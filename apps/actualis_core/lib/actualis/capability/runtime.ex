defmodule Actualis.CapabilityRuntime do
  @moduledoc "Transactional constitutional boundary for governed commands."

  import Ecto.Query

  alias Actualis.Authority
  alias Actualis.Capability.{Command, Registry}
  alias Actualis.Evidence.Record
  alias Actualis.Execution.Receipt
  alias Actualis.Repo

  @spec execute(map()) :: {:ok, map()} | {:error, map()}
  def execute(attrs) do
    with {:ok, handler} <- Registry.fetch(Map.get(attrs, "capability")),
         {:ok, command} <- Command.new(attrs, handler) do
      request_hash = hash(command)

      case Repo.transaction(fn -> execute_transaction(handler, command, request_hash) end) do
        {:ok, response} -> {:ok, response}
        {:error, _reason} -> {:error, execution_failed()}
      end
    end
  end

  defp execute_transaction(handler, command, request_hash) do
    occurred_at = DateTime.utc_now()

    case claim_receipt(command, request_hash, occurred_at) do
      {:cached, response} -> Map.put(response, "replayed", true)
      {:error, reason} -> response(nil, reason, nil)
      {:fresh, receipt} -> execute_fresh(handler, command, receipt, occurred_at)
    end
  end

  defp claim_receipt(command, request_hash, occurred_at) do
    receipt_id = Ecto.UUID.generate()

    row = %{
      id: receipt_id,
      principal_id: command.principal_id,
      idempotency_key: command.idempotency_key,
      capability: command.capability,
      request_hash: request_hash,
      status: "processing",
      inserted_at: occurred_at,
      updated_at: occurred_at
    }

    case Repo.insert_all(Receipt, [row],
           on_conflict: :nothing,
           conflict_target: [:principal_id, :idempotency_key]
         ) do
      {1, _} -> {:fresh, Repo.get!(Receipt, receipt_id)}
      {0, _} -> existing_receipt(command, request_hash)
    end
  end

  defp existing_receipt(command, request_hash) do
    receipt =
      Repo.one!(
        from receipt in Receipt,
          where:
            receipt.principal_id == ^command.principal_id and
              receipt.idempotency_key == ^command.idempotency_key,
          lock: "FOR UPDATE"
      )

    cond do
      receipt.request_hash != request_hash ->
        {:error, error("idempotency_key_reused", "Key is bound to a different request")}

      receipt.status == "completed" ->
        {:cached, receipt.response}

      true ->
        {:error, error("command_in_progress", "The command is still processing")}
    end
  end

  defp execute_fresh(handler, command, receipt, occurred_at) do
    decision = Authority.evaluate(command, occurred_at)
    evidence_id = Ecto.UUID.generate()

    if Authority.allowed?(decision) do
      context = %{
        receipt_id: receipt.id,
        evidence_id: evidence_id,
        occurred_at: occurred_at
      }

      case handler.execute(command, context) do
        {:ok, %{domain_versions: domain_versions, effects: effects}} ->
          persist_success(
            command,
            receipt,
            decision,
            evidence_id,
            domain_versions,
            effects,
            occurred_at
          )

        {:error, %{error: domain_error, domain_versions: domain_versions}} ->
          persist_rejection(
            command,
            receipt,
            decision,
            evidence_id,
            domain_error,
            domain_versions,
            occurred_at
          )

        _invalid_result ->
          Repo.rollback(:invalid_capability_handler_result)
      end
    else
      denied = error("authorization_denied", "The request is not authorized")

      persist_rejection(
        command,
        receipt,
        decision,
        evidence_id,
        denied,
        %{},
        occurred_at
      )
    end
  end

  defp persist_success(
         command,
         receipt,
         decision,
         evidence_id,
         domain_versions,
         effects,
         occurred_at
       ) do
    insert_evidence(
      evidence_id,
      command,
      receipt,
      decision,
      decision["explanation_code"],
      domain_versions,
      effects,
      occurred_at
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

  defp persist_rejection(
         command,
         receipt,
         decision,
         evidence_id,
         domain_error,
         domain_versions,
         occurred_at
       ) do
    result = response(receipt.id, domain_error, decision)

    insert_evidence(
      evidence_id,
      command,
      receipt,
      decision,
      domain_error["code"],
      domain_versions,
      %{},
      occurred_at
    )

    outcome = if decision["decision"] == "deny", do: "denied", else: "rejected"
    complete(receipt, outcome, result)
    result
  end

  defp insert_evidence(
         evidence_id,
         command,
         receipt,
         decision,
         explanation_code,
         domain_versions,
         effects,
         occurred_at
       ) do
    Repo.insert!(%Record{
      id: evidence_id,
      receipt_id: receipt.id,
      principal_id: command.principal_id,
      device_id: command.device_id,
      purpose: command.purpose,
      capability: command.capability,
      authorization_scope_id: command.authorization_scope_id,
      scope: command.scope,
      input: command.input,
      decision: decision["decision"],
      explanation_code: explanation_code,
      policy_version: decision["policy_version"],
      domain_versions: domain_versions,
      effects: effects,
      occurred_at: occurred_at
    })
  end

  defp complete(receipt, outcome, result) do
    receipt
    |> Ecto.Changeset.change(status: "completed", outcome: outcome, response: result)
    |> Repo.update!()
  end

  defp response(receipt_id, error, nil) do
    %{"ok" => false, "command_id" => receipt_id, "replayed" => false, "error" => error}
  end

  defp response(receipt_id, error, decision) do
    Map.put(response(receipt_id, error, nil), "authorization", decision)
  end

  defp error(code, message, details \\ %{}) do
    %{"code" => code, "message" => message, "details" => details}
  end

  defp execution_failed do
    error("execution_failed", "The capability execution failed")
  end

  defp hash(command) do
    command
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
