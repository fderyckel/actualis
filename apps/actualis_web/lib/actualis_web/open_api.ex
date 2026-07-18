defmodule ActualisWeb.OpenAPI do
  @moduledoc false
  def spec do
    %{
      "openapi" => "3.1.0",
      "info" => %{"title" => "Actualis Core API", "version" => "0.1.0"},
      "paths" => %{
        "/api/health" => %{"get" => %{"responses" => %{"200" => %{"description" => "healthy"}}}},
        "/api/v1/capabilities/manufacturing.move_pallet" => %{
          "post" => %{"summary" => "Governed pallet movement"}
        },
        "/api/v1/projections/{view}/snapshot" => %{
          "get" => %{"summary" => "Purpose-scoped snapshot"}
        },
        "/api/v1/projections/{view}/deltas" => %{"get" => %{"summary" => "Ordered catch-up"}},
        "/api/v1/evidence/{id}" => %{"get" => %{"summary" => "Evidence reconstruction"}}
      }
    }
  end
end
