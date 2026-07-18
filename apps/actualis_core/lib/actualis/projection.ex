defmodule Actualis.Projection do
  @moduledoc "Purpose-scoped snapshots and ordered, reauthorised catch-up."
  import Ecto.Query
  alias Actualis.Authority
  alias Actualis.Manufacturing.{Location, Pallet}
  alias Actualis.Projection.Delta
  alias Actualis.Repo

  def snapshot(identity, site_id, purpose, view) when view in ["operator", "supervisor"] do
    with {:ok, decision} <- authorize(identity, site_id, purpose, view) do
      result =
        Repo.transaction(fn -> snapshot_tx(site_id, view, decision) end,
          isolation: :repeatable_read
        )

      case result do
        {:ok, snapshot} -> {:ok, Map.put(snapshot, "authorization", decision)}
        {:error, reason} -> {:error, error("projection_failed", inspect(reason))}
      end
    end
  end

  def deltas(identity, site_id, purpose, view, after_cursor)
      when view in ["operator", "supervisor"] do
    with {:ok, decision} <- authorize(identity, site_id, purpose, view) do
      now = DateTime.utc_now()

      rows =
        from(d in Delta,
          where:
            d.projection == ^view and d.scope_id == ^site_id and d.cursor > ^after_cursor and
              d.expires_at > ^now and is_nil(d.revoked_at),
          order_by: [asc: d.cursor],
          limit: 500,
          select: %{cursor: d.cursor, payload: d.payload}
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

  defp authorize(identity, site_id, purpose, view) do
    decision =
      Authority.evaluate(%{
        principal_id: identity.principal_id,
        device_id: identity.device_id,
        purpose: purpose,
        capability: "manufacturing.view_#{view}",
        scope: %{"site_id" => site_id}
      })

    if Authority.allowed?(decision),
      do: {:ok, decision},
      else: {:error, error("authorization_denied", "Projection access is denied", decision)}
  end

  defp snapshot_tx(site_id, view, decision) do
    rows =
      from(p in Pallet,
        join: l in Location,
        on: l.id == p.current_location_id,
        where: p.site_id == ^site_id,
        order_by: [asc: p.label],
        select: %{
          "pallet_id" => p.id,
          "label" => p.label,
          "material_code" => p.material_code,
          "quality_status" => p.quality_status,
          "location_id" => l.id,
          "location_code" => l.code,
          "version" => p.version,
          "updated_at" => p.updated_at
        }
      )
      |> Repo.all()
      |> Enum.map(&Map.take(&1, decision["permitted_fields"]))

    cursor =
      Repo.one(
        from d in Delta,
          where: d.projection == ^view and d.scope_id == ^site_id,
          select: max(d.cursor)
      ) || 0

    %{"projection" => view, "snapshot" => rows, "cursor" => cursor}
  end

  defp error(code, message, details \\ %{}),
    do: %{"code" => code, "message" => message, "details" => details}
end
