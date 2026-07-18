defmodule Actualis.Repo.Migrations.CreateKernel do
  use Ecto.Migration

  def change do
    create table(:authority_principals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :external_subject, :string, null: false
      add :kind, :string, null: false
      add :display_name, :string, null: false
      add :status, :string, null: false, default: "active"
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:authority_principals, [:external_subject])

    create table(:manufacturing_sites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string, null: false
      add :name, :string, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:manufacturing_sites, [:code])

    create table(:manufacturing_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :site_id, references(:manufacturing_sites, type: :binary_id), null: false
      add :code, :string, null: false
      add :active, :boolean, null: false, default: true
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:manufacturing_locations, [:site_id, :code])

    create table(:authority_devices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :principal_id, references(:authority_principals, type: :binary_id), null: false
      add :site_id, references(:manufacturing_sites, type: :binary_id), null: false
      add :status, :string, null: false, default: "trusted"
      add :trust_expires_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:authority_devices, [:principal_id])

    create table(:authority_assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :principal_id, references(:authority_principals, type: :binary_id), null: false
      add :site_id, references(:manufacturing_sites, type: :binary_id), null: false
      add :valid_from, :utc_datetime_usec, null: false
      add :expires_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:authority_assignments, [:principal_id, :site_id])

    create table(:authority_policies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :version, :string, null: false
      add :status, :string, null: false
      add :effective_from, :utc_datetime_usec, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:authority_policies, [:version])

    create table(:authority_grants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :principal_id, references(:authority_principals, type: :binary_id), null: false
      add :policy_id, references(:authority_policies, type: :binary_id), null: false
      add :capability, :string, null: false
      add :scope_id, :binary_id, null: false
      add :purpose, :string, null: false
      add :permitted_fields, {:array, :string}, null: false, default: []
      add :obligations, {:array, :string}, null: false, default: []
      add :expires_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create index(:authority_grants, [:principal_id, :capability, :scope_id, :purpose])

    create table(:manufacturing_pallets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :site_id, references(:manufacturing_sites, type: :binary_id), null: false

      add :current_location_id, references(:manufacturing_locations, type: :binary_id),
        null: false

      add :label, :string, null: false
      add :material_code, :string, null: false
      add :quality_status, :string, null: false, default: "released"
      add :version, :bigint, null: false, default: 1
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:manufacturing_pallets, [:site_id, :label])
    create constraint(:manufacturing_pallets, :positive_version, check: "version > 0")

    create table(:execution_receipts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :principal_id, references(:authority_principals, type: :binary_id), null: false
      add :idempotency_key, :string, null: false
      add :capability, :string, null: false
      add :request_hash, :string, null: false
      add :status, :string, null: false
      add :outcome, :string
      add :response, :map
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:execution_receipts, [:principal_id, :idempotency_key])

    create table(:manufacturing_movements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pallet_id, references(:manufacturing_pallets, type: :binary_id), null: false
      add :source_location_id, references(:manufacturing_locations, type: :binary_id), null: false

      add :destination_location_id, references(:manufacturing_locations, type: :binary_id),
        null: false

      add :receipt_id, references(:execution_receipts, type: :binary_id), null: false
      add :performed_by_id, references(:authority_principals, type: :binary_id), null: false
      add :reason, :string, null: false
      add :pallet_version, :bigint, null: false
      add :occurred_at, :utc_datetime_usec, null: false
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:manufacturing_movements, [:receipt_id])

    create table(:evidence_records, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :receipt_id, references(:execution_receipts, type: :binary_id), null: false
      add :principal_id, :binary_id, null: false
      add :device_id, :binary_id, null: false
      add :purpose, :string, null: false
      add :capability, :string, null: false
      add :scope, :map, null: false
      add :input, :map, null: false
      add :decision, :string, null: false
      add :explanation_code, :string, null: false
      add :policy_version, :string
      add :domain_versions, :map, null: false, default: %{}
      add :effects, :map, null: false, default: %{}
      add :occurred_at, :utc_datetime_usec, null: false
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:evidence_records, [:receipt_id])

    create table(:execution_outbox, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_type, :string, null: false
      add :aggregate_id, :binary_id, null: false
      add :aggregate_version, :bigint, null: false
      add :payload, :map, null: false
      add :occurred_at, :utc_datetime_usec, null: false
      add :published_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:execution_outbox, [:published_at, :inserted_at])

    create table(:projection_deltas, primary_key: false) do
      add :cursor, :bigserial, primary_key: true
      add :event_id, references(:execution_outbox, type: :binary_id), null: false
      add :projection, :string, null: false
      add :scope_id, :binary_id, null: false
      add :payload, :map, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :revoked_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:projection_deltas, [:event_id, :projection])
    create index(:projection_deltas, [:projection, :scope_id, :cursor])
  end
end
