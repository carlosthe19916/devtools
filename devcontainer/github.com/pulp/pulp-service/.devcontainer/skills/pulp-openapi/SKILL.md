---
name: pulp-openapi
description: Pulp OpenAPI schema and ReDoc UI for the local API. Use when inspecting endpoints, generating clients, or browsing the Pulp REST API docs.
---

# Pulp OpenAPI

With `pulp-services` (or `pulp-api`) running, use the **API on `:24817`** for OpenAPI:

- Schema (JSON): http://localhost:24817/api/pulp/api/v3/docs/api.json
- ReDoc UI: http://localhost:24817/api/pulp/api/v3/docs/

If the host remaps port 24817, use the Ports panel URL for the same paths.

Auth for protected endpoints: `admin` / `password`.

To regenerate Python client bindings from the schema, see the `pulp-dev` skill (`pulp-bindings`).
