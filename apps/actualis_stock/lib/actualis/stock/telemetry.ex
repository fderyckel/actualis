defmodule Actualis.Stock.Telemetry do
  @moduledoc """
  Telemetry names reserved for future Stock command boundaries.

  Phase 0 declares names only. Later phases emit them around implemented public operations and add
  metrics at the operations boundary.
  """

  @prefix [:actualis, :stock]
  @command_events [
    [:actualis, :stock, :command, :start],
    [:actualis, :stock, :command, :stop],
    [:actualis, :stock, :command, :exception]
  ]

  @doc "Returns the common Stock telemetry prefix."
  @spec prefix() :: [atom()]
  def prefix do
    @prefix
  end

  @doc "Returns the events reserved for future public Stock commands."
  @spec command_events() :: [[atom()]]
  def command_events do
    @command_events
  end
end
