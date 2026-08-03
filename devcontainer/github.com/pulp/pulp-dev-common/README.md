# pulp-dev-common

Shared scripts, config, populate, skills, Dockerfile, and settings for Pulp `.devcontainer` trees
(`pulpcore`, `pulp_<plugin>`, `pulp-service`).

## Layout

```
pulp-dev-common/
├── scripts/          # lifecycle / setup / runtime / shell → /opt/pulp-dev/scripts
├── config/           # nginx.conf (upstream), smash.json (nginx :80), proxy-params
├── populate/         # setup_pulp.py (linear) + assets/{file,maven,pypi,npm,rpm}
├── skills/           # pulp-dev, pulp-openapi, pulp-populate
├── Dockerfile        # scaffolding template for per-project .devcontainer/Dockerfile
├── settings.py       # thin Django bootstrap (knobs via pulp-dev.env)
└── README.md
```

## Compose mounts (typical)

```yaml
volumes:
  - ${DEVTOOLS_PATH:-~/git/devtools}/devcontainer/github.com/pulp/pulp-dev-common/scripts:/opt/pulp-dev/scripts:ro,Z
  - ${DEVTOOLS_…}/pulp-dev-common/config:/opt/pulp-dev/config:ro,Z
  - ${DEVTOOLS_…}/pulp-dev-common/skills:/opt/pulp-dev/skills:ro,Z
  - ${DEVTOOLS_…}/pulp-dev-common/populate:/opt/pulp-dev/populate:ro,Z
```

Overlays (examples):

- pulpcore: `./config/smash.json` (API `:24817`), `./scripts/setup/20-python-deps.sh`, `./skills/pulp-profile`
- pulp-service: `./config/nginx.conf` (ClowdApp), RH script overlays, `./skills/pulp-profile`

Build (each project’s `.devcontainer/docker-compose.yml`):

```yaml
build:
  dockerfile: ./Dockerfile
```

This directory’s `Dockerfile` is a scaffolding template (copy into a new plugin’s `.devcontainer/` and adjust `COPY` paths for a local context). Compose builds the per-project `./Dockerfile`.

## Env knobs

| Variable | Values / meaning |
|----------|------------------|
| `PULP_DEV_KIND` | `plugin` \| `core` \| `service` |
| `PULP_PLUGIN` | e.g. `maven`, `python` (plugins) |
| `PULP_BINDINGS` | space-separated OpenAPI components; if unset and `kind=core`, discover |
| `PULP_PATCH_TREE` | default tree for `patches.sh` / `30-patches.sh` |
| `PULP_PATCH_DIR` | directory of `.patch` files |
| `PULP_SETUP_30` | setup step 30 script name |
| `PULP_NGINX_REMOUNT` | `1` copy mounted nginx config then start; `0` start only |
| `PULP_SHELL_MARKER` | bashrc marker line for helpers |
| `PULP_PYPROJECT` | path for `pulp-check-versions` |
| `PULP_BINDINGS_DOMAIN_ENABLED` | `true`/`false` for OpenAPI generator |
| `PULP_POPULATE_MODE` | `plugin` \| `service` |
| `PULP_POPULATE_TYPES` | comma list: `file`, `pypi`, `maven`, `npm`, `rpm` |
| `PULP_POPULATE_BASE_URL` | populate API base URL |
| `PULP_POPULATE_DOMAIN` | domain name when `MODE=service` |

## Edit here first

Prefer changing shared behavior under this directory. Only add a per-project overlay when RH/core/plugin logic truly diverges. **No symlinks** under `.devcontainer/`.

## Host paths Podman must resolve

Compose bind mounts require the **host path to exist** before `up` (including `--no-recreate` of an older container). Do not delete per-project `config/` (plugins keep a copy identical to `pulp-dev-common/config/`). After changing volume sources, use **Rebuild Container** (recreate), not a plain reopen — stale containers still reference old mount sources.

**File/dir overlays under a common bind:** the mount *target* path must already exist on the host under `pulp-dev-common/`. If it does not, Podman creates an empty `nobody`-owned stub there on every start (e.g. a bogus `scripts/setup/30-keys-and-patches.sh`). Overlay onto an existing name (pulp-service mounts RH `30-keys-and-patches.sh` → common `30-patches.sh`) or commit a placeholder directory (see `skills/pulp-profile/`).
