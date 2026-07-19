defmodule ActualisWeb.KernelControllerTest do
  use ActualisWeb.ConnCase, async: false

  alias ActualisManufacturing.TestFixture

  test "identity is required", %{conn: conn} do
    conn = post(conn, "/api/v1/capabilities/manufacturing.move_pallet", %{})
    assert json_response(conn, 401)["error"]["code"] == "missing_or_invalid_identity"
  end

  test "HTTP boundary executes and replays", %{conn: conn} do
    fixture = TestFixture.create()
    body = TestFixture.command(fixture) |> Map.drop(["principal_id", "device_id", "capability"])

    first =
      conn
      |> authenticate(fixture)
      |> post("/api/v1/capabilities/manufacturing.move_pallet", body)

    assert %{"ok" => true, "replayed" => false, "evidence_id" => evidence} =
             json_response(first, 200)

    second =
      build_conn()
      |> authenticate(fixture)
      |> post("/api/v1/capabilities/manufacturing.move_pallet", body)

    assert %{"ok" => true, "replayed" => true, "evidence_id" => ^evidence} =
             json_response(second, 200)
  end

  test "OpenAPI endpoint describes the boundary", %{conn: conn} do
    spec = conn |> get("/api/openapi.json") |> json_response(200)
    assert spec["openapi"] == "3.1.0"
    assert Map.has_key?(spec["paths"], "/api/v1/capabilities/manufacturing.move_pallet")
  end

  defp authenticate(conn, fixture) do
    conn
    |> put_req_header("x-actualis-principal-id", fixture.operator.id)
    |> put_req_header("x-actualis-device-id", fixture.device.id)
  end
end
