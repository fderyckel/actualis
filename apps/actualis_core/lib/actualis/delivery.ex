defmodule Actualis.Delivery do
  @moduledoc "Transactional port for appending versioned domain event envelopes."

  import Ecto.Changeset

  alias Actualis.Execution.Event
  alias Actualis.Repo

  @fields ~w(event_type aggregate_id aggregate_version payload occurred_at)a

  @spec append_event!(map()) :: Event.t()
  def append_event!(attrs) do
    %Event{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> Repo.insert!()
  end
end
