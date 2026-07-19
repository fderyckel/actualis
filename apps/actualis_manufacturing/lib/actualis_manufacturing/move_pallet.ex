defmodule ActualisManufacturing.MovePallet do
  @moduledoc "Governed manufacturing handler for the pallet movement application capability."

  @behaviour Actualis.Capability.Handler

  import Ecto.Query

  alias Actualis.Capability.Command
  alias Actualis.Delivery
  alias Actualis.Repo
  alias ActualisManufacturing.{Location, Movement, Pallet, Projection}

  @capability "manufacturing.move_pallet"

  @impl true
  def capability, do: @capability

  @impl true
  def validate(scope, input) do
    with {:ok, site_id} <- Ecto.UUID.cast(scope["site_id"]),
         {:ok, pallet_id} <- Ecto.UUID.cast(input["pallet_id"]),
         {:ok, source_id} <- Ecto.UUID.cast(input["source_location_id"]),
         {:ok, destination_id} <- Ecto.UUID.cast(input["destination_location_id"]),
         reason when is_binary(reason) and byte_size(reason) >= 3 <- input["reason"] do
      {:ok,
       %{
         authorization_scope_id: site_id,
         scope: %{"site_id" => site_id},
         input: %{
           "pallet_id" => pallet_id,
           "source_location_id" => source_id,
           "destination_location_id" => destination_id,
           "reason" => reason
         }
       }}
    else
      _ -> {:error, invalid_command()}
    end
  end

  @impl true
  def execute(%Command{} = command, context) do
    pallet =
      Repo.one(
        from pallet in Pallet,
          where:
            pallet.id == ^command.input["pallet_id"] and
              pallet.site_id == ^command.scope["site_id"],
          lock: "FOR UPDATE"
      )

    case invariant_error(pallet, command) do
      nil -> {:ok, commit_move(pallet, command, context)}
      domain_error -> {:error, %{error: domain_error, domain_versions: versions(pallet)}}
    end
  end

  defp invariant_error(nil, _command), do: error("pallet_not_found", "Pallet was not found")

  defp invariant_error(%Pallet{version: actual}, %Command{expected_version: expected})
       when actual != expected do
    error("version_conflict", "Pallet version is stale", %{
      "actual_version" => actual,
      "expected_version" => expected
    })
  end

  defp invariant_error(%Pallet{current_location_id: actual}, %Command{
         input: %{"source_location_id" => source}
       })
       when actual != source do
    error("source_location_conflict", "Pallet is no longer at the claimed source", %{
      "actual_source_location_id" => actual
    })
  end

  defp invariant_error(%Pallet{quality_status: status}, _command) when status != "released" do
    error("quality_status_blocks_move", "Pallet quality status blocks movement", %{
      "quality_status" => status
    })
  end

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

  defp commit_move(pallet, command, context) do
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
        receipt_id: context.receipt_id,
        performed_by_id: command.principal_id,
        reason: command.input["reason"],
        pallet_version: moved.version,
        occurred_at: context.occurred_at
      })

    event =
      Delivery.append_event!(%{
        event_type: "manufacturing.pallet_moved.v1",
        aggregate_id: moved.id,
        aggregate_version: moved.version,
        payload: %{
          "schema_version" => "1.0",
          "command_id" => context.receipt_id,
          "evidence_id" => context.evidence_id,
          "pallet_id" => moved.id,
          "site_id" => command.scope["site_id"],
          "source_location_id" => command.input["source_location_id"],
          "destination_location_id" => moved.current_location_id,
          "pallet_version" => moved.version
        },
        occurred_at: context.occurred_at
      })

    Projection.append_deltas!(command, moved, event, context)

    %{
      domain_versions: %{
        "manufacturing_pallet" => %{"read" => pallet.version, "committed" => moved.version}
      },
      effects: %{
        "movement_id" => movement.id,
        "pallet_id" => moved.id,
        "destination_location_id" => moved.current_location_id,
        "pallet_version" => moved.version,
        "outbox_event_id" => event.id
      }
    }
  end

  defp versions(nil), do: %{}

  defp versions(pallet) do
    %{"manufacturing_pallet" => %{"read" => pallet.version, "committed" => nil}}
  end

  defp invalid_command do
    error("invalid_command", "The capability request is invalid")
  end

  defp error(code, message, details \\ %{}) do
    %{"code" => code, "message" => message, "details" => details}
  end
end
