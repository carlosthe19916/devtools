---
name: pulp-openapi
description: Pulp OpenAPI schema and ReDoc UI for the local API. Use when inspecting endpoints, generating clients, or browsing the Pulp REST API docs.
---

# Pulp OpenAPI

With `pulp-services` (or `pulp-api`) running:

- Schema (JSON): http://localhost:24817/pulp/api/v3/docs/api.json
- ReDoc UI: http://localhost:24817/pulp/api/v3/docs/

Nginx proxy also exposes the same paths on `:80`.
Auth: `admin` / `password`.

Regenerate Python clients with `pulp-bindings` (see `pulp-dev` skill).
