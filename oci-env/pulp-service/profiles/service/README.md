# service profile

Baseline dev profile for the `pulp_service` plugin. No extra containers — it only
runs an init script and sets one plugin setting.

## Auto-configuration

`init.sh` runs inside the `pulp` container at startup and generates an RSA
attestation keypair at `/etc/pki/attestation/test-key.pem` (public) and
`test-key-private.pem` (private), mirroring
`pulp-service/dev-container/Dockerfile`. It is idempotent — it skips if the public
key already exists. `pulp_config.env` points
`PULP_ATTESTATION_VERIFICATION_KEY` at that public key, so
`test_attestation_verification` has a key to verify against.

Auth is left relaxed by `compose.env`
(`REST_FRAMEWORK__DEFAULT_PERMISSION_CLASSES=AllowAny`); the RH-identity /
DomainBasedPermission stack from `dev-container/settings.py` is intentionally not
reproduced here so the API can be called directly with `admin:password`.

## Usage

```bash
oci-env -e compose.env compose build
oci-env -e compose.env compose up

# Status (API_ROOT is /api/pulp/, DOMAIN_ENABLED, so a domain is in the path):
http --auth admin:password get http://localhost:5003/api/pulp/api/v3/status/
```

Confirm the plugin loaded:

```bash
curl -sS -u admin:password http://localhost:5003/api/pulp/api/v3/status/ \
  | jq '.versions[] | select(.component=="service")'
```

## Tests

Always pass `-p pulp_service` explicitly — the slashed `DEV_SOURCE_PATH` entry
(`pulp-service/pulp_service`) is not a valid bare plugin name for auto-iteration:

```bash
oci-env -e compose.env test -p pulp_service unit
oci-env -e compose.env generate-client pulp_service
oci-env -e compose.env test -p pulp_service functional
```
