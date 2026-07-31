---
name: pulp-profile
description: pulp-service RH notes — domains, ClowdApp nginx, Sigstore, Postgres 16.
---

# pulp-service profile

See also shared `pulp-dev` / `pulp-openapi` / `pulp-populate` skills from `pulp-dev-common`.

## RH deltas

- Local script overlays: `10-dirs`, `20-python-deps`, `30-keys-and-patches`, `patches.sh`, `run-content.sh`
- Setup step 30: `PULP_SETUP_30=30-keys-and-patches.sh` (service overlay; Sigstore key + patches)
- Patches: `/workspace/images/assets/patches` (production parity)
- Status: `http://localhost:80/api/pulp/api/v3/status/`
- Postgres **16** (delete `pulp-service-postgres-data` if migrating from 17)
- Populate: `PULP_POPULATE_MODE=service`, multi-type + `PULP_POPULATE_DOMAIN`
- Attestation: `/etc/pki/attestation/test-key.pem`; Sigstore PEM under `/etc/pki/sigstore/`

```bash
pulp-core-local / pulp-maven-local / pulp-python-local
pulp-patches apply|remove|reapply
pytest pulp_*/tests/unit/ -v
pytest pulp_*/tests/functional/ -v
```
