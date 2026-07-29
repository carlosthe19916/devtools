---
description: Populate pulp-service domain with sample file/pypi/maven/npm/rpm packages via pulp-populate
---

# Pulp populate

Seed a domain with small sample packages (file, PyPI, Maven, npm, RPM).

## Prerequisites

`pulp-services` running; `./populate` mounted at `/opt/pulp-dev/populate`.

## Command

```bash
pulp-populate
```

Runs `/opt/pulp-dev/populate/setup_pulp.py` (domain → dists/repos → upload `assets/<type>/` → list). Prefer this over ad-hoc API calls.

## Assets

Under `/opt/pulp-dev/populate/assets/`: two versions each of file, six (PyPI), is-odd (npm), junit (Maven), bear/whale (RPM). Add files there and re-run.

## Overrides

`PULP_POPULATE_BASE_URL` (default `http://localhost:24817`), `PULP_POPULATE_DOMAIN`, `PULP_POPULATE_USER` / `PULP_POPULATE_PASSWORD`, `PULP_POPULATE_ASSETS`.
