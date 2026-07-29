---
name: pulp-openapi
description: Pulp OpenAPI schema and ReDoc UI for the local API. Use when inspecting endpoints, generating clients, or browsing the Pulp REST API docs.
---

# Pulp OpenAPI

With `pulp-services` (or `pulp-api`) running, the OpenAPI schema and docs are served at:

- Schema (JSON): http://localhost:24817/pulp/api/v3/docs/api.json
- ReDoc UI: http://localhost:24817/pulp/api/v3/docs/

(Also via nginx on port 80: http://localhost/pulp/api/v3/docs/)

Auth for protected endpoints: `admin` / `password`.

To regenerate Python client bindings from the schema, see the `pulp-dev` skill (`pulp-bindings`).
