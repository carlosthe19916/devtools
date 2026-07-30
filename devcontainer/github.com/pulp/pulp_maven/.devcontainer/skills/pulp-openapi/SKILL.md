---
name: pulp-openapi
description: Pulp OpenAPI schema and ReDoc UI for the local API.
---

# Pulp OpenAPI

With `pulp-services` running, use nginx `:80`:

- Schema: http://localhost:80/pulp/api/v3/docs/api.json
- ReDoc: http://localhost:80/pulp/api/v3/docs/

Auth: `admin` / `password`. Regenerate clients with `pulp-bindings core maven`.
