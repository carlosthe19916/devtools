#!/usr/bin/env bash
# Symlink the shared oci-env configuration in this devtools repo into each Pulp
# source checkout, so oci_env reads compose.env files and plugin profiles
# directly from here (single source of truth). Idempotent; safe to re-run.
set -euo pipefail

# Directory of this script = the devtools oci-env config root.
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# SRC_DIR = the dir that holds the Pulp checkouts (pulpcore, pulp_trustify, ...).
# oci_env derives this as the parent of the oci_env checkout (OCI_ENV_PATH);
# mirror that. Precedence: positional arg > $SRC_DIR > $OCI_ENV_PATH/..
if [[ -n "${1:-}" ]]; then
    SRC_DIR="$(cd "$1" && pwd)"
elif [[ -n "${SRC_DIR:-}" ]]; then
    SRC_DIR="$(cd "$SRC_DIR" && pwd)"
elif [[ -n "${OCI_ENV_PATH:-}" ]]; then
    SRC_DIR="$(cd "$OCI_ENV_PATH/.." && pwd)"
else
    echo "ERROR: set OCI_ENV_PATH (or SRC_DIR, or pass the checkouts dir as \$1)" >&2
    echo "       so the script knows where the Pulp checkouts live." >&2
    exit 1
fi

echo "Config source : $CONFIG_DIR"
echo "Pulp checkouts: $SRC_DIR"
echo

link() {  # link <target-in-devtools> <link-path-in-checkout>
    local target="$1" linkpath="$2"
    if [[ -d "$linkpath" && ! -L "$linkpath" ]]; then
        echo "SKIP  $linkpath (real directory exists - remove it manually first)"
        return
    fi
    ln -sfn "$target" "$linkpath"
    echo "LINK  $linkpath -> $target"
}

for repo_cfg in "$CONFIG_DIR"/*/; do
    repo_cfg="${repo_cfg%/}"
    repo="$(basename "$repo_cfg")"
    checkout="$SRC_DIR/$repo"

    if [[ ! -d "$checkout" ]]; then
        echo "WARN  no checkout for '$repo' at $checkout - skipping"
        continue
    fi

    [[ -f "$repo_cfg/compose.env" ]] && link "$repo_cfg/compose.env" "$checkout/compose.env"
    [[ -d "$repo_cfg/profiles"    ]] && link "$repo_cfg/profiles"    "$checkout/profiles"
done

echo
echo "Done."
