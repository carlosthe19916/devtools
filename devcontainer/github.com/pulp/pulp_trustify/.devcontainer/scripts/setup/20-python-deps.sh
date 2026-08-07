#!/usr/bin/env bash
set -euo pipefail

uv pip install setuptools wheel

# Install pulpcore from mounted checkout (or PyPI), then the workspace plugin.
if [ -f /repositories/pulpcore/pyproject.toml ] || [ -f /repositories/pulpcore/setup.cfg ] \
   || [ -f /repositories/pulpcore/setup.py ]; then
  echo "==> Editable install /repositories/pulpcore"
  uv pip install -e /repositories/pulpcore --no-build-isolation
else
  echo "==> PyPI install pulpcore"
  uv pip install pulpcore
fi

# pulp_trustify connects Django signals to PythonPackageContent — pulp-python must be present.
uv pip install pulp-python

uv pip install -e .
for req in lint_requirements.txt unittest_requirements.txt functest_requirements.txt \
           test_requirements.txt doc_requirements.txt; do
  [ -f "$req" ] && uv pip install -r "$req"
done

plugin_suffix=$(basename /workspace | sed 's/^pulp_//')
uv pip install httpie pulp-cli packaging pytest
uv pip install "pulp-cli-${plugin_suffix}" 2>/dev/null || true
# Keep twine below 7 for shared fixture compatibility with pulp_python.
uv pip install "twine>=4,<7"
npm install -g concurrently
