#!/bin/bash
# oci-env profile init for pulp-service.
# Generates the RSA attestation keypair that pulp_service expects at
# ATTESTATION_VERIFICATION_KEY (see pulp_config.env), so the
# test_attestation_verification functional test can run. Idempotent: skips if the
# public key already exists. Mirrors pulp-service/dev-container/Dockerfile.
set -euo pipefail

KEY_DIR=/etc/pki/attestation
PUB_KEY="${KEY_DIR}/test-key.pem"
PRIV_KEY="${KEY_DIR}/test-key-private.pem"

if [[ -f "${PUB_KEY}" ]]; then
    echo "pulp-service: attestation key already present at ${PUB_KEY}, skipping."
    exit 0
fi

echo "pulp-service: generating attestation keypair at ${KEY_DIR}..."
mkdir -p "${KEY_DIR}"

python3 -c "
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
key = rsa.generate_private_key(public_exponent=65537, key_size=4096)
with open('${PRIV_KEY}', 'wb') as f:
    f.write(key.private_bytes(serialization.Encoding.PEM,
                              serialization.PrivateFormat.PKCS8,
                              serialization.NoEncryption()))
with open('${PUB_KEY}', 'wb') as f:
    f.write(key.public_key().public_bytes(serialization.Encoding.PEM,
                                           serialization.PublicFormat.SubjectPublicKeyInfo))
"

chmod 600 "${PRIV_KEY}"
chmod 644 "${PUB_KEY}"
echo "pulp-service: attestation keypair generated."
