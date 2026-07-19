---
title: Fresh-VM deployment status
doc_type: technical
audience: agents_and_maintainers
kernel_area: deployment
status: partial
source_paths:
  - .tool-versions
  - bin/dev-db
  - bin/setup
  - config/dev.exs
  - config/prod.exs
  - config/runtime.exs
  - README.md
test_paths:
  - none
paired_user_docs:
  - docs/user/installation/fresh-vm.md
last_verified: 2026-07-19
---

# Fresh-VM deployment status

## Current status

A fresh Debian or Ubuntu VM can run the kernel as a source-based evaluation environment. A
production deployment is unavailable.

Docker Engine and the Compose plugin may be installed as host prerequisites, but the repository has
no `Dockerfile`, `.dockerignore`, Compose manifest, published image, image-signing policy, or
container rollback procedure. `docker compose up` is therefore not an Actualis installation path.

## Supported evaluation topology

```text
administrator workstation
        |
        | SSH tunnel: workstation 127.0.0.1:4000
        v
minimal Debian/Ubuntu VM
  Phoenix development endpoint: 127.0.0.1:4000
        |
        v
  PostgreSQL 18: 127.0.0.1:5432
```

The canonical administrator procedure is [Prepare a fresh Debian or Ubuntu VM for
Actualis](../../user/installation/fresh-vm.md). It uses PGDG PostgreSQL packages and `mise` to read
the repository's pinned Erlang, Elixir, and Node.js versions.

This topology is for evaluation only. It deliberately exposes no application or database port on a
public interface.

## Repository evidence

| Concern | Current evidence | Status |
| --- | --- | --- |
| Runtime versions | `.tool-versions` pins Erlang/OTP 29.0.3, Elixir 1.20.2, Node.js 24.15.0, and PostgreSQL 18.4 | Implemented for local tooling |
| Development database | `config/dev.exs` reads `ACTUALIS_DATABASE_URL`; `config/test.exs` reads `ACTUALIS_TEST_DATABASE_URL` | Implemented |
| Development endpoint | `config/dev.exs` binds Phoenix to `127.0.0.1` | Implemented |
| Local setup | `bin/setup` starts a repository-local PostgreSQL cluster and runs `ecto.setup` | Partial; its default PostgreSQL path is Homebrew-specific |
| Production secrets | `config/runtime.exs` requires `DATABASE_URL` and `SECRET_KEY_BASE` in production | Partial |
| Production endpoint | `config/prod.exs` uses the placeholder host `example.com`; release server startup remains commented in `config/runtime.exs` | Not deployable |
| Release artifact | No OTP release overlay, release migration command, package, or artifact digest exists | Planned |
| Containers | No application container or Compose definition exists | Planned |
| Network edge | No reverse proxy, certificate automation, trusted-proxy policy, or production authentication exists | Planned |
| Recovery | No production backup, restore, migration rehearsal, or rollback runbook exists | Planned |

## Docker boundary

Docker is an optional infrastructure choice, not a kernel dependency. Installing Docker on a VM is
supported host preparation; declaring it the production packaging standard requires a deployment
ADR, an immutable image build, a non-root runtime, a migration command, health/readiness behavior,
secret delivery, backup and restore, log limits, upgrade and rollback procedures, and verification
on the documented host architectures.

Operators must not assume UFW protects published container ports. Docker documents that published
ports can bypass UFW rules. Future container manifests must keep PostgreSQL private, bind
non-edge services to loopback or an internal network, and define the required `DOCKER-USER` policy.

Membership in the host `docker` group grants root-level privileges. The application service account
must not receive that membership. A later deployment design may choose root-managed Docker,
rootless Docker, or a different packaging mechanism after the security and recovery trade-offs are
recorded.

## Production blockers

A production VM guide must not be published as available until all of these are implemented and
tested:

1. Generate and commit the OTP release configuration and a release-safe migration command.
2. Make public host, port, proxy, and clustering settings explicit runtime contracts.
3. Replace development identity headers with verified human and device authentication.
4. Choose native or OCI packaging in an accepted deployment ADR.
5. Produce one immutable artifact with an SBOM, provenance, digest, and signature policy.
6. Add least-privilege service ownership, secret delivery, TLS termination, firewall rules, and log
   rotation.
7. Add PostgreSQL backup, isolated restore verification, migration rehearsal, and roll-forward or
   rollback procedures.
8. Add systemd or container lifecycle definitions, health/readiness checks, monitoring, alerting,
   and bounded restart behavior.
9. Exercise installation and recovery on every supported Debian/Ubuntu version and architecture.

## Verification

The documentation claims were checked against `.tool-versions`, the setup scripts, development and
production configuration, repository file inventory, and the database-backed health endpoint on
2026-07-18. The source-based application tests remain the repository quality gate:

```shell
bin/mix-local quality
MIX_ENV=prod bin/mix-local compile --warnings-as-errors
```

In the reference checkout, setup completed and the umbrella suite passed 7 Core tests, 9
manufacturing tests, and 5 web tests. This verifies the repository baseline, not the Debian/Ubuntu
procedure itself.

The Debian/Ubuntu package commands are derived from primary vendor documentation. They have not yet
been executed by continuous integration on fresh VM images, so compatibility remains `partial`.

## External references

- [Phoenix introduction to deployment](https://phoenix.hexdocs.pm/deployment.html)
- [Phoenix releases and container guidance](https://phoenix.hexdocs.pm/releases.html)
- [Docker Engine on Debian](https://docs.docker.com/engine/install/debian/)
- [Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Linux post-installation security](https://docs.docker.com/engine/install/linux-postinstall/)
- [Install mise on Debian or Ubuntu](https://mise.jdx.dev/installing-mise.html)
- [PostgreSQL packages for Debian](https://www.postgresql.org/download/linux/debian/)
- [PostgreSQL packages for Ubuntu](https://www.postgresql.org/download/linux/ubuntu/)

## Update triggers

Re-verify this page whenever runtime pins, setup scripts, database configuration, production config,
release packaging, Docker artifacts, network exposure, authentication, secrets, migrations, backup,
restore, or supported operating systems change. Review external installation commands at least once
per year and before every production-readiness exercise.
