defmodule Actualis.Repo.Migrations.AddEvidenceAuthorizationScope do
  use Ecto.Migration

  def up do
    alter table(:evidence_records) do
      add :authorization_scope_id, :binary_id
    end

    execute("""
    UPDATE evidence_records
    SET authorization_scope_id =
      COALESCE(NULLIF(scope->>'scope_id', ''), NULLIF(scope->>'site_id', ''))::uuid
    WHERE authorization_scope_id IS NULL
    """)

    execute("ALTER TABLE evidence_records ALTER COLUMN authorization_scope_id SET NOT NULL")
    create index(:evidence_records, [:authorization_scope_id, :occurred_at])
  end

  def down do
    drop_if_exists index(:evidence_records, [:authorization_scope_id, :occurred_at])

    alter table(:evidence_records) do
      remove :authorization_scope_id
    end
  end
end
