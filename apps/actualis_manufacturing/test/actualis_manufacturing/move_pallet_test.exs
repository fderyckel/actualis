defmodule ActualisManufacturing.MovePalletTest do
  use ActualisManufacturing.DataCase, async: false

  alias Actualis.{Evidence, Repo}
  alias Actualis.Evidence.Record
  alias Actualis.Execution.{Event, Receipt}
  alias ActualisManufacturing.{Movement, Pallet, Projection, TestFixture}
  alias ActualisManufacturing.Projection.Delta

  test "commits the domain effect and Core records atomically" do
    fixture = TestFixture.create()

    assert {:ok, %{"ok" => true} = result} =
             ActualisManufacturing.execute(TestFixture.command(fixture))

    assert result["authorization"]["policy_version"] == fixture.policy.version
    assert Repo.get!(Pallet, fixture.pallet.id).version == 2
    assert Repo.aggregate(Movement, :count) == 1
    assert Repo.aggregate(Record, :count) == 1
    assert Repo.aggregate(Event, :count) == 1
    assert Repo.aggregate(Delta, :count) == 2
  end

  test "replays the same request without a duplicate movement" do
    fixture = TestFixture.create()
    command = TestFixture.command(fixture)

    assert {:ok, %{"replayed" => false} = first} = ActualisManufacturing.execute(command)
    assert {:ok, %{"replayed" => true} = second} = ActualisManufacturing.execute(command)
    assert first["command_id"] == second["command_id"]
    assert Repo.aggregate(Movement, :count) == 1
  end

  test "rejects changed content under an existing idempotency key" do
    fixture = TestFixture.create()
    command = TestFixture.command(fixture)

    assert {:ok, %{"ok" => true}} = ActualisManufacturing.execute(command)
    changed = put_in(command, ["input", "reason"], "Different reason")

    assert {:ok, %{"error" => %{"code" => "idempotency_key_reused"}}} =
             ActualisManufacturing.execute(changed)
  end

  test "records a stale-version rejection without a domain effect" do
    fixture = TestFixture.create()

    assert {:ok, %{"error" => %{"code" => "version_conflict"}, "command_id" => receipt_id}} =
             ActualisManufacturing.execute(
               TestFixture.command(fixture, %{"expected_version" => 2})
             )

    assert Repo.get!(Pallet, fixture.pallet.id).version == 1
    assert Repo.aggregate(Movement, :count) == 0
    assert Repo.get_by!(Record, receipt_id: receipt_id).explanation_code == "version_conflict"
  end

  test "denies an ungranted purpose and retains evidence" do
    fixture = TestFixture.create()

    assert {:ok, %{"error" => %{"code" => "authorization_denied"}, "authorization" => auth}} =
             ActualisManufacturing.execute(
               TestFixture.command(fixture, %{"purpose" => "not_granted"})
             )

    assert auth["explanation_code"] == "no_active_capability_grant"
    assert Repo.aggregate(Movement, :count) == 0
    assert Repo.aggregate(Record, :count) == 1
  end

  test "blocks movement while the pallet is on quality hold" do
    fixture = TestFixture.create(%{quality_status: "hold"})

    assert {:ok, %{"error" => %{"code" => "quality_status_blocks_move"}}} =
             ActualisManufacturing.execute(TestFixture.command(fixture))

    assert Repo.aggregate(Movement, :count) == 0
  end

  test "filters operator projections and catches up from the durable cursor" do
    fixture = TestFixture.create()

    assert {:ok, before} =
             Projection.snapshot(
               fixture.identity,
               fixture.site.id,
               "fulfil_material_movement",
               "operator"
             )

    [row] = before["snapshot"]
    refute Map.has_key?(row, "material_code")
    assert {:ok, %{"ok" => true}} = ActualisManufacturing.execute(TestFixture.command(fixture))

    assert {:ok, %{"deltas" => [%{"payload" => payload}]}} =
             Projection.deltas(
               fixture.identity,
               fixture.site.id,
               "fulfil_material_movement",
               "operator",
               before["cursor"]
             )

    assert payload["status"] == "moved"
    refute Map.has_key?(payload, "reason")
  end

  test "reconstructs evidence under a separate current grant" do
    fixture = TestFixture.create()

    assert {:ok, %{"evidence_id" => evidence_id}} =
             ActualisManufacturing.execute(TestFixture.command(fixture))

    assert {:ok, %{"evidence" => evidence}} =
             Evidence.fetch(
               fixture.identity,
               evidence_id,
               fixture.site.id,
               "supervise_material_flow"
             )

    assert evidence["outcome"] == "committed"

    assert evidence["domain_versions"]["manufacturing_pallet"] == %{
             "read" => 1,
             "committed" => 2
           }
  end

  test "completes the Core receipt for every governed outcome" do
    fixture = TestFixture.create()

    assert {:ok, %{"command_id" => receipt_id}} =
             ActualisManufacturing.execute(TestFixture.command(fixture))

    assert Repo.get!(Receipt, receipt_id).status == "completed"
  end
end
