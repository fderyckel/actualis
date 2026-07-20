defmodule Actualis.Stock.Phase0Test do
  use ExUnit.Case, async: true

  alias Actualis.Capability.Command
  alias Actualis.Stock
  alias Actualis.Stock.{Capabilities, Scope, Telemetry}

  defmodule ValidateOnlyHandler do
    @moduledoc false

    @behaviour Actualis.Capability.Handler

    @impl true
    def capability, do: "stock.manage_items"

    @impl true
    def validate(scope, input) do
      with {:ok, %Scope{} = stock_scope} <- Scope.new(scope),
           example_code when is_binary(example_code) and byte_size(example_code) > 0 <-
             input["example_code"] do
        {:ok,
         %{
           authorization_scope_id: stock_scope.organisation_id,
           scope: Scope.to_map(stock_scope),
           input: %{"example_code" => example_code}
         }}
      else
        _other -> {:error, invalid_command()}
      end
    end

    @impl true
    def execute(_command, _context) do
      {:error, %{error: invalid_command(), domain_versions: %{}}}
    end

    defp invalid_command do
      %{
        "code" => "invalid_command",
        "message" => "The capability request is invalid",
        "details" => %{}
      }
    end
  end

  test "canonicalizes an organisation scope without persistence" do
    organisation_id = Ecto.UUID.generate()

    assert {:ok, %Scope{organisation_id: ^organisation_id} = scope} =
             Stock.new_scope(%{"organisation_id" => organisation_id})

    assert Scope.to_map(scope) == %{"organisation_id" => organisation_id}
  end

  test "rejects missing, noncanonical, and internally keyed scope input" do
    assert {:error, :invalid_stock_scope} = Stock.new_scope(%{})

    assert {:error, :invalid_stock_scope} =
             Stock.new_scope(%{"organisation_id" => "organisation-one"})

    assert {:error, :invalid_stock_scope} =
             Stock.new_scope(%{organisation_id: Ecto.UUID.generate()})

    assert {:error, :invalid_stock_scope} =
             Stock.new_scope(%{"organisation_id" => String.upcase(Ecto.UUID.generate())})
  end

  test "uses Core's command envelope instead of introducing a Stock command framework" do
    organisation_id = Ecto.UUID.generate()

    attributes = %{
      "principal_id" => Ecto.UUID.generate(),
      "device_id" => Ecto.UUID.generate(),
      "purpose" => "maintain_stock_catalog",
      "capability" => "stock.manage_items",
      "scope" => %{"organisation_id" => organisation_id},
      "input" => %{"example_code" => "NON-PERSISTED"},
      "expected_version" => 1,
      "idempotency_key" => "phase0-stock-validation"
    }

    assert {:ok, %Command{} = command} = Command.new(attributes, ValidateOnlyHandler)
    assert command.authorization_scope_id == organisation_id
    assert command.scope == %{"organisation_id" => organisation_id}
    assert command.input == %{"example_code" => "NON-PERSISTED"}
  end

  test "reserves an exact capability vocabulary without registering handlers" do
    capabilities = Stock.capabilities()

    assert capabilities == [
             "stock.view_positions",
             "stock.manage_items",
             "stock.manage_locations",
             "stock.move_quantity",
             "stock.adjust_quantity",
             "stock.count_positions",
             "stock.review_count",
             "stock.manage_monitoring"
           ]

    assert Enum.all?(capabilities, &Capabilities.known?/1)
    refute Capabilities.known?("stock.run_workflow")

    registered_handlers = Application.fetch_env!(:actualis_core, :capability_handlers)

    refute Enum.any?(registered_handlers, fn handler ->
             Code.ensure_loaded?(handler) and function_exported?(handler, :capability, 0) and
               handler.capability() in capabilities
           end)
  end

  test "reserves telemetry names without starting an unnecessary process" do
    assert Telemetry.prefix() == [:actualis, :stock]

    assert Telemetry.command_events() == [
             [:actualis, :stock, :command, :start],
             [:actualis, :stock, :command, :stop],
             [:actualis, :stock, :command, :exception]
           ]
  end

  test "does not introduce a Core dependency on Stock" do
    core_source_root = Path.expand("../../../actualis_core/lib", __DIR__)

    sources =
      core_source_root
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.map_join("\n", &File.read!/1)

    refute sources =~ "Actualis.Stock"
  end
end
