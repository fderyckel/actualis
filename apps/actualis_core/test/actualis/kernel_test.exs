defmodule Actualis.KernelTest do
  use Actualis.DataCase, async: false
  alias Actualis.{CapabilityRuntime, Evidence, KernelFixture, Projection, Repo}
  alias Actualis.Evidence.Record
  alias Actualis.Execution.{Event, Receipt}
  alias Actualis.Manufacturing.{Movement, Pallet}
  alias Actualis.Projection.Delta

  test "atomic happy path" do
    f = KernelFixture.create()
    assert {:ok, %{"ok" => true} = result} = CapabilityRuntime.execute(KernelFixture.command(f))
    assert result["authorization"]["policy_version"] == f.policy.version
    assert Repo.get!(Pallet, f.pallet.id).version == 2
    assert Repo.aggregate(Movement, :count) == 1
    assert Repo.aggregate(Record, :count) == 1
    assert Repo.aggregate(Event, :count) == 1
    assert Repo.aggregate(Delta, :count) == 2
  end

  test "same request replays without duplicate effect" do
    f = KernelFixture.create()
    command = KernelFixture.command(f)
    assert {:ok, %{"replayed" => false} = first} = CapabilityRuntime.execute(command)
    assert {:ok, %{"replayed" => true} = second} = CapabilityRuntime.execute(command)
    assert first["command_id"] == second["command_id"]
    assert Repo.aggregate(Movement, :count) == 1
  end

  test "changed request cannot reuse idempotency key" do
    f = KernelFixture.create()
    command = KernelFixture.command(f)
    assert {:ok, %{"ok" => true}} = CapabilityRuntime.execute(command)
    changed = put_in(command, ["input", "reason"], "Different reason")

    assert {:ok, %{"error" => %{"code" => "idempotency_key_reused"}}} =
             CapabilityRuntime.execute(changed)
  end

  test "stale version records evidence but no effect" do
    f = KernelFixture.create()

    assert {:ok, %{"error" => %{"code" => "version_conflict"}, "command_id" => id}} =
             CapabilityRuntime.execute(KernelFixture.command(f, %{"expected_version" => 2}))

    assert Repo.get!(Pallet, f.pallet.id).version == 1
    assert Repo.aggregate(Movement, :count) == 0
    assert Repo.get_by!(Record, receipt_id: id).explanation_code == "version_conflict"
  end

  test "ungranted purpose is denied and retained" do
    f = KernelFixture.create()

    assert {:ok, %{"error" => %{"code" => "authorization_denied"}, "authorization" => auth}} =
             CapabilityRuntime.execute(KernelFixture.command(f, %{"purpose" => "not_granted"}))

    assert auth["explanation_code"] == "no_active_capability_grant"
    assert Repo.aggregate(Movement, :count) == 0
    assert Repo.aggregate(Record, :count) == 1
  end

  test "quality hold blocks movement" do
    f = KernelFixture.create(%{quality_status: "hold"})

    assert {:ok, %{"error" => %{"code" => "quality_status_blocks_move"}}} =
             CapabilityRuntime.execute(KernelFixture.command(f))

    assert Repo.aggregate(Movement, :count) == 0
  end

  test "operator projection filters and catches up" do
    f = KernelFixture.create()

    assert {:ok, before} =
             Projection.snapshot(f.identity, f.site.id, "fulfil_material_movement", "operator")

    [row] = before["snapshot"]
    refute Map.has_key?(row, "material_code")
    assert {:ok, %{"ok" => true}} = CapabilityRuntime.execute(KernelFixture.command(f))

    assert {:ok, %{"deltas" => [%{"payload" => payload}]}} =
             Projection.deltas(
               f.identity,
               f.site.id,
               "fulfil_material_movement",
               "operator",
               before["cursor"]
             )

    assert payload["status"] == "moved"
    refute Map.has_key?(payload, "reason")
  end

  test "evidence reconstructs versions and outcome under separate grant" do
    f = KernelFixture.create()
    assert {:ok, %{"evidence_id" => id}} = CapabilityRuntime.execute(KernelFixture.command(f))

    assert {:ok, %{"evidence" => evidence}} =
             Evidence.fetch(f.identity, id, f.site.id, "supervise_material_flow")

    assert evidence["outcome"] == "committed"
    assert evidence["domain_versions"]["manufacturing_pallet"] == %{"read" => 1, "committed" => 2}
  end

  test "receipt is completed on every governed outcome" do
    f = KernelFixture.create()
    assert {:ok, %{"command_id" => id}} = CapabilityRuntime.execute(KernelFixture.command(f))
    assert Repo.get!(Receipt, id).status == "completed"
  end
end
