defmodule ActualisWeb.ActualisController do
  use ActualisWeb, :controller

  alias Actualis.{Evidence, Repo}
  alias ActualisManufacturing

  def health(conn, _), do: health_response(conn, Ecto.Adapters.SQL.query(Repo, "SELECT 1", []))
  def openapi(conn, _), do: json(conn, ActualisWeb.OpenAPI.spec())

  def move(conn, params) do
    identity = conn.assigns.identity

    attrs =
      params
      |> Map.put("principal_id", identity.principal_id)
      |> Map.put("device_id", identity.device_id)
      |> Map.put("capability", "manufacturing.move_pallet")
      |> Map.put_new("client_context", %{
        "remote_ip" => conn.remote_ip |> :inet.ntoa() |> to_string()
      })

    case ActualisManufacturing.execute(attrs) do
      {:ok, %{"ok" => true} = result} ->
        json(conn, result)

      {:ok, %{"error" => error} = result} ->
        conn |> put_status(status(error["code"])) |> json(result)

      {:error, error} ->
        conn |> put_status(:unprocessable_entity) |> json(%{"ok" => false, "error" => error})
    end
  end

  def snapshot(conn, %{"view" => view, "site_id" => site, "purpose" => purpose}) do
    render_result(
      conn,
      ActualisManufacturing.snapshot(conn.assigns.identity, site, purpose, view)
    )
  end

  def snapshot(conn, _), do: invalid(conn)

  def deltas(conn, %{
        "view" => view,
        "site_id" => site,
        "purpose" => purpose,
        "after" => after_value
      }) do
    case Integer.parse(after_value) do
      {cursor, ""} when cursor >= 0 ->
        render_result(
          conn,
          ActualisManufacturing.deltas(conn.assigns.identity, site, purpose, view, cursor)
        )

      _ ->
        invalid(conn)
    end
  end

  def deltas(conn, _), do: invalid(conn)

  def evidence(conn, %{"id" => id, "site_id" => site, "purpose" => purpose}) do
    render_result(conn, Evidence.fetch(conn.assigns.identity, id, site, purpose))
  end

  def evidence(conn, _), do: invalid(conn)

  defp render_result(conn, {:ok, result}), do: json(conn, result)

  defp render_result(conn, {:error, %{"code" => "authorization_denied"} = error}),
    do: conn |> put_status(:forbidden) |> json(%{"error" => error})

  defp render_result(conn, {:error, %{"code" => "evidence_not_found"} = error}),
    do: conn |> put_status(:not_found) |> json(%{"error" => error})

  defp render_result(conn, {:error, error}),
    do: conn |> put_status(:unprocessable_entity) |> json(%{"error" => error})

  defp invalid(conn),
    do:
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{"error" => %{"code" => "invalid_query"}})

  defp health_response(conn, {:ok, _}), do: json(conn, %{"status" => "ok"})

  defp health_response(conn, _),
    do: conn |> put_status(:service_unavailable) |> json(%{"status" => "degraded"})

  defp status(code)
       when code in [
              "version_conflict",
              "source_location_conflict",
              "idempotency_key_reused",
              "command_in_progress"
            ],
       do: :conflict

  defp status("authorization_denied"), do: :forbidden
  defp status(_), do: :unprocessable_entity
end
