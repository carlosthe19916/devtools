---
name: pulp-dev
description: Pulpcore development — services, reset, populate, tests, CLI, and bindings.
---

# Pulpcore Development

Config root: `devtools/devcontainer/github.com/pulp/pulpcore/.devcontainer/`  
Inside the container, scripts mount at `/opt/pulp-dev/scripts` (sourced via `shell/pulp-shell.sh`).

## Layout

| Concern | Where |
|---------|--------|
| Lifecycle entrypoints | `scripts/lifecycle/` |
| First-boot steps | `scripts/setup/NN-*.sh` |
| Runtime tools | `scripts/runtime/` |
| Interactive aliases | `scripts/shell/` |
| Sample file populate | `populate/` (`pulp-populate`) |
| Nginx / smash | `config/` |
| Pulp `PULP_*` env | `pulp-dev.env` |
| Django bootstrap | `settings.py` |
| Dev patches | `patches/` |

### First-boot (`lifecycle/post-create.sh`)

1. `10-dirs` → `20-python-deps` (editable pulpcore) → `30-patches`
2. `40-database` (redis flush, migrate, admin, collectstatic)
3. `50-smash` (API `:24817` / content `:24816`) → `60-shell` → `70-claude`

### Every start (`lifecycle/post-start.sh`)

- nginx start (optional proxy on `:80`)
- `ensure-bindings` — discovers `core` + in-tree `pulp_*` (file, certguard, …); `FORCE_BINDINGS=1` to force

## Day-1 commands

```bash
pulp-services          # api :24817 + content :24816 + worker
pulp-reset             # drop/recreate DB, migrate, reset admin password
pulp-populate          # seed file repo + upload samples (needs pulp-services)
pulp-patches apply     # overlays from /opt/pulp-dev/patches onto /workspace
pulp-check-versions    # installed pkgs vs pyproject.toml ranges
pulp-bindings core file certguard   # regenerate OpenAPI clients (in-tree plugins auto-discovered on start)
```

API admin: `admin` / `password`

Functional tests and smash use **direct** API `:24817` / content `:24816` (client-cert content guards cannot go through nginx). Nginx `:80` remains available as an optional proxy.

```bash
pulp config create --base-url http://localhost:24817 --username admin --password password --no-verify-ssl
curl -s http://localhost:24817/pulp/api/v3/status/ | jq .
```

- OpenAPI / ReDoc: see `pulp-openapi` skill
- Populate: see `pulp-populate` skill

## Optional plugins

Sibling checkouts mount under `/repositories/`:

| Helper | Path |
|--------|------|
| `pulp-maven-local` / `pulp-maven-pypi` | `/repositories/pulp_maven` |
| `pulp-python-local` / `pulp-python-pypi` | `/repositories/pulp_python` |

`pulp_file` ships with pulpcore (no separate install). After installing extra plugins, run `pulp-reset` (or migrate) and `FORCE_BINDINGS=1`, then restart `pulp-services`.

## Tests

```bash
pytest pulpcore/tests/unit/ -v
pytest pulpcore/tests/functional/ -v   # needs pulp-services
pytest pulp_certguard/tests/functional/ -v
```

## Kill services

```bash
pkill -f 'pulpcore-(api|content|worker)|concurrently.*pulpcore'
```

## DB / Redis

| | |
|---|---|
| Postgres 17 | `pulp`/`pulp` @ `$DB_HOST` (`pulpcore-db`) — `pulp-migrate`, `pulp-psql`, `pulp-reset` |
| Redis | `$REDIS_URL` |
