---
name: pulp-dev
description: pulp_maven development — services, reset, populate, tests, CLI, and bindings.
---

# pulp_maven Development

Config root: `devtools/devcontainer/github.com/pulp/pulp_maven/.devcontainer/`  
Inside the container, scripts mount at `/opt/pulp-dev/scripts` (sourced via `shell/pulp-shell.sh`).  
Workspace is the plugin (`/workspace`); pulpcore is at `/repositories/pulpcore`.

## Layout

| Concern | Where |
|---------|--------|
| Lifecycle entrypoints | `scripts/lifecycle/` |
| First-boot steps | `scripts/setup/NN-*.sh` |
| Runtime tools | `scripts/runtime/` |
| Interactive aliases | `scripts/shell/` |
| Sample maven populate | `populate/` (`pulp-populate`) |
| Nginx / smash | `config/` |
| Pulp `PULP_*` env | `pulp-dev.env` |
| Django bootstrap | `settings.py` |
| Dev patches (→ pulpcore) | `patches/` |

### First-boot (`lifecycle/post-create.sh`)

1. `10-dirs` → `20-python-deps` (editable pulpcore + `pip install -e .` + pulp-cli-maven) → `30-patches`
2. `40-database` (redis flush, migrate, admin, collectstatic)
3. `50-smash` (API + content via nginx `:80`) → `60-shell` → `70-claude`

### Every start (`lifecycle/post-start.sh`)

- nginx start (front door on `:80`)
- `ensure-bindings` — `core` + `maven`; `FORCE_BINDINGS=1` to force

## Day-1 commands

```bash
pulp-services          # api :24817 + content :24816 + worker (behind nginx :80)
pulp-reset             # drop/recreate DB, migrate, reset admin password
pulp-populate          # seed maven repo + upload sample jars/poms (needs pulp-services)
pulp-patches apply     # overlays from /opt/pulp-dev/patches onto /repositories/pulpcore
pulp-check-versions    # installed pkgs vs /repositories/pulpcore/pyproject.toml
pulp-bindings core maven
pulp-core-local        # editable pulpcore from /repositories/pulpcore (+ patches)
pulp-core-pypi         # PyPI pulpcore, then reapply patches
```

API admin: `admin` / `password`

Clients, smash, and functional tests use **nginx `:80`** (`API_PORT=80`). Processes still bind localhost `:24817` / `:24816`.

```bash
pulp config create --base-url http://localhost:80 --username admin --password password --no-verify-ssl
curl -s http://localhost:80/pulp/api/v3/status/ | jq .
```

- OpenAPI / ReDoc: see `pulp-openapi` skill
- Populate: see `pulp-populate` skill

## Packages / patches

| Helper | Effect |
|--------|--------|
| `pulp-core-local` | `pip install -e /repositories/pulpcore` + apply patches |
| `pulp-core-pypi` | `pip install pulpcore` + `pulp-patches reapply` |
| `pulp-patches apply\|remove\|reapply` | overlay on `/repositories/pulpcore` |

After switching pulpcore, restart `pulp-services` (and `FORCE_BINDINGS=1` if API shape changed).

## Tests

```bash
pytest pulp_maven/tests/unit/ -v
pytest pulp_maven/tests/functional/ -v   # needs pulp-services + nginx
```

## Kill services

```bash
pkill -f 'pulpcore-(api|content|worker)|concurrently.*pulpcore'
```

## DB / Redis

| | |
|---|---|
| Postgres 17 | `pulp`/`pulp` @ `$DB_HOST` (`pulp-maven-db`) — `pulp-migrate`, `pulp-psql`, `pulp-reset` |
| Redis | `$REDIS_URL` |
