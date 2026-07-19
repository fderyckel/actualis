defmodule ActualisManufacturing.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Actualis.Repo
    end
  end

  setup tags do
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Actualis.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)
  end
end
