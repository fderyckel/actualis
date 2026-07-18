defmodule Actualis.Repo do
  use Ecto.Repo,
    otp_app: :actualis_core,
    adapter: Ecto.Adapters.Postgres
end
