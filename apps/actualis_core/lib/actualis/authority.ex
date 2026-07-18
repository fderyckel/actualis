defmodule Actualis.Authority do
  @moduledoc "Purpose- and scope-aware in-process policy evaluation."
  import Ecto.Query

  alias Actualis.Authority.{Assignment, Device, Grant, Policy, Principal}
  alias Actualis.Repo

  def evaluate(command, now \\ DateTime.utc_now()) do
    with :ok <- principal(command.principal_id),
         :ok <- device(command.device_id, command.scope["site_id"], now),
         :ok <- assignment(command.principal_id, command.scope["site_id"], now),
         {:ok, grant, policy} <- grant(command, now) do
      %{
        "decision" => if(grant.obligations == [], do: "allow", else: "allow_with_obligations"),
        "permitted_fields" => grant.permitted_fields,
        "obligations" => grant.obligations,
        "policy_version" => policy.version,
        "explanation_code" => "assigned_operator_with_active_grant"
      }
    else
      {:error, code} -> denied(code)
    end
  end

  def allowed?(%{"decision" => decision}), do: decision in ["allow", "allow_with_obligations"]

  defp principal(id) do
    case Repo.get(Principal, id) do
      %Principal{kind: "human", status: "active"} -> :ok
      %Principal{} -> {:error, "principal_not_active_human"}
      nil -> {:error, "principal_not_found"}
    end
  end

  defp device(id, site_id, now) do
    query =
      from d in Device,
        join: p in Principal,
        on: p.id == d.principal_id,
        where:
          d.principal_id == ^id and d.site_id == ^site_id and d.status == "trusted" and
            p.kind == "device" and p.status == "active" and
            (is_nil(d.trust_expires_at) or d.trust_expires_at > ^now)

    if Repo.exists?(query), do: :ok, else: {:error, "device_not_trusted_for_site"}
  end

  defp assignment(principal_id, site_id, now) do
    query =
      from a in Assignment,
        where:
          a.principal_id == ^principal_id and a.site_id == ^site_id and a.valid_from <= ^now and
            (is_nil(a.expires_at) or a.expires_at > ^now)

    if Repo.exists?(query), do: :ok, else: {:error, "operator_not_assigned_to_site"}
  end

  defp grant(command, now) do
    site_id = command.scope["site_id"]

    query =
      from g in Grant,
        join: p in Policy,
        on: p.id == g.policy_id,
        where:
          g.principal_id == ^command.principal_id and g.capability == ^command.capability and
            g.scope_id == ^site_id and g.purpose == ^command.purpose and
            (is_nil(g.expires_at) or g.expires_at > ^now) and p.status == "approved" and
            p.effective_from <= ^now,
        order_by: [desc: p.effective_from],
        limit: 1,
        select: {g, p}

    case Repo.one(query) do
      nil -> {:error, "no_active_capability_grant"}
      result -> {:ok, elem(result, 0), elem(result, 1)}
    end
  end

  defp denied(code) do
    %{
      "decision" => "deny",
      "permitted_fields" => [],
      "obligations" => [],
      "policy_version" => nil,
      "explanation_code" => code
    }
  end
end
