---
name: pulp-profile
description: pulpcore-specific notes — certguard API port, empty patches, optional sibling plugins.
---

# pulpcore profile

See also shared `pulp-dev` / `pulp-openapi` / `pulp-populate` skills from `pulp-dev-common`.

## Deltas

- Workspace **is** pulpcore (`/workspace`); siblings at `/repositories/pulp_{maven,python}`
- Smash/CLI on **`:24817`** (certguard); content via nginx `:80` + `/pulp/content/`
- `patches/` empty by default (CI parity — do not ship RH heartbeat overlays)
- Bindings: discover `core` + in-tree `pulp_*`
- Populate: `PULP_POPULATE_TYPES=file`, base URL `:24817`
- Optional: `pulp-maven-local` / `pulp-python-local` (no patch overlay onto siblings)

```bash
pytest pulpcore/tests/unit/ -v
pytest pulpcore/tests/functional/ -v
pytest pulp_certguard/tests/functional/ -v
```

Postgres 17 @ `pulpcore-db`.
