defmodule Actualis.CapabilityRuntimeTest do
  use Actualis.DataCase, async: false

  alias Actualis.{CapabilityRuntime, ConformanceFixture, Repo}
  alias Actualis.Evidence.Record
  alias Actualis.Execution.{Event, Receipt}

  test "executes a configured domain handler through Core contracts" do
    fixture = ConformanceFixture.create()

    assert {:ok, %{"ok" => true} = result} =
             CapabilityRuntime.execute(ConformanceFixture.command(fixture))

    assert result["authorization"]["policy_version"] == fixture.policy.version
    assert Repo.aggregate(Record, :count) == 1
    assert Repo.aggregate(Event, :count) == 1
    assert Repo.aggregate(Receipt, :count) == 1
  end

  test "replays an identical request without duplicating the handler effect" do
    fixture = ConformanceFixture.create()
    command = ConformanceFixture.command(fixture)

    assert {:ok, %{"replayed" => false} = first} = CapabilityRuntime.execute(command)
    assert {:ok, %{"replayed" => true} = second} = CapabilityRuntime.execute(command)
    assert first["command_id"] == second["command_id"]
    assert Repo.aggregate(Event, :count) == 1
  end

  test "rejects changed content under an existing idempotency key" do
    fixture = ConformanceFixture.create()
    command = ConformanceFixture.command(fixture)

    assert {:ok, %{"ok" => true}} = CapabilityRuntime.execute(command)
    changed = put_in(command, ["input", "value"], "changed-value")

    assert {:ok, %{"error" => %{"code" => "idempotency_key_reused"}}} =
             CapabilityRuntime.execute(changed)
  end

  test "denies an ungranted purpose and retains Core evidence" do
    fixture = ConformanceFixture.create()
    command = ConformanceFixture.command(fixture, %{"purpose" => "not_granted"})

    assert {:ok, %{"error" => %{"code" => "authorization_denied"}}} =
             CapabilityRuntime.execute(command)

    assert Repo.aggregate(Event, :count) == 0
    assert Repo.aggregate(Record, :count) == 1
  end

  test "rolls back handler events and the Core receipt when the transaction aborts" do
    fixture = ConformanceFixture.create()

    command =
      ConformanceFixture.command(fixture, %{
        "input" => %{"rollback_after_event" => true}
      })

    assert {:error, %{"code" => "execution_failed"}} = CapabilityRuntime.execute(command)
    assert Repo.aggregate(Event, :count) == 0
    assert Repo.aggregate(Record, :count) == 0
    assert Repo.aggregate(Receipt, :count) == 0
  end

  test "Core source does not import manufacturing modules" do
    core_source_root = Path.expand("../../../lib", __DIR__)

    sources =
      core_source_root
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.map_join("\n", &File.read!/1)

    refute sources =~ "ActualisManufacturing"
    refute sources =~ "Actualis.Manufacturing"
  end

  test "Core authority tables have no foreign keys to manufacturing tables" do
    query = """
    SELECT ccu.table_name
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.constraint_schema = tc.constraint_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = current_schema()
      AND tc.table_name IN ('authority_devices', 'authority_assignments')
      AND ccu.table_name LIKE 'manufacturing_%'
    """

    assert %{rows: []} = Ecto.Adapters.SQL.query!(Repo, query)
  end
end
