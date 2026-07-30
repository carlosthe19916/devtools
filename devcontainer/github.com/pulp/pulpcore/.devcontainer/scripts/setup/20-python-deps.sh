#!/usr/bin/env bash
set -euo pipefail

cd /workspace

pip install -e .
for req in lint_requirements.txt unittest_requirements.txt functest_requirements.txt \
           test_requirements.txt doc_requirements.txt; do
  [ -f "$req" ] && pip install -r "$req"
done

# pulp_file ships inside pulpcore. Optional sibling plugins if checkouts are mounted.
_install_plugin() {
  local path="$1"
  if [ -f "${path}/pyproject.toml" ] || [ -f "${path}/setup.cfg" ] || [ -f "${path}/setup.py" ]; then
    echo "==> Editable install ${path}"
    pip install -e "${path}" --no-build-isolation
  fi
}

_install_plugin /repositories/pulp_maven
_install_plugin /repositories/pulp_python

# File CLI commands are built into pulp-cli (no pulp-cli-file package).
pip install httpie pulp-cli packaging
# Soft-install plugin CLI extensions when the server plugin is present.
python3 -c "import pulp_maven" 2>/dev/null && pip install pulp-cli-maven || true
python3 -c "import pulp_python" 2>/dev/null && pip install pulp-cli-python 2>/dev/null || true

npm install -g concurrently
