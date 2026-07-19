defmodule Actualis.Repo.Migrations.ExpandAuthorityScope do
  use Ecto.Migration

  def up do
    alter table(:authority_devices) do
      add :scope_id, :binary_id
      modify :site_id, :binary_id, null: true
    end

    alter table(:authority_assignments) do
      add :scope_id, :binary_id
      modify :site_id, :binary_id, null: true
    end

    execute("UPDATE authority_devices SET scope_id = site_id WHERE scope_id IS NULL")
    execute("UPDATE authority_assignments SET scope_id = site_id WHERE scope_id IS NULL")

    execute("ALTER TABLE authority_devices ALTER COLUMN scope_id SET NOT NULL")
    execute("ALTER TABLE authority_assignments ALTER COLUMN scope_id SET NOT NULL")

    create unique_index(:authority_assignments, [:principal_id, :scope_id],
             name: :authority_assignments_principal_id_scope_id_unique
           )
  end

  def down do
    execute("UPDATE authority_devices SET site_id = scope_id WHERE site_id IS NULL")
    execute("UPDATE authority_assignments SET site_id = scope_id WHERE site_id IS NULL")
    execute("ALTER TABLE authority_devices ALTER COLUMN site_id SET NOT NULL")
    execute("ALTER TABLE authority_assignments ALTER COLUMN site_id SET NOT NULL")

    drop_if_exists index(:authority_assignments, [:principal_id, :scope_id],
                     name: :authority_assignments_principal_id_scope_id_unique
                   )

    alter table(:authority_devices), do: remove(:scope_id)
    alter table(:authority_assignments), do: remove(:scope_id)
  end
end
