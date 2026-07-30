---
name: pulp-container-debug
description: Use when any Pulp component (pulp-service, pulpcore, pulp_maven, pulp_python, or other plugins) running in a devcontainer needs to be examined, debugged, or tested — covers environment configuration, test failures, and container inspection
---

# Pulp Container Debug

## Overview

Debug test failures in Pulp devcontainers where the source code is correct (verified by CI) but tests fail locally due to devcontainer or environment misconfiguration.

**Core principle:** The source code passes in CI. If a test fails locally, the problem is in the devcontainer setup, environment configuration, or settings — not the application code.

## When to Use

- Test fails in devcontainer but passes in CI
- Pulp plugin functional/API tests return unexpected errors
- Devcontainer environment seems misconfigured

## Debugging Workflow

1. **Reproduce the failure** — run the failing test inside the container
2. **Compare environments** — diff against pulp-docs skill / CI (`pulp-dev.env`, settings, compose)
3. **Check settings / env** — `settings.py` + `pulp-dev.env` (`PULP_*`)
4. **Check .bashrc** — service helpers and env vars
5. **Check patches** — for pulp-service, canonical patches are `/workspace/images/assets/patches`. Use `pulp-patches reapply` / `pulp-check-versions`
6. **Check docker-compose.yml** — services, volumes, Postgres version, networking
7. **Front door** — clients should hit nginx `:80`, not raw `:24817`/`:24816`

## Quick Reference

| Item | Location |
|------|----------|
| Source code | `/home/cferiavi/git/pulp/<component>` (e.g. `pulp_maven`, `pulp_python`, `pulpcore`) |
| Devcontainer config | `devcontainer/github.com/pulp/<component>/.devcontainer/` |
| App settings | `settings.py` + `pulp-dev.env` |
| Scripts (all modular Pulp containers) | `.devcontainer/scripts/{lifecycle,setup,runtime,shell}/` → `/opt/pulp-dev/scripts` |
| Patches (plugins / pulpcore) | `.devcontainer/patches/` → `/opt/pulp-dev/patches` (plugins apply onto `/repositories/pulpcore`) |
| Patches (pulp-service) | `pulp-service/images/assets/patches/` → `/workspace/images/assets/patches` |
| Human + agent docs | `.devcontainer/skills/pulp-dev/SKILL.md` |
| Plugin structure contract | `.claude/skills/pulp-plugin-devcontainer` |
| Docker Compose | `devcontainer/github.com/pulp/<component>/.devcontainer/docker-compose.yml` |
| Container shell commands | `source /opt/pulp-dev/scripts/shell/pulp-shell.sh` via `~/.bashrc` |

## Running Commands

Run commands inside the container:

```bash
podman exec -u vscode <container-name> <command>
```

Run tests:

```bash
podman exec -u vscode <container-name> pytest <test-path>
```

Container names follow the pattern `devcontainer-pulp-<component>-1` (e.g. `devcontainer-pulp-maven-1`, `devcontainer-pulp-python-1`).

## Common Mistakes

- **Assuming source code is wrong** — if CI passes, the code is fine. Focus on environment.
- **Ignoring patches** — RH overlays live in pulp-service assets; a failed apply or `pulp-*-local` without reapply can drop them. Plugin/pulpcore overlays live under `.devcontainer/patches`.
- **Hitting API/content ports directly** — prefer nginx `:80` for smash/CLI/populate (processes still bind `:24817`/`:24816`).
- **Forgetting postCreate** — `scripts/lifecycle/post-create.sh` runs `setup/NN-*.sh`.
- **Flat plugin layout** — `pulp_*` plugins must use modular `/opt/pulp-dev` (see `pulp-plugin-devcontainer` skill); do not reintroduce `/tmp/postCreateCommand.sh`.
