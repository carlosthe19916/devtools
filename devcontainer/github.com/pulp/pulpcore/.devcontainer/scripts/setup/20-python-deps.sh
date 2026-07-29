#!/usr/bin/env bash
set -euo pipefail

pip install -e .
for req in lint_requirements.txt unittest_requirements.txt functest_requirements.txt \
           test_requirements.txt doc_requirements.txt; do
  [ -f "$req" ] && pip install -r "$req"
done

pip install httpie pulp-cli packaging
npm install -g concurrently
