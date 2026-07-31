# Devcontainer Binding Auto-Generation

> **Historical note:** `pulp_plugin_template/` / `generate.sh` were removed.
> Bindings live under `pulp-dev-common/scripts/runtime/` (`prepare-bindings.sh`,
> `ensure-bindings.sh`) and are mounted into each thin `.devcontainer`.

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

### Shared scripts (`pulp-dev-common`)

`prepare-bindings.sh` / `ensure-bindings.sh` live under
`pulp-dev-common/scripts/runtime/` and are bind-mounted to `/opt/pulp-dev/scripts`.

### Changes to in-container skills

- Document that bindings are auto-generated during container setup for `core` and the current plugin
- Document `pulp-bindings <component> [--force]` for manual regeneration
- Note that bindings live in `/opt/bindings/`

### What stays the same

- Docker-compose model (separate DB, Redis containers)
- Manual service start via `pulp-services`
- Dockerfile, settings.py, initializeCommand (from common)
- devcontainer.json features (Java 17 as devcontainer feature)
- devcontainer-lock.json files

## Component name mapping

Following the pulp-docs convention:
- `pulpcore` -> component name `core`
- `pulp_maven` -> component name `maven`
- `pulp_python` -> component name `python`
- Generic: `pulp_<suffix>` -> component name `<suffix>`

## Files modified

- `pulp-dev-common/scripts/runtime/prepare-bindings.sh`
- `pulp-dev-common/scripts/runtime/ensure-bindings.sh`
- Thin `.devcontainer/` trees (compose mounts common scripts; env sets `PULP_BINDINGS`)
- In-container `skills/pulp-dev/SKILL.md`

## Verification

1. Recreate a thin plugin container (e.g. pulp_maven) with `pulp-dev-common` mounted
2. Open the devcontainer and verify:
   - Container builds and starts successfully
   - postCreateCommand completes without errors
   - `python -c "from pulpcore.client.pulp_maven import ApiClient"` succeeds
   - `python -c "from pulpcore.client.pulpcore import ApiClient"` succeeds
   - `pulp-services` starts API, content, and worker
   - `pytest pulp_maven/tests/functional/ -v` runs (may fail for non-binding reasons, but no ImportError)
3. Test `pulp-bindings maven --force` regenerates bindings successfully
