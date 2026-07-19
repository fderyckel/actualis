defmodule ActualisManufacturing.Movement do
  @moduledoc false

  use Actualis.Model

  schema "manufacturing_movements" do
    field :pallet_id, :binary_id
    field :source_location_id, :binary_id
    field :destination_location_id, :binary_id
    field :receipt_id, :binary_id
    field :performed_by_id, :binary_id
    field :reason, :string
    field :pallet_version, :integer
    field :occurred_at, :utc_datetime_usec
    timestamps(updated_at: false)
  end
end
