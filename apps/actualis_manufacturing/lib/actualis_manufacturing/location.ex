defmodule ActualisManufacturing.Location do
  @moduledoc false

  use Actualis.Model

  schema "manufacturing_locations" do
    field :site_id, :binary_id
    field :code, :string
    field :active, :boolean, default: true
    timestamps()
  end
end
