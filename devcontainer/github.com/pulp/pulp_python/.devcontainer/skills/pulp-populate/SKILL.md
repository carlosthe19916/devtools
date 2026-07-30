---
name: pulp-populate
description: Populate pulp_python with sample PyPI packages via pulp-populate (no domains).
---

# Pulp populate (python)

## Prerequisites

`pulp-services` running; nginx on `:80`.

## Command

```bash
pulp-populate
```

Uploads `assets/pypi/` (six wheels) into a python repo/dist.

## Overrides

| Env | Default |
|-----|---------|
| `PULP_POPULATE_BASE_URL` | `http://localhost:80` |
| `PULP_POPULATE_API_ROOT` | `/pulp/` |
| `PULP_POPULATE_USER` / `PASSWORD` | `admin` / `password` |
