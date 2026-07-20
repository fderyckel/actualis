defmodule ActualisManufacturing.Phase0FixtureTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../../..", __DIR__)
  @dataset_path Path.join(
                  @repo_root,
                  "evals/phase0/fixtures/manufacturing-synthetic.v0.1.json"
                )
  @workload_path Path.join(@repo_root, "evals/phase0/workload-envelope.v0.1.json")
  @evidence_register_path Path.join(
                            @repo_root,
                            "architecture/phase-0/evidence-register.v0.1.json"
                          )
  @narrative_register_path Path.join(
                             @repo_root,
                             "architecture/phase-0/manufacturing-narrative-validation.v0.1.json"
                           )
  @reality_contract_path Path.join(
                           @repo_root,
                           "architecture/reality-contracts/manufacturing-exception-replan-v0.1.md"
                         )

  test "Phase 0 manufacturing fixture is deterministic and contains synthetic data only" do
    dataset = @dataset_path |> File.read!() |> Jason.decode!()

    assert dataset["metadata"]["classification"] == "synthetic_non_personal"
    refute dataset["metadata"]["contains_real_personal_data"]
    refute dataset["metadata"]["contains_secrets"]
    assert is_integer(dataset["metadata"]["deterministic_seed"])

    ids =
      ~w(sites locations principals pallets)
      |> Enum.flat_map(fn collection -> Enum.map(dataset[collection], & &1["id"]) end)

    assert length(ids) == MapSet.size(MapSet.new(ids))
    assert Enum.all?(ids, &match?({:ok, _}, Ecto.UUID.cast(&1)))
    assert Enum.all?(dataset["principals"], &String.starts_with?(&1["display_name"], "Synthetic"))

    deliveries = Enum.map(dataset["observation_trace"], & &1["delivery"])
    assert "duplicate_after_reconnect" in deliveries
    assert "out_of_order_first" in deliveries
    assert "out_of_order_late" in deliveries
  end

  test "Phase 0 workload envelope keeps targets and unimplemented adapters explicit" do
    envelope = @workload_path |> File.read!() |> Jason.decode!()

    assert envelope["status"] == "engineering_hypothesis_unvalidated"
    assert envelope["targets"]["duplicate_authoritative_effects"] == 0
    assert envelope["phase_0_probe_limits"]["phoenix_connections"] == 10_000

    statuses = envelope["profiles"] |> Enum.map(& &1["status"]) |> MapSet.new()
    assert "needs_site_measurement" in statuses
    assert "adapter_not_implemented" in statuses
    assert "worker_not_implemented" in statuses
  end

  test "Phase 0 registers cover the canonical narratives and point to existing evidence" do
    narrative_register = @narrative_register_path |> File.read!() |> Jason.decode!()
    registered_ids = Enum.map(narrative_register["narratives"], & &1["id"])

    canonical_ids =
      ~r/^\| (M-\d{2}) \|/m
      |> Regex.scan(File.read!(@reality_contract_path), capture: :all_but_first)
      |> List.flatten()

    assert length(registered_ids) == 24
    assert MapSet.new(registered_ids) == MapSet.new(canonical_ids)
    assert Enum.all?(narrative_register["narratives"], &is_nil(&1["decision"]))

    evidence_register = @evidence_register_path |> File.read!() |> Jason.decode!()
    refute evidence_register["status"] == "complete"

    for requirement <- evidence_register["requirements"], evidence_path <- requirement["evidence"] do
      assert File.exists?(Path.join(@repo_root, evidence_path)),
             "missing Phase 0 evidence: #{evidence_path}"
    end
  end
end
