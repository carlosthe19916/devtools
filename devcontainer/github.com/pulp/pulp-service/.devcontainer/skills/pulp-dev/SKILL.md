---
name: pulp-dev
description: Pulp-service Cursor/VS Code devcontainer — layout, services, patches, testing, CLI
---

# Pulp Development (pulp-service)

RH/production-like Cursor environment for [pulp-service](https://github.com/pulp/pulp-service): domains, ClowdApp-style auth, nginx front door on `:80`.

Config root: `devtools/devcontainer/github.com/pulp/pulp-service/.devcontainer/`  
Inside the container, scripts mount at `/opt/pulp-dev/scripts` (sourced via `shell/pulp-shell.sh`).

## Layout (by concern)

| Concern | Where |
|---------|--------|
| Lifecycle entrypoints | `scripts/lifecycle/` (`initialize`, `post-create`, `post-start`) |
| First-boot steps (ordered) | `scripts/setup/NN-*.sh` |
| Runtime tools / process entrypoints | `scripts/runtime/` |
| Interactive aliases | `scripts/shell/` |
| Sample package populate | `populate/` (`pulp-populate` / skill `pulp-populate`) |
| Nginx / smash / certs | `config/` |
| ClowdApp `PULP_*` env | `pulp-dev.env` |
| Django bootstrap | `settings.py` |
| This skill + Claude install | `skills/` (+ `setup/70-claude.sh`) |
| Compose stack | `docker-compose.yml` (app + Postgres + Redis) |
| Image build | `Dockerfile` |

### First-boot order (`lifecycle/post-create.sh`)

1. `setup/10-dirs.sh` — permissions / dirs  
2. `setup/20-python-deps.sh` — pip + tooling  
3. `setup/30-keys-and-patches.sh` — Sigstore key + RH patches  
4. `setup/40-database.sh` — redis flush, migrate, admin password  
5. `setup/50-smash.sh` — pulp-smash → nginx `:80`  
6. `setup/60-shell.sh` — source `shell/pulp-shell.sh` from `~/.bashrc`  
7. `setup/70-claude.sh` — MCP/plugins + copy skills  

### Every start (`lifecycle/post-start.sh`)

- `runtime/start-nginx.sh`  
- `runtime/ensure-bindings.sh` (only if missing, or `FORCE_BINDINGS=1`)

## Day-1 commands

```bash
pulp-services          # api + content + worker
pulp-reset             # drop/recreate DB, migrate, reset admin password
pulp-populate          # seed domain + upload sample packages (see pulp-populate skill)
pulp-patches apply     # RH overlays from /workspace/images/assets/patches
pulp-check-versions    # pip pins vs requirements.txt
pulp-bindings core     # regenerate OpenAPI clients
```

Clients and functional tests use **nginx `:80`** (`API_PORT=80`), not raw `:24817`/`:24816`.

```bash
pulp config create --base-url http://localhost:80 --username admin --password password --no-verify-ssl
curl -s http://localhost:80/api/pulp/api/v3/status/ | jq .
```

- Admin API: `admin` / `password`  
- Postgres 16: `pulp` / `pulp` @ `$DB_HOST` (`pulp-service-db`) — `pulp-migrate`, `pulp-psql`  
- Redis: `$REDIS_URL`  
- OpenAPI / ReDoc: see `pulp-openapi` skill

## Starting services

Nginx starts on container start. Run Pulp processes:

```bash
pulp-services
# or: pulp-api | pulp-content | pulp-worker
```

## Patches

Canonical source (same as production / pulp-docs):

`pulp-service/images/assets/patches` → `/workspace/images/assets/patches`

```bash
pulp-patches apply|remove|reapply
```

`pulp-core-local` / `pulp-maven-local` / `pulp-python-local` overlay patches onto editable checkouts under `/repositories/`. `pulp-*-pypi` reinstalls from PyPI and reapplies.

## Versions / bindings

```bash
pulp-check-versions
pulp-bindings <component> [component2 ...]
```

Bindings regenerate on start only if missing; set `FORCE_BINDINGS=1` to force.

## Tests

```bash
pytest pulp_*/tests/unit/ -v
pytest pulp_*/tests/functional/ -v   # needs pulp-services + nginx
```

## Parity / ops notes

Aligned with pulp-docs all-in-one skill for: patch source, ClowdApp `PULP_*`, nginx `:80`, Postgres 16.

Attestation functional tests use the generated test key at `/etc/pki/attestation/test-key.pem`. The vendored Sigstore PEM is installed at `/etc/pki/sigstore/SIGSTORE-redhat-release3`.

If you previously used Postgres 17, delete the `pulp-service-postgres-data` volume before recreate.

## Kill services

```shell
pkill -f 'pulpcore-(api|content|worker)|concurrently.*pulpcore'
```
