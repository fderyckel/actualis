defmodule ActualisManufacturing.Pallet do
  @moduledoc false

  use Actualis.Model

  schema "manufacturing_pallets" do
    field :site_id, :binary_id
    field :current_location_id, :binary_id
    field :label, :string
    field :material_code, :string
    field :quality_status, :string, default: "released"
    field :version, :integer, default: 1
    timestamps()
  end
end
