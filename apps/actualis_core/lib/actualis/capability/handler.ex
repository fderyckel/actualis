defmodule Actualis.Capability.Handler do
  @moduledoc "Contract implemented by domain-owned governed capability handlers."

  alias Actualis.Capability.Command

  @type error :: %{required(String.t()) => term()}
  @type validated_domain_input :: %{
          required(:authorization_scope_id) => Ecto.UUID.t(),
          required(:scope) => map(),
          required(:input) => map()
        }
  @type execution_context :: %{
          required(:receipt_id) => Ecto.UUID.t(),
          required(:evidence_id) => Ecto.UUID.t(),
          required(:occurred_at) => DateTime.t()
        }
  @type result :: %{
          required(:domain_versions) => map(),
          required(:effects) => map()
        }
  @type rejection :: %{
          required(:error) => error(),
          required(:domain_versions) => map()
        }

  @callback capability() :: String.t()

  @doc """
  Canonicalizes product-owned scope and input and selects the generic authority scope.

  This callback runs before authority evaluation and must be deterministic and side-effect-free. It
  must not query or mutate persistence, call an external system, read wall time, or generate values.
  """
  @callback validate(scope :: map(), input :: map()) ::
              {:ok, validated_domain_input()} | {:error, error()}

  @doc "Performs authorized product work inside the transaction opened by Core."
  @callback execute(Command.t(), execution_context()) ::
              {:ok, result()} | {:error, rejection()}
end
