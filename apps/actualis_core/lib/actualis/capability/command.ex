defmodule Actualis.Capability.Command do
  @moduledoc "Canonical governed command shared by Core and domain handlers."

  alias Actualis.Capability.Handler

  @enforce_keys [
    :principal_id,
    :device_id,
    :purpose,
    :capability,
    :authorization_scope_id,
    :scope,
    :input,
    :expected_version,
    :idempotency_key
  ]
  defstruct @enforce_keys ++ [evidence_references: [], client_context: %{}]

  @type t :: %__MODULE__{
          principal_id: Ecto.UUID.t(),
          device_id: Ecto.UUID.t(),
          purpose: String.t(),
          capability: String.t(),
          authorization_scope_id: Ecto.UUID.t(),
          scope: map(),
          input: map(),
          expected_version: pos_integer(),
          idempotency_key: String.t(),
          evidence_references: list(),
          client_context: map()
        }

  @spec new(map(), module()) :: {:ok, t()} | {:error, Handler.error()}
  def new(attrs, handler) when is_map(attrs) do
    required =
      ~w(principal_id device_id purpose capability scope input expected_version idempotency_key)

    with true <- Enum.all?(required, &Map.has_key?(attrs, &1)),
         capability when is_binary(capability) <- attrs["capability"],
         ^capability <- handler.capability(),
         {:ok, principal_id} <- Ecto.UUID.cast(attrs["principal_id"]),
         {:ok, device_id} <- Ecto.UUID.cast(attrs["device_id"]),
         purpose when is_binary(purpose) and byte_size(purpose) >= 3 <- attrs["purpose"],
         version when is_integer(version) and version > 0 <- attrs["expected_version"],
         key when is_binary(key) and byte_size(key) >= 8 <- attrs["idempotency_key"],
         scope when is_map(scope) <- attrs["scope"],
         input when is_map(input) <- attrs["input"],
         references when is_list(references) <- Map.get(attrs, "evidence_references", []),
         client_context when is_map(client_context) <- Map.get(attrs, "client_context", %{}),
         {:ok, validated} <- handler.validate(scope, input),
         {:ok, authorization_scope_id} <-
           Ecto.UUID.cast(validated.authorization_scope_id) do
      {:ok,
       %__MODULE__{
         principal_id: principal_id,
         device_id: device_id,
         purpose: purpose,
         capability: capability,
         authorization_scope_id: authorization_scope_id,
         scope: validated.scope,
         input: validated.input,
         expected_version: version,
         idempotency_key: key,
         evidence_references: references,
         client_context: client_context
       }}
    else
      {:error, %{} = error} -> {:error, error}
      _ -> {:error, invalid_command()}
    end
  end

  def new(_attrs, _handler), do: {:error, invalid_command()}

  defp invalid_command do
    %{
      "code" => "invalid_command",
      "message" => "The capability request is invalid",
      "details" => %{}
    }
  end
end
