defmodule ActualisManufacturing.TestFixture do
  @moduledoc false

  alias Actualis.Authority.{Assignment, Device, Grant, Policy, Principal}
  alias Actualis.Repo
  alias ActualisManufacturing.{Location, Pallet, Site}

  def create(opts \\ %{}) do
    now = DateTime.utc_now()

    operator =
      insert(%Principal{
        external_subject: unique("human"),
        kind: "human",
        display_name: "Operator"
      })

    device =
      insert(%Principal{
        external_subject: unique("device"),
        kind: "device",
        display_name: "Tablet"
      })

    site = insert(%Site{code: unique("site"), name: "Test site"})
    source = insert(%Location{site_id: site.id, code: unique("source")})
    destination = insert(%Location{site_id: site.id, code: unique("dest")})

    insert(%Device{
      principal_id: device.id,
      scope_id: site.id,
      legacy_site_id: site.id,
      status: Map.get(opts, :device_status, "trusted")
    })

    insert(%Assignment{
      principal_id: operator.id,
      scope_id: site.id,
      legacy_site_id: site.id,
      valid_from: DateTime.add(now, -1, :hour)
    })

    policy =
      insert(%Policy{
        version: unique("policy"),
        status: "approved",
        effective_from: DateTime.add(now, -1, :hour)
      })

    grant(operator, site, policy, "manufacturing.move_pallet", "fulfil_material_movement", [
      "pallet_id",
      "version"
    ])

    grant(
      operator,
      site,
      policy,
      "manufacturing.view_operator",
      "fulfil_material_movement",
      [
        "pallet_id",
        "label",
        "location_id",
        "location_code",
        "destination_location_id",
        "version",
        "status",
        "updated_at"
      ]
    )

    grant(
      operator,
      site,
      policy,
      "manufacturing.view_supervisor",
      "supervise_material_flow",
      [
        "pallet_id",
        "label",
        "material_code",
        "quality_status",
        "location_id",
        "location_code",
        "version",
        "status"
      ]
    )

    grant(operator, site, policy, "evidence.read", "supervise_material_flow", ["*"])

    pallet =
      insert(%Pallet{
        site_id: site.id,
        current_location_id: source.id,
        label: unique("pallet"),
        material_code: "MAT-1",
        quality_status: Map.get(opts, :quality_status, "released"),
        version: 1
      })

    %{
      operator: operator,
      device: device,
      site: site,
      source: source,
      destination: destination,
      pallet: pallet,
      policy: policy,
      identity: %{principal_id: operator.id, device_id: device.id}
    }
  end

  def command(fixture, overrides \\ %{}) do
    base = %{
      "principal_id" => fixture.operator.id,
      "device_id" => fixture.device.id,
      "purpose" => "fulfil_material_movement",
      "capability" => "manufacturing.move_pallet",
      "scope" => %{"site_id" => fixture.site.id},
      "input" => %{
        "pallet_id" => fixture.pallet.id,
        "source_location_id" => fixture.source.id,
        "destination_location_id" => fixture.destination.id,
        "reason" => "Replenish production"
      },
      "expected_version" => 1,
      "idempotency_key" => "test-#{Ecto.UUID.generate()}"
    }

    deep_merge(base, overrides)
  end

  defp grant(operator, site, policy, capability, purpose, fields) do
    insert(%Grant{
      principal_id: operator.id,
      policy_id: policy.id,
      capability: capability,
      scope_id: site.id,
      purpose: purpose,
      permitted_fields: fields,
      obligations: ["record_access", "expire_projection_in_8_hours"]
    })
  end

  defp insert(struct), do: Repo.insert!(struct)
  defp unique(prefix), do: "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"

  defp deep_merge(left, right) do
    Map.merge(left, right, fn _, left_value, right_value ->
      if is_map(left_value) and is_map(right_value),
        do: deep_merge(left_value, right_value),
        else: right_value
    end)
  end
end
