---
name: pulp-populate
description: Seed sample packages via pulp-populate (shared assets + env-selected types).
---

# Pulp populate

## Prerequisites

`pulp-services` running so the REST API is up on **`:24817`** (direct `pulpcore-api`, not nginx `:80`).

## Command

```bash
pulp-populate
```

Runs `/opt/pulp-dev/populate/setup_pulp.py` — a linear top-to-bottom script (domain → dists → repos → upload → list). Types and mode come from compose env.

## Env

| Env | Meaning |
|-----|---------|
| `DEVCONTAINER_POPULATE_TYPES` | comma list: `file`, `pypi`, `maven`, `npm`, `rpm` |
| `DEVCONTAINER_POPULATE_MODE` | `plugin` (default) or `service` (domains + ClowdApp API root) |
| `DEVCONTAINER_POPULATE_BASE_URL` | default `http://localhost:24817` (direct API) |
| `DEVCONTAINER_POPULATE_API_ROOT` | `/pulp/` (plugin/core) |
| `DEVCONTAINER_POPULATE_DOMAIN` | domain name when `MODE=service` |
| `DEVCONTAINER_POPULATE_USER` / `PASSWORD` | `admin` / `password` |

Assets live under `/opt/pulp-dev/populate/assets/<type>/`.
