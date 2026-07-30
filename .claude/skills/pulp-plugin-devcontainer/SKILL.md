---
name: pulp-plugin-devcontainer
description: Use when creating, editing, reviewing, regenerating, or scaffolding any pulp_<plugin> .devcontainer under devcontainer/github.com/pulp/ — enforces the modular /opt/pulp-dev layout shared by pulp_maven and pulp_python
---

# Pulp plugin `.devcontainer` structure

**Enforce this layout for every `pulp_<plugin>`** (e.g. `pulp_maven`, `pulp_python`, `pulp_rpm`). Do **not** invent a flat `/tmp/postCreateCommand.sh` layout.

Hand-maintained references (gold standard):

- `devcontainer/github.com/pulp/pulp_maven/.devcontainer/`
- `devcontainer/github.com/pulp/pulp_python/.devcontainer/`

For a new plugin, **copy** `pulp_maven/.devcontainer/` (or `pulp_python`) and adapt names/populate — do **not** edit or regenerate from `pulp_plugin_template/`.

## Required tree

```
.devcontainer/
├── Dockerfile
├── devcontainer.json
├── docker-compose.yml
├── settings.py              # thin bootstrap
├── pulp-dev.env             # PULP_* knobs; nginx :80 front door
├── config/
│   ├── nginx.conf
│   ├── nginx-proxy-params.conf
│   └── smash.json           # api + content on port 80 / nginx
├── patches/                 # applied to /repositories/pulpcore
├── populate/
│   ├── setup_pulp.py
│   └── assets/<plugin>/
├── skills/
│   ├── pulp-dev/SKILL.md
│   ├── pulp-openapi/SKILL.md
│   └── pulp-populate/SKILL.md
└── scripts/
    ├── lifecycle/           # initialize, post-create, post-start
    ├── setup/               # 10-dirs … 70-claude
    ├── runtime/             # nginx, bindings, reset, populate, run-api/content
    └── shell/               # pulp-shell + db/services/tools/packages
```

Compose mounts (not `/tmp`):

| Host | Container |
|------|-----------|
| `./scripts` | `/opt/pulp-dev/scripts` |
| `./config` | `/opt/pulp-dev/config` |
| `./skills` | `/opt/pulp-dev/skills` |
| `./patches` | `/opt/pulp-dev/patches` |
| `./populate` | `/opt/pulp-dev/populate` |
| plugin checkout | `/workspace` |
| pulpcore checkout | `/repositories/pulpcore` |

## Plugin deltas (vs pulpcore)

| Concern | Required value |
|---------|----------------|
| Workspace | `${PULP_<PLUGIN>_PATH}` → `/workspace` |
| pulpcore | `${PULPCORE_PATH}` → `/repositories/pulpcore` |
| Names | `pulp-<plugin>`, `pulp-<plugin>-db`, `pulp-<plugin>-redis` |
| `20-python-deps` | editable pulpcore, then `pip install -e .`, then `pulp-cli-<plugin>` |
| Patches | apply to `/repositories/pulpcore` |
| Bindings | always `core` + `<plugin>` |
| Front door | `API_PORT=80`; smash/CLI/populate via nginx `:80` |
| `packages.sh` | `pulp-core-local` / `pulp-core-pypi` |
| Day-1 helpers | `pulp-services`, `pulp-reset`, `pulp-populate`, `pulp-bindings`, `pulp-check-versions` |

## Forbidden

- Flat `.devcontainer/postCreateCommand.sh` mounted at `/tmp`
- Smash/CLI only on `:24817`/`:24816` (processes may bind those; **clients use `:80`**)
- Missing `scripts/{lifecycle,setup,runtime,shell}`
- Workspace = pulpcore for a plugin container
- Editing `pulp_plugin_template/` to “fix” tracked modular containers

## Checklist before finishing

- [ ] Tree matches required layout
- [ ] Compose uses `/opt/pulp-dev/*` mounts + pulpcore mount
- [ ] `smash.json` api+content port `80` / service `nginx`
- [ ] `ensure-bindings.sh` generates `core` + plugin
- [ ] `populate/` has type-specific `setup_pulp.py` + assets
- [ ] In-container skills document day-1 commands
- [ ] New plugins: copied from `pulp_maven` / `pulp_python`, then customized and tracked

## Related

- Debug failures: `.claude/skills/pulp-container-debug`
- Parent docs: `devcontainer/github.com/pulp/README.md`
