---
title: Prepare a fresh Debian or Ubuntu VM for Actualis
doc_type: user_task
audience: administrator
kernel_area: deployment
status: partial
roles:
  - system_administrator
paired_technical_docs:
  - docs/technical/deployment/README.md
screenshots:
  - none
last_verified: 2026-07-18
---

# Prepare a fresh Debian or Ubuntu VM for Actualis

## What this lets you do

This procedure prepares a minimal Debian or Ubuntu virtual machine and runs the current Actualis
kernel for evaluation. The service stays on the VM's loopback interface and is reached through an
SSH tunnel.

**Warning:** this is not a production installation. Actualis does not yet provide an OTP release,
Docker image, Compose manifest, TLS proxy, production authentication, backup automation, or tested
rollback procedure. Do not expose the current API to an untrusted network or use it for operational
data.

## Before you start

- Use a 64-bit Debian 13 or 12 host, or Ubuntu 26.04 LTS or 24.04 LTS host. These are documented
  targets, not a continuous-integration compatibility matrix.
- Keep provider-console access until SSH and firewall changes are verified in a second session.
- Use an administrator account with `sudo`; do not work as `root` over SSH.
- Keep ports `4000` and `5432` private. The current guide requires only the configured SSH port.
- Plan to discard the evaluation databases. They are seeded with fictional demonstration data.

External installation sources were reviewed on 2026-07-18. Re-check them before using this guide
with newer operating-system releases.

## 1. Verify and update the host

Confirm the operating system and architecture:

```shell
cat /etc/os-release
dpkg --print-architecture
```

Install security updates and the packages used by this procedure:

```shell
sudo apt-get update
sudo apt-get -y full-upgrade
sudo apt-get install -y \
  autoconf \
  build-essential \
  ca-certificates \
  curl \
  extrepo \
  git \
  gnupg \
  jq \
  libncurses-dev \
  libssl-dev \
  libxml2-dev \
  libxslt1-dev \
  m4 \
  openssl \
  ufw \
  unattended-upgrades \
  unixodbc-dev
```

If `/var/run/reboot-required` exists, reboot before continuing and reconnect:

```shell
test ! -f /var/run/reboot-required || cat /var/run/reboot-required
```

## 2. Protect SSH before enabling the firewall

Verify that key-based SSH access works in a second terminal. If the VM uses the standard OpenSSH
profile, apply the baseline firewall rules:

```shell
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit OpenSSH
sudo ufw enable
sudo ufw status verbose
```

**Warning:** if SSH uses a custom port, allow that exact port before enabling UFW. Do not open
PostgreSQL port `5432` or Phoenix port `4000` to the internet.

## 3. Optionally install Docker Engine and Compose

Docker is optional for this evaluation and does not install Actualis. This step prepares the host
for future container artifacts and installs Docker from Docker's official Apt repository. Skip it
if the VM is not intended to run containers.

Identify the supported distribution and add Docker's signing key and repository:

```shell
. /etc/os-release
case "$ID" in
  debian|ubuntu) ;;
  *) printf 'Unsupported distribution: %s\n' "$ID" >&2; exit 1 ;;
esac

DOCKER_CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
DOCKER_ARCH="$(dpkg --print-architecture)"

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL "https://download.docker.com/linux/${ID}/gpg" \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

printf '%s\n' \
  'Types: deb' \
  "URIs: https://download.docker.com/linux/${ID}" \
  "Suites: ${DOCKER_CODENAME}" \
  'Components: stable' \
  "Architectures: ${DOCKER_ARCH}" \
  'Signed-By: /etc/apt/keyrings/docker.asc' \
  | sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null
```

Install and verify Docker Engine, Buildx, and the Compose plugin:

```shell
sudo apt-get update
sudo apt-get install -y \
  containerd.io \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin
sudo systemctl enable --now docker
sudo docker version
sudo docker compose version
sudo docker run --rm hello-world
```

Do not add the `actualis` service account or an untrusted operator to the `docker` group. Membership
in that group grants root-level control of the host. Use `sudo docker` until a separate rootless or
privileged-operator policy is approved.

Docker-published ports can bypass UFW rules. A future Actualis container definition must bind
internal services to loopback or a private network and enforce filtering in the `DOCKER-USER`
chain. Never publish PostgreSQL with an unrestricted mapping such as `5432:5432`.

## 4. Install the pinned language tools

Install `mise` from its Apt repository:

```shell
sudo extrepo enable mise
sudo apt-get update
sudo apt-get install -y mise
mise --version
```

Clone Actualis and record the exact revision being evaluated:

```shell
git clone https://github.com/fderyckel/actualis.git
cd actualis
git rev-parse HEAD
```

Install the Erlang, Elixir, and Node.js versions from `.tool-versions`. The options omit Erlang GUI
and Java components that the headless kernel does not use:

```shell
export KERL_CONFIGURE_OPTIONS='--without-javac --without-wx'
mise install erlang elixir nodejs
mise exec -- elixir --version
mise exec -- node --version
```

Use `mise exec -- COMMAND` for the remaining steps. This avoids depending on shell-startup files.

## 5. Install PostgreSQL 18

Use the PostgreSQL Global Development Group (PGDG) Apt repository so Debian and Ubuntu receive the
project's pinned major version through normal package updates:

```shell
sudo apt-get install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt-get update
sudo apt-get install -y postgresql-18
sudo systemctl enable --now postgresql
sudo systemctl status postgresql --no-pager
```

Generate a URL-safe evaluation password, then use the printed value when `createuser` prompts twice:

```shell
openssl rand -hex 24
sudo -u postgres createuser \
  --pwprompt \
  --no-superuser \
  --no-createdb \
  --no-createrole \
  actualis
sudo -u postgres createdb --owner=actualis actualis_dev
sudo -u postgres createdb --owner=actualis actualis_test
```

Load the same password into the current shell without placing it in shell history:

```shell
read -rsp 'Actualis database password: ' ACTUALIS_DB_PASSWORD
printf '\n'
export ACTUALIS_DATABASE_URL="ecto://actualis:${ACTUALIS_DB_PASSWORD}@127.0.0.1:5432/actualis_dev"
export ACTUALIS_TEST_DATABASE_URL="ecto://actualis:${ACTUALIS_DB_PASSWORD}@127.0.0.1:5432/actualis_test"
unset ACTUALIS_DB_PASSWORD
```

These exports last only for the current shell. Do not place production credentials in the
repository or in a world-readable profile. Actualis does not yet provide its production secret
delivery mechanism.

## 6. Initialize and verify Actualis

Install Hex dependencies, create the schema, run migrations and seed the fictional fixture:

```shell
mise exec -- bin/mix-local local.hex --force
mise exec -- bin/mix-local deps.get
mise exec -- bin/mix-local ecto.setup
```

Run the repository quality gate before starting the service:

```shell
mise exec -- bin/mix-local quality
```

All formatting, compilation, and test checks must pass. Start the development endpoint:

```shell
mise exec -- bin/mix-local phx.server
```

Leave that process running. The endpoint listens on `127.0.0.1:4000`; this is intentional.

## 7. Confirm the result through an SSH tunnel

From your workstation, replace `ADMIN` and `VM_ADDRESS` and open the tunnel:

```shell
ssh -L 4000:127.0.0.1:4000 ADMIN@VM_ADDRESS
```

In another workstation terminal, check database-backed health:

```shell
curl --fail --show-error http://127.0.0.1:4000/api/health
```

Expected response:

```json
{"status":"ok"}
```

You can now use the README's fictional demonstration request through the same tunnel.

## If it does not work

| What you see | Likely reason | What to do |
| --- | --- | --- |
| SSH disconnects after `ufw enable` | The VM uses a non-standard SSH port | Use provider-console access, allow the actual SSH port, then verify a second session before disconnecting the console. |
| `mise install erlang` fails | A compiler or native library is missing, or no prebuilt Erlang package matches the OS | Read the complete error, install the named build prerequisite, and rerun the same command. Do not substitute a different Erlang version. |
| PostgreSQL authentication fails | The password in the database URLs differs from the role password | Re-enter the role password with `sudo -u postgres psql -c '\password actualis'`, then recreate the two exports. |
| `ecto.setup` reports that a database already exists | A previous setup attempt created it | Run `mise exec -- bin/mix-local ecto.migrate` and do not drop a database until you have confirmed it contains only disposable evaluation data. |
| Health returns `{"status":"degraded"}` | Phoenix cannot query PostgreSQL | Check `sudo systemctl status postgresql`, the two database URLs, and the server terminal. |
| The workstation cannot reach port `4000` | The SSH tunnel is absent or points to the wrong VM | Keep Phoenix bound to loopback and recreate the tunnel; do not solve this by opening port `4000` publicly. |
| `docker compose` reports no configuration file | Actualis has no Compose manifest yet | Use the source-based evaluation procedure. Docker Engine alone is not an Actualis deployment. |

## What Actualis records

The setup seeds fictional principals, sites, locations, policies, grants, and a pallet. Evaluation
commands can create command receipts, evidence, movements, outbox rows, and projection deltas in
`actualis_dev`. Delete the VM or securely remove the disposable databases when the evaluation ends.

## Related tasks and concepts

- [Fresh-VM deployment status](../../technical/deployment/README.md)
- [Actualis core-kernel user guide](../core-kernel/README.md)
- [Docker Engine on Debian](https://docs.docker.com/engine/install/debian/)
- [Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Linux post-installation security](https://docs.docker.com/engine/install/linux-postinstall/)
- [Install mise on Debian or Ubuntu](https://mise.jdx.dev/installing-mise.html)
- [PostgreSQL packages for Debian](https://www.postgresql.org/download/linux/debian/)
- [PostgreSQL packages for Ubuntu](https://www.postgresql.org/download/linux/ubuntu/)
