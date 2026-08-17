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

## Start

From this directory:

```bash
# pulpcore — API http://localhost:5001
oci-env -e pulpcore/compose.env compose build
oci-env -e pulpcore/compose.env compose up

# pulp_trustify — API http://localhost:5002
oci-env -e pulp_trustify/compose.env compose build
oci-env -e pulp_trustify/compose.env compose up
```

From anywhere:

```bash
oci-env -e "$DEVTOOLS_PATH/oci-env/pulpcore/compose.env" compose up
oci-env -e "$DEVTOOLS_PATH/oci-env/pulp_trustify/compose.env" compose up
```

## Lifecycle

```bash
oci-env -e pulpcore/compose.env compose down
oci-env -e pulpcore/compose.env compose down --volumes
oci-env -e pulpcore/compose.env db reset
```

Replace `pulpcore/compose.env` with `pulp_trustify/compose.env` for that stack.
