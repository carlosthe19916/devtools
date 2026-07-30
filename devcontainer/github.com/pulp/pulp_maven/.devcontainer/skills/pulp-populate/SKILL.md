---
name: pulp-populate
description: Populate pulp_maven with sample Maven artifacts via pulp-populate (no domains).
---

# Pulp populate (maven)

## Prerequisites

`pulp-services` running; nginx on `:80`.

## Command

```bash
pulp-populate
```

Uploads `assets/maven/` (junit jars/poms) into a maven repo/dist.

## Overrides

| Env | Default |
|-----|---------|
| `PULP_POPULATE_BASE_URL` | `http://localhost:80` |
| `PULP_POPULATE_API_ROOT` | `/pulp/` |
| `PULP_POPULATE_USER` / `PASSWORD` | `admin` / `password` |
