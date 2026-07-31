---
name: pulp-plugin-devcontainer
description: Use when creating, editing, reviewing, or scaffolding any pulp_<plugin> .devcontainer under devcontainer/github.com/pulp/ — enforces thin trees + pulp-dev-common bind mounts (no symlinks)
---

# Pulp plugin `.devcontainer` structure

**Enforce this layout for every `pulp_<plugin>`** (e.g. `pulp_maven`, `pulp_python`, `pulp_rpm`).

## Source of truth

| What | Where |
|------|--------|
| Shared scripts | `devcontainer/github.com/pulp/pulp-dev-common/scripts/` |
| Shared knobs docs | `pulp-dev-common/README.md` |
| Thin plugin tree | `pulp_maven/.devcontainer/` (gold) / `pulp_python/.devcontainer/` |

**Edit common first** for lifecycle/setup/runtime/shell behavior. Per-project only for deltas (compose names, env, nginx, smash, populate, optional file overlays).

Do **not**:

- Symlink under `.devcontainer/` (Podman mounts the link node; `:Z` / `COPY` break)
- Fork the full `scripts/` tree into each plugin

## Thin plugin tree

```
.devcontainer/
├── devcontainer.json          # initializeCommand → pulp-dev-common/.../initialize.sh
├── docker-compose.yml         # mounts pulp-dev-common → /opt/pulp-dev/*
├── pulp-dev.env
└── patches/                   # usually empty (.gitkeep) for CI parity
```

Dockerfile, settings, config, populate, and skills come from `pulp-dev-common` (compose build context + mounts).

## Compose mounts

| Host | Container |
|------|-----------|
| `${DEVTOOLS_…}/pulp-dev-common/scripts` | `/opt/pulp-dev/scripts:ro,Z` |
| `${DEVTOOLS_…}/pulp-dev-common/config` | `/opt/pulp-dev/config:ro,Z` |
| `${DEVTOOLS_…}/pulp-dev-common/skills` | `/opt/pulp-dev/skills:ro,Z` |
| `${DEVTOOLS_…}/pulp-dev-common/populate` | `/opt/pulp-dev/populate:ro,Z` |
| `./patches` | `/opt/pulp-dev/patches` |
| plugin checkout | `/workspace` |
| pulpcore checkout | `/repositories/pulpcore` |

Build: `context: …/pulp`, `dockerfile: pulp-dev-common/Dockerfile`.

## Required env (plugins)

| Variable | Example |
|----------|---------|
| `PULP_DEV_KIND` | `plugin` |
| `PULP_PLUGIN` | `maven` / `python` / `rpm` |
| `PULP_BINDINGS` | `core maven` |
| `PULP_PATCH_TREE` | `/repositories/pulpcore` |
| `PULP_NGINX_REMOUNT` | `1` |
| `PULP_SHELL_MARKER` | `# pulp-maven devcontainer helpers` |
| `PULP_BINDINGS_DOMAIN_ENABLED` | `false` |
| `PULP_POPULATE_MODE` | `plugin` |
| `PULP_POPULATE_TYPES` | e.g. `maven` / `pypi` |
| `PULP_POPULATE_BASE_URL` | `http://localhost:80` |

## Plugin deltas (vs pulpcore)

| Concern | Required value |
|---------|----------------|
| Workspace | `${PULP_<PLUGIN>_PATH}` → `/workspace` |
| pulpcore | `${PULPCORE_PATH}` → `/repositories/pulpcore` |
| Names | `pulp-<plugin>`, `pulp-<plugin>-db`, `pulp-<plugin>-redis` |
| `20-python-deps` | editable pulpcore, then `pip install -e .`, then `pulp-cli-<plugin>` (overlay if ≠ common) |
| Patches | apply to `/repositories/pulpcore` |
| Bindings | `PULP_BINDINGS=core <plugin>` |
| Front door | `API_PORT=80`; smash/CLI/populate via nginx `:80` |
| Day-1 helpers | `pulp-services`, `pulp-reset`, `pulp-populate`, `pulp-bindings`, `pulp-check-versions` |

## New plugin (`pulp_rpm`)

1. Copy thin `.devcontainer/` from `pulp_maven`
2. Rename compose/service/network/volumes/`PULP_*` paths
3. Set `PULP_PLUGIN=rpm`, `PULP_BINDINGS=core rpm`, shell marker
4. Replace `populate/` with rpm assets + `setup_pulp.py`
5. Shared scripts come from `pulp-dev-common` automatically

## Forbidden

- Flat `.devcontainer/postCreateCommand.sh` mounted at `/tmp`
- Full duplicated `scripts/{lifecycle,setup,runtime,shell}` trees
- Symlinks into `pulp-dev-common`
- Smash/CLI only on `:24817`/`:24816` (processes may bind those; **clients use `:80`**)
- File-mount overlays onto a path that does **not** exist under the `pulp-dev-common` bind (Podman creates empty `nobody`-owned host stubs). Overlay an existing name, or commit a placeholder mount point.

## Checklist before finishing

- [ ] Scripts/config/skills/populate come from `pulp-dev-common` (compose mounts)
- [ ] Build uses `pulp-dev-common/Dockerfile` (parent context)
- [ ] No symlinks under `.devcontainer/`
- [ ] Env knobs set (`PULP_DEV_KIND`, `PULP_PLUGIN`, `PULP_BINDINGS`, `PULP_POPULATE_TYPES`, …)
- [ ] Smash via common config (api+content `:80` / nginx) unless intentionally overlaid
- [ ] Overlays only where behavior truly diverges

## Related

- Debug failures: `.claude/skills/pulp-container-debug`
- Common docs: `devcontainer/github.com/pulp/pulp-dev-common/README.md`
- Parent docs: `devcontainer/github.com/pulp/README.md`
