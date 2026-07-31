---
name: pulp-openapi
description: Pulp OpenAPI schema and ReDoc UI for the local API.
---

# Pulp OpenAPI

With `pulp-services` running:

**Plugins** (nginx `:80`, `/pulp/`):

- Schema: http://localhost:80/pulp/api/v3/docs/api.json
- ReDoc: http://localhost:80/pulp/api/v3/docs/

**pulpcore** (direct API `:24817` preferred for certguard; nginx `:80` also works):

- Schema: http://localhost:24817/pulp/api/v3/docs/api.json
- ReDoc: http://localhost:24817/pulp/api/v3/docs/

**pulp-service** (ClowdApp `/api/pulp/` via nginx `:80`; Ports panel may remap host ports):

- Schema: http://localhost:80/api/pulp/api/v3/docs/api.json
- ReDoc: http://localhost:80/api/pulp/api/v3/docs/

Auth: `admin` / `password`. Regenerate clients with `pulp-bindings` (components from `PULP_BINDINGS` / discovery).
