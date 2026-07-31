---
name: pulp-dev
description: Pulp .devcontainer day-1 — services, reset, populate, tests, CLI, bindings (shared).
---

# Pulp Development

Scripts mount from `pulp-dev-common` → `/opt/pulp-dev/scripts` (sourced via `shell/pulp-shell.sh`).  
Config / skills / populate also come from `pulp-dev-common` unless a project overlays them.

Kind is selected by compose env: `PULP_DEV_KIND` = `plugin` | `core` | `service`.

## Layout

| Concern | Where |
|---------|--------|
| Shared scripts | `pulp-dev-common/scripts` → `/opt/pulp-dev/scripts` |
| Shared config | `pulp-dev-common/config` → `/opt/pulp-dev/config` (+ overlays) |
| Shared populate | `pulp-dev-common/populate` → `/opt/pulp-dev/populate` |
| Shared skills | `pulp-dev-common/skills` → `/opt/pulp-dev/skills` (+ overlays) |
| Pulp `PULP_*` env | per-project `pulp-dev.env` |
| Django bootstrap | `pulp-dev-common/settings.py` (image) |

### First-boot (`lifecycle/post-create.sh`)

1. `10-dirs` → `20-python-deps` → step 30 (`30-patches.sh`; pulp-service mounts its `30-keys-and-patches.sh` over that path)
2. `40-database` → `50-smash` → `60-shell` → `70-claude`

### Every start (`lifecycle/post-start.sh`)

- nginx (remount config when `PULP_NGINX_REMOUNT=1`)
- `ensure-bindings` (from `PULP_BINDINGS` or discover when `PULP_DEV_KIND=core`)

## Day-1 commands

```bash
pulp-services          # api :24817 + content :24816 + worker
pulp-reset             # drop/recreate DB, migrate, reset admin password
pulp-populate          # seed sample packages (see pulp-populate)
pulp-patches apply     # overlays from $PULP_PATCH_DIR onto $PULP_PATCH_TREE
pulp-check-versions    # installed pkgs vs pulpcore pyproject
pulp-bindings <comp>…  # regenerate OpenAPI clients
```

API admin: `admin` / `password`

## Front door (by kind)

| Kind | Clients | Notes |
|------|---------|-------|
| `plugin` | nginx `:80` (`API_PORT=80`) | workspace = plugin; pulpcore at `/repositories/pulpcore` |
| `core` | API smash/CLI `:24817`; content nginx `:80` | certguard; patches onto `/workspace` |
| `service` | nginx `:80`; status under `/api/pulp/` | domains, RH patches under `/workspace/images/assets/patches` |

```bash
# plugin / service (nginx front door)
pulp config create --base-url http://localhost:80 --username admin --password password --no-verify-ssl

# pulpcore (direct API for certguard)
pulp config create --base-url http://localhost:24817 --username admin --password password --no-verify-ssl
```

- OpenAPI / ReDoc: see `pulp-openapi`
- Populate: see `pulp-populate`
- Project-specific notes: local overlay under `.devcontainer/skills/pulp-dev/` when present

## Kill services

```bash
pkill -f 'pulpcore-(api|content|worker)|concurrently.*pulpcore'
```
