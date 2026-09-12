# oci-env

Shared oci-env compose files for Pulp checkouts. Point `oci-env -e` at a file
here instead of a per-repo `compose.env`.

## Prerequisites

- Clone `oci_env`, `pulpcore`, and any plugins you need as siblings (default
  `SRC_DIR` is the parent of the `oci_env` checkout).
- Install the client: `pip3 install -e client` from the `oci_env` checkout.
- Set `OCI_ENV_PATH` to that checkout.

```bash
export OCI_ENV_PATH="$HOME/git/github/pulp/oci_env"
export DEVTOOLS_PATH="$HOME/git/github/carlosthe19916/devtools"
```

## Link config into the checkouts

oci_env reads plugin profiles from `SRC_DIR/<repo>/profiles`. Run this once (and
after a fresh clone / `git clean`) to symlink this repo's profiles and
compose.env files into the Pulp checkouts:

```bash
./oci-env/setup-links.sh          # uses $OCI_ENV_PATH to locate checkouts
# or: ./oci-env/setup-links.sh /path/to/pulp/checkouts
```

## Start

From this directory:

```bash
# pulpcore — API http://localhost:5001
oci-env -e pulpcore/compose.env compose build
oci-env -e pulpcore/compose.env compose up

# pulp_trustify — API http://localhost:5002
oci-env -e pulp_trustify/compose.env compose build
oci-env -e pulp_trustify/compose.env compose up

# pulp-service — API http://localhost:5003/api/pulp/api/v3/status/
oci-env -e pulp-service/compose.env compose build
oci-env -e pulp-service/compose.env compose up

# pulp_maven — API http://localhost:5004
oci-env -e pulp_maven/compose.env compose build
oci-env -e pulp_maven/compose.env compose up

# pulp-ui-2 — API http://localhost:5003, Keycloak http://localhost:8090
oci-env -e pulp-ui-2/compose.env compose build
oci-env -e pulp-ui-2/compose.env compose up
```

## pulp-service notes

`pulp-service` is a nested, hyphenated checkout, so its config has two quirks:

- **Source path.** The installable package lives at
  `pulp-service/pulp_service`, so `DEV_SOURCE_PATH` uses that nested path. This
  means the entry is not a bare plugin name — pass `-p pulp_service` explicitly
  to `test` and `generate-client` (they can't auto-iterate the slashed entry).
- **pulpcore pin.** `pulp_service` pins `pulpcore==3.115.2`. Since `compose.env`
  also source-installs `pulpcore`, keep the `pulpcore` checkout on a
  3.115.x-compatible ref, or drop `pulpcore` from `DEV_SOURCE_PATH` to install
  it from PyPI at 3.115.2.

The `service` profile generates an attestation keypair at startup so
`test_attestation_verification` can run; see `pulp-service/profiles/service/`.

From anywhere:

```bash
oci-env -e "$DEVTOOLS_PATH/oci-env/pulpcore/compose.env" compose up
oci-env -e "$DEVTOOLS_PATH/oci-env/pulp_trustify/compose.env" compose up
oci-env -e "$DEVTOOLS_PATH/oci-env/pulp-ui-2/compose.env" compose up
```

## Lifecycle

```bash
oci-env -e pulpcore/compose.env compose down
oci-env -e pulpcore/compose.env compose down --volumes
oci-env -e pulpcore/compose.env db reset
```

Replace `pulpcore/compose.env` with `pulp_trustify/compose.env` for that stack.
