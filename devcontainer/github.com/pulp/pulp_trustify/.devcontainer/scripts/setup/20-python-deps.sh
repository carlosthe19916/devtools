#!/usr/bin/env bash
set -euo pipefail

# Install pulpcore from mounted checkout (or PyPI), then the workspace plugin.
if [ -f /repositories/pulpcore/pyproject.toml ] || [ -f /repositories/pulpcore/setup.cfg ] \
   || [ -f /repositories/pulpcore/setup.py ]; then
  echo "==> Editable install /repositories/pulpcore"
  pip install -e /repositories/pulpcore --no-build-isolation
else
  echo "==> PyPI install pulpcore"
  pip install pulpcore
fi

pip install -e .
for req in lint_requirements.txt unittest_requirements.txt functest_requirements.txt \
           test_requirements.txt doc_requirements.txt; do
  [ -f "$req" ] && pip install -r "$req"
done

# pulp_trustify connects Django signals to PythonPackageContent — pulp-python must be present.
pip install pulp-python

plugin_suffix=$(basename /workspace | sed 's/^pulp_//')
pip install httpie pulp-cli packaging
pip install "pulp-cli-${plugin_suffix}" 2>/dev/null || true
# Keep twine below 7 for shared fixture compatibility with pulp_python.
pip install "twine>=4,<7"
npm install -g concurrently
