---
name: pulp-profile
description: pulp-service RH notes — domains, ClowdApp nginx, Sigstore, Postgres 16.
---

# pulp-service profile

See also shared `pulp-dev` / `pulp-openapi` / `pulp-populate` skills from `pulp-dev-common`.

## RH deltas

- Local script overlays: `20-python-deps`, `30-keys-and-patches` → `30-patches`
- Patches: `/workspace/images/assets/patches` (production parity)
- Status: `http://localhost:80/api/pulp/api/v3/status/`
- Postgres **16** (delete `pulp-service-postgres-data` if migrating from 17)
- Populate: `PULP_POPULATE_MODE=service`, multi-type + `PULP_POPULATE_DOMAIN`
- Attestation: `/etc/pki/attestation/test-key.pem`; Sigstore PEM under `/etc/pki/sigstore/`

## Local telemetry (OTEL + Prometheus + Grafana)

Compose starts `pulp-service-otel`, `pulp-service-prometheus`, and `pulp-service-grafana`.

| UI / endpoint | URL |
|---------------|-----|
| Grafana | http://localhost:3200 (admin/admin; anonymous Viewer) |
| Prometheus | http://localhost:9090 |
| Collector (from pulp container) | `http://pulp-service-otel:4318` |

Pulp is wired with `OTEL_EXPORTER_OTLP_ENDPOINT` / `OTEL_EXPORTER_OTLP_PROTOCOL` in `docker-compose.yml` and `PULP_OTEL_ENABLED=true` in `pulp-dev.env`.

Confirm: generate API traffic, then in Prometheus or Grafana Explore query metrics such as `api_active_connections` (OpenTelemetry names may appear with dots converted to underscores).

```bash
pulp-core-local / pulp-maven-local / pulp-python-local
pulp-patches apply|remove|reapply
# Prefer upstream helper for pulp_service suite (deselects known feature_service gaps):
#   /workspace/dev-container/scripts/pulp-test
```
