defmodule ActualisWeb.Router do
  use ActualisWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :governed do
    plug ActualisWeb.IdentityPlug
  end

  scope "/api", ActualisWeb do
    pipe_through :api
    get "/health", ActualisController, :health
    get "/openapi.json", ActualisController, :openapi
  end

  scope "/api/v1", ActualisWeb do
    pipe_through [:api, :governed]
    post "/capabilities/manufacturing.move_pallet", ActualisController, :move
    get "/projections/:view/snapshot", ActualisController, :snapshot
    get "/projections/:view/deltas", ActualisController, :deltas
    get "/evidence/:id", ActualisController, :evidence
  end
end
