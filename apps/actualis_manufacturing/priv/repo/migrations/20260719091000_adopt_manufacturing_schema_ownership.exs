defmodule ActualisManufacturing.Repo.Migrations.AdoptManufacturingSchemaOwnership do
  use Ecto.Migration

  @tables ~w(
    manufacturing_sites
    manufacturing_locations
    manufacturing_pallets
    manufacturing_movements
    projection_deltas
  )

  def up do
    Enum.each(@tables, fn table ->
      execute("COMMENT ON TABLE #{table} IS 'Owned by the actualis_manufacturing application'")
    end)
  end

  def down do
    Enum.each(@tables, fn table ->
      execute("COMMENT ON TABLE #{table} IS NULL")
    end)
  end
end
