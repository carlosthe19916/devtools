# Devcontainer Binding Auto-Generation

## Problem

Functional tests in Pulp devcontainers fail with `ModuleNotFoundError: No module named 'pulpcore.client.pulp_maven'` (and similar) because OpenAPI client bindings are not generated during container setup. The `pulp-bindings` shell function exists for manual generation but is never called automatically.

The reference implementation at `pulp-docs/skills/dev-container` solves this with an automated `prepare-tests.sh` that generates all bindings before tests run. We adapt that approach to our docker-compose model.

## Constraints

- Keep docker-compose model (separate containers for DB, Redis)
- Keep manual service initialization (no always-running services)
- Use `pulpcore-manager openapi` (Django management command) instead of fetching from the live API — no need to start Pulp services for spec generation
- Generated binding code goes to `/opt/bindings/` (outside workspace)

## Design

### New file: `shared/prepare-bindings.sh`

A shared script that handles all binding generation logic.

**Usage:**
```bash
prepare-bindings.sh [component1 component2 ...] [--force]
```

**Behavior:**
1. Checks if `/opt/openapi-generator-cli.jar` exists; if not, downloads OpenAPI Generator CLI 7.19.0 and the four Pulp-specific Mustache templates to `/opt/templates/`
2. For each specified component (e.g., `core`, `maven`, `python`):
   - Skips if `/opt/bindings/<comp>-client/setup.py` exists AND `pip show pulp_<comp>-client` succeeds (unless `--force` is passed)
   - Generates OpenAPI spec: `pulpcore-manager openapi --bindings --component <comp> --file /tmp/<comp>-api.json`
   - Generates Python client: `java -jar /opt/openapi-generator-cli.jar generate -i /tmp/<comp>-api.json -g python -o /opt/bindings/<comp>-client -t /opt/templates --skip-validate-spec --strict-spec=false --additional-properties=packageName=pulpcore.client.pulp_<comp>,domainEnabled=true`
   - Copies `extend_path` `__init__.py` to `<client>/pulpcore/__init__.py` and `<client>/pulpcore/client/__init__.py`
   - Installs: `pip install /opt/bindings/<comp>-client`
   - Cleans up temp spec file
3. Components must always be specified explicitly (no auto-detection in the script itself — callers pass the right list)

**OpenAPI Generator and templates installation** (currently in postCreateCommand.sh) moves into this script with an idempotent check — if `/opt/openapi-generator-cli.jar` exists, skip download.

### Changes to pulpcore (hand-maintained)

pulpcore is no longer generated from `core/` templates. Bindings live under
`pulpcore/.devcontainer/scripts/runtime/prepare-bindings.sh`, invoked by
`ensure-bindings.sh` on post-start and by the `pulp-bindings` shell helper.

### Changes to `plugin/postCreateCommand.sh`

Auto-detect the plugin suffix and generate both `core` and plugin bindings:
```bash
plugin_suffix=$(basename /workspace | sed 's/^pulp_//')
/tmp/prepare-bindings.sh core "${plugin_suffix}"
```

Remove the OpenAPI Generator download section. Simplify `pulp-bindings` the same way.

### Changes to `generate.sh`

Add `prepare-bindings.sh` to the list of shared files copied from `shared/` to generated outputs. The script will be mounted into the container at `/tmp/prepare-bindings.sh` via docker-compose (same pattern as postCreateCommand.sh).

### Changes to docker-compose templates

Add a volume mount for the new script:
```yaml
- ${DEVTOOLS_PATH:-.devcontainer}/prepare-bindings.sh:/tmp/prepare-bindings.sh
```

### Changes to `shared/skills/pulp-dev/SKILL.md`

- Document that bindings are auto-generated during container setup for `core` and the current plugin
- Document `pulp-bindings <component> [--force]` for manual regeneration
- Note that bindings live in `/opt/bindings/`

### What stays the same

- Docker-compose model (separate DB, Redis containers)
- Manual service start via `pulp-services`
- Dockerfile, settings.py, initializeCommand.sh
- devcontainer.json features (Java 17 as devcontainer feature)
- devcontainer-lock.json files

## Component name mapping

Following the pulp-docs convention:
- `pulpcore` -> component name `core`
- `pulp_maven` -> component name `maven`
- `pulp_python` -> component name `python`
- Generic: `pulp_<suffix>` -> component name `<suffix>`

## Files modified

- `shared/prepare-bindings.sh` (new)
- `plugin/postCreateCommand.sh` (prepare-bindings call, simplify pulp-bindings function)
- `plugin/docker-compose.yml` (add volume mount for prepare-bindings.sh)
- `generate.sh` (add prepare-bindings.sh to shared files list)
- `shared/skills/pulp-dev/SKILL.md` (update documentation)
- Generated plugin devcontainers (pulp_maven, pulp_python) will be regenerated
- Hand-maintained `pulpcore/.devcontainer/` (bindings live under `scripts/runtime/prepare-bindings.sh`)

## Verification

1. Run `generate.sh maven python` to regenerate plugin devcontainers (pulpcore is hand-maintained)
2. Open one devcontainer (e.g., pulp_maven) and verify:
   - Container builds and starts successfully
   - postCreateCommand completes without errors
   - `python -c "from pulpcore.client.pulp_maven import ApiClient"` succeeds
   - `python -c "from pulpcore.client.pulpcore import ApiClient"` succeeds
   - `pulp-services` starts API, content, and worker
   - `pytest pulp_maven/tests/functional/ -v` runs (may fail for non-binding reasons, but no ImportError)
3. Test `pulp-bindings maven --force` regenerates bindings successfully
