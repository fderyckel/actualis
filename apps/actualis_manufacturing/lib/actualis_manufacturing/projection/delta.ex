defmodule ActualisManufacturing.Projection.Delta do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:cursor, :id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "projection_deltas" do
    field :event_id, :binary_id
    field :projection, :string
    field :scope_id, :binary_id
    field :payload, :map
    field :expires_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    timestamps(updated_at: false)
  end
end
