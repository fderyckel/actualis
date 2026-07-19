defmodule Actualis.Model do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end

defmodule Actualis.Authority.Principal do
  @moduledoc false
  use Actualis.Model

  schema "authority_principals" do
    field :external_subject, :string
    field :kind, :string
    field :display_name, :string
    field :status, :string, default: "active"
    timestamps()
  end
end

defmodule Actualis.Authority.Device do
  @moduledoc false
  use Actualis.Model

  schema "authority_devices" do
    field :principal_id, :binary_id
    field :scope_id, :binary_id
    field :legacy_site_id, :binary_id, source: :site_id
    field :status, :string, default: "trusted"
    field :trust_expires_at, :utc_datetime_usec
    timestamps()
  end
end

defmodule Actualis.Authority.Assignment do
  @moduledoc false
  use Actualis.Model

  schema "authority_assignments" do
    field :principal_id, :binary_id
    field :scope_id, :binary_id
    field :legacy_site_id, :binary_id, source: :site_id
    field :valid_from, :utc_datetime_usec
    field :expires_at, :utc_datetime_usec
    timestamps()
  end
end

defmodule Actualis.Authority.Policy do
  @moduledoc false
  use Actualis.Model

  schema "authority_policies" do
    field :version, :string
    field :status, :string
    field :effective_from, :utc_datetime_usec
    timestamps()
  end
end

defmodule Actualis.Authority.Grant do
  @moduledoc false
  use Actualis.Model

  schema "authority_grants" do
    field :principal_id, :binary_id
    field :policy_id, :binary_id
    field :capability, :string
    field :scope_id, :binary_id
    field :purpose, :string
    field :permitted_fields, {:array, :string}, default: []
    field :obligations, {:array, :string}, default: []
    field :expires_at, :utc_datetime_usec
    timestamps()
  end
end

defmodule Actualis.Execution.Receipt do
  @moduledoc false
  use Actualis.Model

  schema "execution_receipts" do
    field :principal_id, :binary_id
    field :idempotency_key, :string
    field :capability, :string
    field :request_hash, :string
    field :status, :string
    field :outcome, :string
    field :response, :map
    timestamps()
  end
end

defmodule Actualis.Evidence.Record do
  @moduledoc false
  use Actualis.Model

  schema "evidence_records" do
    field :receipt_id, :binary_id
    field :principal_id, :binary_id
    field :device_id, :binary_id
    field :purpose, :string
    field :capability, :string
    field :scope, :map
    field :input, :map
    field :decision, :string
    field :explanation_code, :string
    field :policy_version, :string
    field :domain_versions, :map, default: %{}
    field :effects, :map, default: %{}
    field :occurred_at, :utc_datetime_usec
    timestamps(updated_at: false)
  end
end

defmodule Actualis.Execution.Event do
  @moduledoc false
  use Actualis.Model

  schema "execution_outbox" do
    field :event_type, :string
    field :aggregate_id, :binary_id
    field :aggregate_version, :integer
    field :payload, :map
    field :occurred_at, :utc_datetime_usec
    field :published_at, :utc_datetime_usec
    timestamps(updated_at: false)
  end
end
