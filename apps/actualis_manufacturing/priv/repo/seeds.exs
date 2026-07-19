alias Actualis.Authority.{Assignment, Device, Grant, Policy, Principal}
alias Actualis.Repo
alias ActualisManufacturing.{Location, Pallet, Site}

now = DateTime.utc_now()

ids = %{
  site: "11111111-1111-4111-8111-111111111111",
  source: "22222222-2222-4222-8222-222222222221",
  destination: "22222222-2222-4222-8222-222222222222",
  operator: "33333333-3333-4333-8333-333333333333",
  device: "44444444-4444-4444-8444-444444444444",
  policy: "66666666-6666-4666-8666-666666666662",
  pallet: "77777777-7777-4777-8777-777777777777"
}

insert = fn struct -> Repo.insert!(struct, on_conflict: :nothing) end

insert.(%Principal{
  id: ids.operator,
  external_subject: "oidc|demo-operator",
  kind: "human",
  display_name: "Demo Operator"
})

insert.(%Principal{
  id: ids.device,
  external_subject: "device|demo-tablet",
  kind: "device",
  display_name: "Demo Tablet"
})

insert.(%Site{id: ids.site, code: "BE-01", name: "Actualis Demo Cell"})
insert.(%Location{id: ids.source, site_id: ids.site, code: "RECV-01"})
insert.(%Location{id: ids.destination, site_id: ids.site, code: "STOR-01"})

insert.(%Device{
  principal_id: ids.device,
  scope_id: ids.site,
  legacy_site_id: ids.site,
  status: "trusted"
})

insert.(%Assignment{
  principal_id: ids.operator,
  scope_id: ids.site,
  legacy_site_id: ids.site,
  valid_from: DateTime.add(now, -1, :day)
})

insert.(%Policy{
  id: ids.policy,
  version: "2026.07.1",
  status: "approved",
  effective_from: DateTime.add(now, -1, :day)
})

for {capability, purpose, fields} <- [
      {"manufacturing.move_pallet", "fulfil_material_movement", ["pallet_id", "version"]},
      {"manufacturing.view_operator", "fulfil_material_movement",
       [
         "pallet_id",
         "label",
         "location_id",
         "location_code",
         "destination_location_id",
         "version",
         "status",
         "updated_at"
       ]},
      {"manufacturing.view_supervisor", "supervise_material_flow",
       [
         "pallet_id",
         "label",
         "material_code",
         "quality_status",
         "location_id",
         "location_code",
         "source_location_id",
         "destination_location_id",
         "reason",
         "performed_by_id",
         "evidence_id",
         "version",
         "status",
         "updated_at"
       ]},
      {"evidence.read", "supervise_material_flow", ["*"]}
    ] do
  insert.(%Grant{
    principal_id: ids.operator,
    policy_id: ids.policy,
    capability: capability,
    scope_id: ids.site,
    purpose: purpose,
    permitted_fields: fields,
    obligations: ["record_access", "expire_projection_in_8_hours"]
  })
end

insert.(%Pallet{
  id: ids.pallet,
  site_id: ids.site,
  current_location_id: ids.source,
  label: "PLT-0001",
  material_code: "MAT-ACT-001",
  quality_status: "released",
  version: 1
})

IO.puts(
  "Seeded demo: site=#{ids.site} operator=#{ids.operator} device=#{ids.device} pallet=#{ids.pallet}"
)
