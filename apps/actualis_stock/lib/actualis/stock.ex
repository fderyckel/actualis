defmodule Actualis.Stock do
  @moduledoc """
  Public boundary for the Actualis Stock domain application.

  Phase 0 exposes Stock's stable capability vocabulary and canonical organisation scope. Items,
  locations, movements, balances, stocktakes, and monitoring are not implemented yet.

  Future callers must use explicit business functions added to this module rather than Stock
  schemas or persistence helpers.
  """

  alias Actualis.Stock.{Capabilities, Scope}

  @doc "Validates and canonicalizes the organisation scope used by Stock handlers."
  @spec new_scope(term()) :: {:ok, Scope.t()} | {:error, :invalid_stock_scope}
  def new_scope(attributes) do
    Scope.new(attributes)
  end

  @doc "Returns the capability identifiers reserved by the Stock domain application."
  @spec capabilities() :: [Capabilities.t()]
  def capabilities do
    Capabilities.all()
  end
end
