# Actualis: first VM setup

This file is the root-level entry point for preparing a fresh minimal Debian or Ubuntu VM.

The complete, maintained procedure is:

**[`docs/user/installation/fresh-vm.md`](docs/user/installation/fresh-vm.md)**

The corresponding implementation status and production gaps are documented in:

**[`docs/technical/deployment/README.md`](docs/technical/deployment/README.md)**

## Current scope

The present procedure creates a **source-based evaluation VM**, not a production installation.
Actualis currently runs as an Elixir/Phoenix modular monolith backed by PostgreSQL 18.

The repository does not yet provide a production OTP release, Actualis Docker image, Compose
manifest, TLS proxy, production authentication, automated backup/restore, or tested rollback.
Do not expose the current API or database to an untrusted network and do not use operational data.

## VM preparation sequence

1. Provision a supported 64-bit minimal host:
   - Debian 13 or 12; or
   - Ubuntu 26.04 LTS or 24.04 LTS.
2. Retain provider-console access and configure key-based SSH for a non-root administrator.
3. Update the OS and install the build, security, firewall, and unattended-upgrade packages listed
   in the canonical guide.
4. Configure UFW to allow only the real SSH port. Keep Phoenix `4000` and PostgreSQL `5432`
   private.
5. Clone this repository and record the exact commit being evaluated.
6. Install the versions pinned in `.tool-versions` using `mise`:
   - Erlang/OTP 29.0.3;
   - Elixir 1.20.2;
   - Node.js 24.15.0.
7. Install PostgreSQL 18 from the PostgreSQL Global Development Group repository.
8. Create disposable `actualis_dev` and `actualis_test` databases and configure
   `ACTUALIS_DATABASE_URL` and `ACTUALIS_TEST_DATABASE_URL` for the current session.
9. Initialize and verify the application:

   ```shell
   mise exec -- bin/mix-local local.hex --force
   mise exec -- bin/mix-local deps.get
   mise exec -- bin/mix-local ecto.setup
   mise exec -- bin/mix-local quality
   ```

10. Start Phoenix on the loopback interface:

    ```shell
    mise exec -- bin/mix-local phx.server
    ```

11. Reach it from the administrator workstation through an SSH tunnel:

    ```shell
    ssh -L 4000:127.0.0.1:4000 ADMIN@VM_ADDRESS
    curl --fail --show-error http://127.0.0.1:4000/api/health
    ```

    The expected response is `{"status":"ok"}`.

## Docker boundary

Docker Engine and the Compose plugin are optional host preparation only. Docker does not currently
install Actualis because the repository has no application image or Compose manifest.

Do not add the Actualis service account to the `docker` group; membership grants root-level host
control. Do not assume UFW protects Docker-published ports, and never publish PostgreSQL publicly.

## Before production

Production use requires, at minimum, accepted release packaging, verified human and device
authentication, immutable artifacts, TLS, least-privilege service ownership, secret delivery,
backup and isolated restore verification, safe migrations, monitoring, alerting, and a rehearsed
upgrade/rollback procedure. The authoritative blocker list is maintained in
[`docs/technical/deployment/README.md`](docs/technical/deployment/README.md).
