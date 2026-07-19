defmodule Actualis.Repo.Migrations.DetachAuthorityScopeFromManufacturing do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE authority_devices DROP CONSTRAINT IF EXISTS authority_devices_site_id_fkey",
      "ALTER TABLE authority_devices ADD CONSTRAINT authority_devices_site_id_fkey " <>
        "FOREIGN KEY (site_id) REFERENCES manufacturing_sites(id)"
    )

    execute(
      "ALTER TABLE authority_assignments DROP CONSTRAINT IF EXISTS authority_assignments_site_id_fkey",
      "ALTER TABLE authority_assignments ADD CONSTRAINT authority_assignments_site_id_fkey " <>
        "FOREIGN KEY (site_id) REFERENCES manufacturing_sites(id)"
    )
  end
end
