---
name: pulp-populate
description: Populate pulpcore with sample file packages via pulp-populate (no domains).
---

# Pulp populate (file)

Seed a file repository/distribution and upload small sample files via the API on `:24817`.

## Prerequisites

- `pulp-services` running
- `pulp_file` available via pulpcore (bundled)
- `./populate` mounted at `/opt/pulp-dev/populate`

## Command

```bash
pulp-populate
```

Runs `/opt/pulp-dev/populate/setup_pulp.py`:
repo → dist → attach → upload `assets/file/` → list content.

## Assets

Under `/opt/pulp-dev/populate/assets/file/` (`hello-1.0.txt`, `hello-2.0.txt`). Add files and re-run.

## Overrides

| Env | Default |
|-----|---------|
| `PULP_POPULATE_BASE_URL` | `http://localhost:24817` |
| `PULP_POPULATE_API_ROOT` | `/pulp/` |
| `PULP_POPULATE_USER` / `PASSWORD` | `admin` / `password` |
| `PULP_POPULATE_ASSETS` | `/opt/pulp-dev/populate/assets` |
