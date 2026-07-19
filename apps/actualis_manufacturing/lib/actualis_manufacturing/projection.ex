defmodule ActualisManufacturing.Projection do
  @moduledoc "Manufacturing-owned purpose-scoped snapshots and ordered catch-up."

  import Ecto.Query

  alias Actualis.Authority
  alias Actualis.Repo
  alias ActualisManufacturing.{Location, Pallet}
  alias ActualisManufacturing.Projection.Delta

  def snapshot(identity, site_id, purpose, view) when view in ["operator", "supervisor"] do
    with {:ok, decision} <- authorize(identity, site_id, purpose, view) do
      result =
        Repo.transaction(fn -> snapshot_transaction(site_id, view, decision) end,
          isolation: :repeatable_read
        )

      case result do
        {:ok, snapshot} -> {:ok, Map.put(snapshot, "authorization", decision)}
        {:error, _reason} -> {:error, error("projection_failed", "Projection failed")}
      end
    end
  end

  def deltas(identity, site_id, purpose, view, after_cursor)
      when view in ["operator", "supervisor"] do
    with {:ok, decision} <- authorize(identity, site_id, purpose, view) do
      now = DateTime.utc_now()

      rows =
        from(delta in Delta,
          where:
            delta.projection == ^view and delta.scope_id == ^site_id and
              delta.cursor > ^after_cursor and delta.expires_at > ^now and
              is_nil(delta.revoked_at),
          order_by: [asc: delta.cursor],
          limit: 500,
          select: %{cursor: delta.cursor, payload: delta.payload}
        )
        |> Repo.all()
        |> Enum.map(fn row ->
          %{
            "cursor" => row.cursor,
            "payload" => Map.take(row.payload, decision["permitted_fields"])
          }
        end)

      cursor = if rows == [], do: after_cursor, else: rows |> List.last() |> Map.fetch!("cursor")

      {:ok,
       %{"projection" => view, "deltas" => rows, "cursor" => cursor, "authorization" => decision}}
    end
  end

  def append_deltas!(command, pallet, event, context) do
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
        "evidence_id" => context.evidence_id
      })

    expires_at = DateTime.add(context.occurred_at, 8, :hour)

    Enum.each([{"operator", common}, {"supervisor", supervisor}], fn {projection, payload} ->
      Repo.insert!(%Delta{
        event_id: event.id,
        projection: projection,
        scope_id: command.authorization_scope_id,
        payload: payload,
        expires_at: expires_at
      })
    end)
  end

  defp authorize(identity, site_id, purpose, view) do
    decision =
      Authority.evaluate(%{
        principal_id: identity.principal_id,
        device_id: identity.device_id,
        purpose: purpose,
        capability: "manufacturing.view_#{view}",
        authorization_scope_id: site_id,
        scope: %{"site_id" => site_id}
      })

    if Authority.allowed?(decision),
      do: {:ok, decision},
      else: {:error, error("authorization_denied", "Projection access is denied", decision)}
  end

  defp snapshot_transaction(site_id, view, decision) do
    rows =
      from(pallet in Pallet,
        join: location in Location,
        on: location.id == pallet.current_location_id,
        where: pallet.site_id == ^site_id,
        order_by: [asc: pallet.label],
        select: %{
          "pallet_id" => pallet.id,
          "label" => pallet.label,
          "material_code" => pallet.material_code,
          "quality_status" => pallet.quality_status,
          "location_id" => location.id,
          "location_code" => location.code,
          "version" => pallet.version,
          "updated_at" => pallet.updated_at
        }
      )
      |> Repo.all()
      |> Enum.map(&Map.take(&1, decision["permitted_fields"]))

    cursor =
      Repo.one(
        from delta in Delta,
          where: delta.projection == ^view and delta.scope_id == ^site_id,
          select: max(delta.cursor)
      ) || 0

    %{"projection" => view, "snapshot" => rows, "cursor" => cursor}
  end

  defp error(code, message, details \\ %{}) do
    %{"code" => code, "message" => message, "details" => details}
  end
end
