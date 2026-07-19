defmodule ActualisManufacturing do
  @moduledoc "Manufacturing application boundary built on governed Actualis Core contracts."

  alias Actualis.CapabilityRuntime
  alias ActualisManufacturing.Projection

  @spec execute(map()) :: {:ok, map()} | {:error, map()}
  def execute(attrs), do: CapabilityRuntime.execute(attrs)

  defdelegate snapshot(identity, site_id, purpose, view), to: Projection
  defdelegate deltas(identity, site_id, purpose, view, after_cursor), to: Projection
end
