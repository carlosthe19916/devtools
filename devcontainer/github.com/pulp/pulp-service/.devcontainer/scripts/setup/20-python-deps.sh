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
pip install httpie pulp-cli packaging setproctitle pytest-asyncio
npm install -g concurrently
