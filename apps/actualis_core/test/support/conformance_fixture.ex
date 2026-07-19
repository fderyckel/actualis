defmodule Actualis.ConformanceFixture do
  @moduledoc false

  alias Actualis.Authority.{Assignment, Device, Grant, Policy, Principal}
  alias Actualis.Repo

  @capability "conformance.record_effect"

  def capability, do: @capability

  def create do
    now = DateTime.utc_now()
    scope_id = Ecto.UUID.generate()

    operator =
      insert(%Principal{
        external_subject: unique("conformance-human"),
        kind: "human",
        display_name: "Conformance principal"
      })

    device =
      insert(%Principal{
        external_subject: unique("conformance-device"),
        kind: "device",
        display_name: "Conformance device"
      })

    insert(%Device{principal_id: device.id, scope_id: scope_id, status: "trusted"})

    insert(%Assignment{
      principal_id: operator.id,
      scope_id: scope_id,
      valid_from: DateTime.add(now, -1, :hour)
    })

    policy =
      insert(%Policy{
        version: unique("conformance-policy"),
        status: "approved",
        effective_from: DateTime.add(now, -1, :hour)
      })

    insert(%Grant{
      principal_id: operator.id,
      policy_id: policy.id,
      capability: capability(),
      scope_id: scope_id,
      purpose: "verify_core_contract",
      permitted_fields: ["record_id", "version"],
      obligations: ["record_evidence"]
    })

    %{
      operator: operator,
      device: device,
      policy: policy,
      scope_id: scope_id,
      record_id: Ecto.UUID.generate()
    }
  end

  def command(fixture, overrides \\ %{}) do
    base = %{
      "principal_id" => fixture.operator.id,
      "device_id" => fixture.device.id,
      "purpose" => "verify_core_contract",
      "capability" => capability(),
      "scope" => %{"scope_id" => fixture.scope_id},
      "input" => %{
        "record_id" => fixture.record_id,
        "value" => "conformance-effect",
        "rollback_after_event" => false
      },
      "expected_version" => 1,
      "idempotency_key" => "test-#{Ecto.UUID.generate()}"
    }

    deep_merge(base, overrides)
  end

  defp insert(struct), do: Repo.insert!(struct)
  defp unique(prefix), do: "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"

  defp deep_merge(left, right) do
    Map.merge(left, right, fn _, left_value, right_value ->
      if is_map(left_value) and is_map(right_value),
        do: deep_merge(left_value, right_value),
        else: right_value
    end)
  end

  defmodule Handler do
    @moduledoc false

    @behaviour Actualis.Capability.Handler

    alias Actualis.Capability.Command
    alias Actualis.Delivery
    alias Actualis.Repo

    @impl true
    def capability, do: Actualis.ConformanceFixture.capability()

    @impl true
    def validate(scope, input) do
      with {:ok, scope_id} <- Ecto.UUID.cast(scope["scope_id"]),
           {:ok, record_id} <- Ecto.UUID.cast(input["record_id"]),
           value when is_binary(value) and byte_size(value) > 0 <- input["value"],
           rollback when is_boolean(rollback) <- input["rollback_after_event"] do
        {:ok,
         %{
           authorization_scope_id: scope_id,
           scope: %{"scope_id" => scope_id},
           input: %{
             "record_id" => record_id,
             "value" => value,
             "rollback_after_event" => rollback
           }
         }}
      else
        _ -> {:error, invalid_command()}
      end
    end

    @impl true
    def execute(%Command{} = command, context) do
      event =
        Delivery.append_event!(%{
          event_type: "conformance.effect_recorded.v1",
          aggregate_id: command.input["record_id"],
          aggregate_version: command.expected_version + 1,
          payload: %{
            "schema_version" => "1.0",
            "command_id" => context.receipt_id,
            "evidence_id" => context.evidence_id,
            "record_id" => command.input["record_id"],
            "value" => command.input["value"]
          },
          occurred_at: context.occurred_at
        })

      if command.input["rollback_after_event"], do: Repo.rollback(:fixture_requested_rollback)

      {:ok,
       %{
         domain_versions: %{
           "conformance_record" => %{
             "read" => command.expected_version,
             "committed" => command.expected_version + 1
           }
         },
         effects: %{
           "record_id" => command.input["record_id"],
           "outbox_event_id" => event.id
         }
       }}
    end

    defp invalid_command do
      %{
        "code" => "invalid_command",
        "message" => "The capability request is invalid",
        "details" => %{}
      }
    end
  end
end
