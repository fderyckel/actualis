defmodule Actualis.Stock.Scope do
  @moduledoc """
  Canonical organisation scope supplied by a Stock capability handler to Actualis Core.

  Core treats the organisation identifier as an opaque authorization scope. Constructing this
  value does not prove cell placement, authenticate a principal, or grant a capability.
  """

  @enforce_keys [:organisation_id]
  defstruct [:organisation_id]

  @type t() :: %__MODULE__{organisation_id: Ecto.UUID.t()}

  @doc "Builds a scope from external string-keyed attributes and requires a canonical UUID."
  @spec new(term()) :: {:ok, t()} | {:error, :invalid_stock_scope}
  def new(%{"organisation_id" => organisation_id}) when is_binary(organisation_id) do
    case Ecto.UUID.cast(organisation_id) do
      {:ok, ^organisation_id} -> {:ok, %__MODULE__{organisation_id: organisation_id}}
      _other -> {:error, :invalid_stock_scope}
    end
  end

  def new(_attributes), do: {:error, :invalid_stock_scope}

  @doc "Returns the canonical external representation retained in a Core command and evidence."
  @spec to_map(t()) :: %{required(String.t()) => Ecto.UUID.t()}
  def to_map(%__MODULE__{organisation_id: organisation_id}) do
    %{"organisation_id" => organisation_id}
  end
end
