#!/usr/bin/env bash
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"

if [ -f /workspace/images/assets/keys/SIGSTORE-redhat-release3.pem ]; then
  sudo cp /workspace/images/assets/keys/SIGSTORE-redhat-release3.pem \
    /etc/pki/sigstore/SIGSTORE-redhat-release3
  sudo chmod 644 /etc/pki/sigstore/SIGSTORE-redhat-release3
fi

bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" apply
