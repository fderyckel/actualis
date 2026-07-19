defmodule ActualisManufacturing.Site do
  @moduledoc false

  use Actualis.Model

  schema "manufacturing_sites" do
    field :code, :string
    field :name, :string
    timestamps()
  end
end
