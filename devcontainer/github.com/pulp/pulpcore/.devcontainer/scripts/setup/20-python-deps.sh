#!/usr/bin/env bash
set -euo pipefail

uv pip install setuptools wheel

cd /workspace

uv pip install -e .
for req in lint_requirements.txt unittest_requirements.txt functest_requirements.txt \
           test_requirements.txt doc_requirements.txt; do
  [ -f "$req" ] && uv pip install -r "$req"
done

uv pip install pulp-maven pulp-python

uv pip install httpie pulp-cli pulp-cli-maven pulp-cli-python packaging pytest
# Twine 7+ rejects Metadata-Version 2.0 (used by pulp_python fixtures).
uv pip install "twine>=4,<7"

npm install -g concurrently
