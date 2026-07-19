defmodule Actualis.Evidence do
  @moduledoc "Purpose-scoped reconstruction from retained evidence."
  import Ecto.Query
  alias Actualis.Authority
  alias Actualis.Evidence.Record
  alias Actualis.Execution.Receipt
  alias Actualis.Repo

  def fetch(identity, evidence_id, site_id, purpose) do
    decision =
      Authority.evaluate(%{
        principal_id: identity.principal_id,
        device_id: identity.device_id,
        capability: "evidence.read",
        purpose: purpose,
        authorization_scope_id: site_id,
        scope: %{"site_id" => site_id}
      })

    if Authority.allowed?(decision),
      do: fetch_allowed(evidence_id, site_id, decision),
      else: {:error, error("authorization_denied", "Evidence access is denied", decision)}
  end

  defp fetch_allowed(id, site_id, decision) do
    query =
      from e in Record,
        join: r in Receipt,
        on: r.id == e.receipt_id,
        where: e.id == ^id and fragment("?->>'site_id' = ?", e.scope, ^site_id),
        select: {e, r}

    case Repo.one(query) do
      {e, r} ->
        {:ok,
         %{
           "evidence" => %{
             "id" => e.id,
             "command_id" => e.receipt_id,
             "principal_id" => e.principal_id,
             "device_id" => e.device_id,
             "purpose" => e.purpose,
             "capability" => e.capability,
             "scope" => e.scope,
             "input" => e.input,
             "decision" => e.decision,
             "explanation_code" => e.explanation_code,
             "policy_version" => e.policy_version,
             "domain_versions" => e.domain_versions,
             "effects" => e.effects,
             "outcome" => r.outcome,
             "occurred_at" => e.occurred_at
           },
           "authorization" => decision
         }}

      nil ->
        {:error, error("evidence_not_found", "Evidence was not found in this scope")}
    end
  end

  defp error(code, message, details \\ %{}),
    do: %{"code" => code, "message" => message, "details" => details}
end
