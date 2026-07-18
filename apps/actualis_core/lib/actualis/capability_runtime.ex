defmodule Actualis.CapabilityRuntime do
  @moduledoc "Transactional constitutional boundary for governed commands."
  import Ecto.Query

  alias Actualis.Authority
  alias Actualis.Evidence.Record
  alias Actualis.Execution.{Event, Receipt}
  alias Actualis.Manufacturing.{Location, Movement, Pallet}
  alias Actualis.Projection.Delta
  alias Actualis.Repo

  @capability "manufacturing.move_pallet"

  def execute(attrs) do
    with {:ok, command} <- validate(attrs) do
      hash = hash(command)

      case Repo.transaction(fn -> execute_tx(command, hash) end) do
        {:ok, response} -> {:ok, response}
        {:error, reason} -> {:error, error("execution_failed", inspect(reason))}
      end
    end
  end

  defp validate(attrs) do
    required =
      ~w(principal_id device_id purpose capability scope input expected_version idempotency_key)

    with true <- Enum.all?(required, &Map.has_key?(attrs, &1)),
         @capability <- attrs["capability"],
         {:ok, principal_id} <- uuid(attrs["principal_id"]),
         {:ok, device_id} <- uuid(attrs["device_id"]),
         {:ok, site_id} <- uuid(get_in(attrs, ["scope", "site_id"])),
         {:ok, pallet_id} <- uuid(get_in(attrs, ["input", "pallet_id"])),
         {:ok, source_id} <- uuid(get_in(attrs, ["input", "source_location_id"])),
         {:ok, destination_id} <- uuid(get_in(attrs, ["input", "destination_location_id"])),
         version when is_integer(version) and version > 0 <- attrs["expected_version"],
         key when is_binary(key) and byte_size(key) >= 8 <- attrs["idempotency_key"],
         purpose when is_binary(purpose) and byte_size(purpose) >= 3 <- attrs["purpose"],
         reason when is_binary(reason) and byte_size(reason) >= 3 <-
           get_in(attrs, ["input", "reason"]) do
      {:ok,
       %{
         principal_id: principal_id,
         device_id: device_id,
         purpose: purpose,
         capability: @capability,
         scope: %{"site_id" => site_id},
         input: %{
           "pallet_id" => pallet_id,
           "source_location_id" => source_id,
           "destination_location_id" => destination_id,
           "reason" => reason
         },
         expected_version: version,
         idempotency_key: key,
         evidence_references: Map.get(attrs, "evidence_references", []),
         client_context: Map.get(attrs, "client_context", %{})
       }}
    else
      _ -> {:error, error("invalid_command", "The capability request is invalid")}
    end
  end

  defp execute_tx(command, hash) do
    now = DateTime.utc_now()

    case receipt(command, hash, now) do
      {:cached, response} -> Map.put(response, "replayed", true)
      {:error, reason} -> response(nil, reason, nil)
      {:fresh, receipt} -> execute_fresh(command, receipt, now)
    end
  end

  defp receipt(command, hash, now) do
    id = Ecto.UUID.generate()

    row = %{
      id: id,
      principal_id: command.principal_id,
      idempotency_key: command.idempotency_key,
      capability: command.capability,
      request_hash: hash,
      status: "processing",
      inserted_at: now,
      updated_at: now
    }

    case Repo.insert_all(Receipt, [row],
           on_conflict: :nothing,
           conflict_target: [:principal_id, :idempotency_key]
         ) do
      {1, _} -> {:fresh, Repo.get!(Receipt, id)}
      {0, _} -> existing_receipt(command, hash)
    end
  end

  defp existing_receipt(command, hash) do
    receipt =
      Repo.one!(
        from r in Receipt,
          where:
            r.principal_id == ^command.principal_id and
              r.idempotency_key == ^command.idempotency_key,
          lock: "FOR UPDATE"
      )

    cond do
      receipt.request_hash != hash ->
        {:error, error("idempotency_key_reused", "Key is bound to a different request")}

      receipt.status == "completed" ->
        {:cached, receipt.response}

      true ->
        {:error, error("command_in_progress", "The command is still processing")}
    end
  end

  defp execute_fresh(command, receipt, now) do
    decision = Authority.evaluate(command, now)

    if Authority.allowed?(decision) do
      move(command, receipt, decision, now)
    else
      denied = error("authorization_denied", "The request is not authorized")
      persist_rejection(command, receipt, decision, denied, %{}, now)
    end
  end

  defp move(command, receipt, decision, now) do
    pallet =
      Repo.one(
        from p in Pallet,
          where: p.id == ^command.input["pallet_id"] and p.site_id == ^command.scope["site_id"],
          lock: "FOR UPDATE"
      )

    case invariant_error(pallet, command) do
      nil ->
        commit_move(pallet, command, receipt, decision, now)

      domain_error ->
        persist_rejection(command, receipt, decision, domain_error, versions(pallet), now)
    end
  end

  defp invariant_error(nil, _command), do: error("pallet_not_found", "Pallet was not found")

  defp invariant_error(%Pallet{version: actual}, %{expected_version: expected})
       when actual != expected,
       do:
         error("version_conflict", "Pallet version is stale", %{
           "actual_version" => actual,
           "expected_version" => expected
         })

  defp invariant_error(%Pallet{current_location_id: actual}, %{
         input: %{"source_location_id" => source}
       })
       when actual != source,
       do:
         error("source_location_conflict", "Pallet is no longer at the claimed source", %{
           "actual_source_location_id" => actual
         })

  defp invariant_error(%Pallet{quality_status: status}, _command) when status != "released",
    do:
      error("quality_status_blocks_move", "Pallet quality status blocks movement", %{
        "quality_status" => status
      })

  defp invariant_error(pallet, command) do
    destination =
      Repo.get_by(Location,
        id: command.input["destination_location_id"],
        site_id: pallet.site_id,
        active: true
      )

    cond do
      is_nil(destination) ->
        error("invalid_destination", "Destination is not active in the site")

      destination.id == pallet.current_location_id ->
        error("destination_unchanged", "Source and destination must differ")

      true ->
        nil
    end
  end

  defp commit_move(pallet, command, receipt, decision, now) do
    moved =
      pallet
      |> Ecto.Changeset.change(
        current_location_id: command.input["destination_location_id"],
        version: pallet.version + 1
      )
      |> Repo.update!()

    movement =
      Repo.insert!(%Movement{
        pallet_id: pallet.id,
        source_location_id: pallet.current_location_id,
        destination_location_id: moved.current_location_id,
        receipt_id: receipt.id,
        performed_by_id: command.principal_id,
        reason: command.input["reason"],
        pallet_version: moved.version,
        occurred_at: now
      })

    evidence_id = Ecto.UUID.generate()
    event = insert_event(command, receipt, moved, evidence_id, now)
    insert_deltas(command, moved, event, evidence_id, now)

    effects = %{
      "movement_id" => movement.id,
      "pallet_id" => moved.id,
      "destination_location_id" => moved.current_location_id,
      "pallet_version" => moved.version,
      "outbox_event_id" => event.id
    }

    domain_versions = %{
      "manufacturing_pallet" => %{"read" => pallet.version, "committed" => moved.version}
    }

    insert_evidence(
      evidence_id,
      command,
      receipt,
      decision,
      decision["explanation_code"],
      domain_versions,
      effects,
      now
    )

    result = %{
      "ok" => true,
      "command_id" => receipt.id,
      "evidence_id" => evidence_id,
      "replayed" => false,
      "authorization" => decision,
      "result" => effects
    }

    complete(receipt, "committed", result)
    result
  end

  defp persist_rejection(command, receipt, decision, domain_error, domain_versions, now) do
    result = response(receipt.id, domain_error, decision)

    insert_evidence(
      Ecto.UUID.generate(),
      command,
      receipt,
      decision,
      domain_error["code"],
      domain_versions,
      %{},
      now
    )

    complete(receipt, if(decision["decision"] == "deny", do: "denied", else: "rejected"), result)
    result
  end

  defp insert_event(command, receipt, pallet, evidence_id, now) do
    Repo.insert!(%Event{
      event_type: "manufacturing.pallet_moved.v1",
      aggregate_id: pallet.id,
      aggregate_version: pallet.version,
      payload: %{
        "schema_version" => "1.0",
        "command_id" => receipt.id,
        "evidence_id" => evidence_id,
        "pallet_id" => pallet.id,
        "site_id" => command.scope["site_id"],
        "source_location_id" => command.input["source_location_id"],
        "destination_location_id" => pallet.current_location_id,
        "pallet_version" => pallet.version
      },
      occurred_at: now
    })
  end

  defp insert_deltas(command, pallet, event, evidence_id, now) do
    common = %{
      "pallet_id" => pallet.id,
      "label" => pallet.label,
      "destination_location_id" => pallet.current_location_id,
      "version" => pallet.version,
      "status" => "moved"
    }

    supervisor =
      Map.merge(common, %{
        "material_code" => pallet.material_code,
        "source_location_id" => command.input["source_location_id"],
        "reason" => command.input["reason"],
        "performed_by_id" => command.principal_id,
        "evidence_id" => evidence_id
      })

    expiry = DateTime.add(now, 8, :hour)

    Enum.each([{"operator", common}, {"supervisor", supervisor}], fn {projection, payload} ->
      Repo.insert!(%Delta{
        event_id: event.id,
        projection: projection,
        scope_id: command.scope["site_id"],
        payload: payload,
        expires_at: expiry
      })
    end)
  end

  defp insert_evidence(id, command, receipt, decision, code, domain_versions, effects, now) do
    Repo.insert!(%Record{
      id: id,
      receipt_id: receipt.id,
      principal_id: command.principal_id,
      device_id: command.device_id,
      purpose: command.purpose,
      capability: command.capability,
      scope: command.scope,
      input: command.input,
      decision: decision["decision"],
      explanation_code: code,
      policy_version: decision["policy_version"],
      domain_versions: domain_versions,
      effects: effects,
      occurred_at: now
    })
  end

  defp complete(receipt, outcome, result) do
    receipt
    |> Ecto.Changeset.change(status: "completed", outcome: outcome, response: result)
    |> Repo.update!()
  end

  defp versions(nil), do: %{}

  defp versions(pallet),
    do: %{"manufacturing_pallet" => %{"read" => pallet.version, "committed" => nil}}

  defp response(id, error, nil),
    do: %{"ok" => false, "command_id" => id, "replayed" => false, "error" => error}

  defp response(id, error, decision),
    do: Map.put(response(id, error, nil), "authorization", decision)

  defp error(code, message, details \\ %{}),
    do: %{"code" => code, "message" => message, "details" => details}

  defp uuid(value), do: Ecto.UUID.cast(value)

  defp hash(command) do
    command
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
