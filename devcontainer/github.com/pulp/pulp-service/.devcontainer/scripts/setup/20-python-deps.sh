#!/usr/bin/env bash
set -euo pipefail

pip install -e /workspace/pulp_service
for req in /workspace/pulp_service/functest_requirements.txt \
           /workspace/pulp_service/lint_requirements.txt \
           /workspace/pulp_service/unittest_requirements.txt \
           /workspace/pulp_service/test_requirements.txt \
           /workspace/pulp_service/doc_requirements.txt; do
  [ -f "$req" ] && pip install -r "$req"
done

# Used by pulpcore/pulp_service functional fixtures even though not in requirements.txt
pip install pulp-file
pip install httpie pulp-cli packaging setproctitle

# Match pulp-service/dev-container/scripts/pulp-test install_test_deps exactly.
# (Do not invent fixture bridges — pulp-test deselects the known-broken feature_service tests.)
pip install "pytest<8" pytest-django gnupg
if curl -sf -o /tmp/functest_requirements.txt \
    https://raw.githubusercontent.com/pulp/pulp_rpm/main/functest_requirements.txt; then
  pip install -r /tmp/functest_requirements.txt || true
fi
if curl -sf -o /tmp/unittest_requirements.txt \
    https://raw.githubusercontent.com/pulp/pulp_rpm/main/unittest_requirements.txt; then
  pip install -r /tmp/unittest_requirements.txt || true
fi

npm install -g concurrently
