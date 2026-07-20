defmodule Actualis.Stock.Capabilities do
  @moduledoc """
  Stable capability identifiers reserved by the Stock domain application.

  These identifiers are authorization contracts, not display labels. Reserving a name does not
  register a handler or make the corresponding operation available.
  """

  @capabilities [
    "stock.view_positions",
    "stock.manage_items",
    "stock.manage_locations",
    "stock.move_quantity",
    "stock.adjust_quantity",
    "stock.count_positions",
    "stock.review_count",
    "stock.manage_monitoring"
  ]

  @type t() :: String.t()

  @doc "Returns every reserved Stock capability identifier."
  @spec all() :: [t()]
  def all do
    @capabilities
  end

  @doc "Returns whether a value is a reserved Stock capability identifier."
  @spec known?(term()) :: boolean()
  def known?(capability) do
    capability in @capabilities
  end
end
