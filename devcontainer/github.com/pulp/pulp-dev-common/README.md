# pulp-dev-common

Shared scripts, config, populate, skills, Dockerfile, and settings for Pulp `.devcontainer` trees
(`pulpcore`, `pulp_<plugin>`, `pulp-service`).

## Layout

```
pulp-dev-common/
├── scripts/          # lifecycle / setup / runtime / shell → /opt/pulp-dev/scripts
├── config/           # nginx.conf (upstream), smash.json (nginx :80), proxy-params
├── populate/         # setup_pulp.py (linear) + assets/{file,maven,pypi,npm,rpm}
├── skills/           # pulp-dev, pulp-openapi, pulp-populate, pulp-profile/ (placeholder)
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

### Overlay map by group

| Group | File overlays (mounted over common) |
|-------|-------------------------------------|
| **pulpcore** | `./config/smash.json` (API `:24817`), `./scripts/setup/20-python-deps.sh`, `./skills/pulp-profile` |
| **plugins** | none (pure common mounts) |
| **pulp-service** | `./config/nginx.conf` (ClowdApp), `./scripts/setup/20-python-deps.sh`, `./scripts/setup/30-keys-and-patches.sh` → `…/30-patches.sh`, certs, OTEL/Prometheus/Grafana, `./skills/pulp-profile` |

Build (each project’s `.devcontainer/docker-compose.yml`):

```yaml
build:
  dockerfile: ./Dockerfile
```

This directory’s `Dockerfile` is a scaffolding template (copy into a new plugin’s `.devcontainer/` and adjust `COPY` paths for a local context). Compose builds the per-project `./Dockerfile`.

## Env knobs

| Variable | Values / meaning |
|----------|------------------|
| `DEVCONTAINER_DEV_KIND` | `plugin` \| `core` \| `service` |
| `DEVCONTAINER_PLUGIN` | e.g. `maven`, `python` (plugins) |
| `DEVCONTAINER_BINDINGS` | space-separated OpenAPI components; if unset and `kind=core`, discover |
| `DEVCONTAINER_PATCH_TREE` | default tree for `patches.sh` / `30-patches.sh` |
| `DEVCONTAINER_PATCH_DIR` | directory of `.patch` files |
| `DEVCONTAINER_PATCH_STRICT` | `1` fail-hard on apply errors / missing dir; default `1` when `kind=service` |
| `DEVCONTAINER_SETUP_30` | setup step 30 script name (default `30-patches.sh`) |
| `DEVCONTAINER_NGINX_REMOUNT` | `1` copy mounted nginx config then start; `0` start only |
| `DEVCONTAINER_SHELL_MARKER` | bashrc marker line for helpers |
| `DEVCONTAINER_PYPROJECT` | path for `pulp-check-versions` (core/plugin) |
| `DEVCONTAINER_REQUIREMENTS` | path for `pulp-check-versions` pinned file (service) |
| `DEVCONTAINER_BINDINGS_DOMAIN_ENABLED` | `true`/`false` for OpenAPI generator |
| `DEVCONTAINER_POPULATE_MODE` | `plugin` \| `service` |
| `DEVCONTAINER_POPULATE_TYPES` | comma list: `file`, `pypi`, `maven`, `npm`, `rpm` |
| `DEVCONTAINER_POPULATE_BASE_URL` | populate API base URL |
| `DEVCONTAINER_POPULATE_DOMAIN` | domain name when `MODE=service` |

### Group matrix (typical compose values)

| Knob | core | plugin | service |
|------|------|--------|---------|
| `DEVCONTAINER_DEV_KIND` | `core` | `plugin` | `service` |
| Client front door | smash/CLI `:24817` | nginx `:80` | nginx `:80` (`/api/pulp/`) |
| `DEVCONTAINER_BINDINGS_DOMAIN_ENABLED` | `false` | `false` | `true` |
| `DEVCONTAINER_POPULATE_MODE` | `plugin` | `plugin` | `service` |
| Patch tree default | `/workspace` (via env) | `/repositories/pulpcore` | site-packages |
| Postgres | 17 | 17 | 16 (RH) |

## Edit here first

Prefer changing shared behavior under this directory. Only add a per-project overlay when RH/core/plugin logic truly diverges. **No symlinks** under `.devcontainer/`.

## Host paths Podman must resolve

Compose bind mounts require the **host path to exist** before `up` (including `--no-recreate` of an older container). After changing volume sources, use **Rebuild Container** (recreate), not a plain reopen — stale containers still reference old mount sources.

**File/dir overlays under a common bind:** the mount *target* path must already exist on the host under `pulp-dev-common/`. If it does not, Podman creates an empty `nobody`-owned stub there on every start (e.g. a bogus `scripts/setup/30-keys-and-patches.sh`). Overlay onto an existing name (pulp-service mounts RH `30-keys-and-patches.sh` → common `30-patches.sh`) or commit a placeholder directory (see `skills/pulp-profile/`).
