defmodule ActualisWeb.IdentityPlug do
  @moduledoc "Local-only adapter; production must replace headers with verified OIDC and device proof."
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    with [principal] <- get_req_header(conn, "x-actualis-principal-id"),
         {:ok, principal} <- Ecto.UUID.cast(principal),
         [device] <- get_req_header(conn, "x-actualis-device-id"),
         {:ok, device} <- Ecto.UUID.cast(device) do
      assign(conn, :identity, %{principal_id: principal, device_id: device})
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{"error" => %{"code" => "missing_or_invalid_identity"}})
        |> halt()
    end
  end
end
