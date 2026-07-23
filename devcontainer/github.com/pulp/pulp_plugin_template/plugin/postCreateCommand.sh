#!/bin/bash

sudo chown -R "$(id -u):$(id -g)" ~/.claude 2>/dev/null || true
sudo chown -R "$(id -u):$(id -g)" /var/lib/pulp /etc/pulp

################################################################################
# Python dependencies
################################################################################

# Install local pulpcore checkout (if mounted) before the plugin so pip reuses it instead of pulling from PyPI
pulp-core-local() {
    if [ -f /repositories/pulpcore/pyproject.toml ] || [ -f /repositories/pulpcore/setup.cfg ]; then
        pip install -e /repositories/pulpcore
    else
        echo "No pulpcore checkout found at /repositories/pulpcore — using PyPI version"
    fi
}
pulp-core-pypi() { pip install pulpcore; }
pulp-core-local
pip install -e .
for req in lint_requirements.txt unittest_requirements.txt functest_requirements.txt test_requirements.txt doc_requirements.txt; do
    [ -f "$req" ] && pip install -r "$req"
done

# Install pulp-cli (base CLI) and its plugin-specific extension (e.g. pulp-cli-maven)
pip install httpie pulp-cli
plugin_suffix=$(basename /workspace | sed 's/^pulp_//')
pip install "pulp-cli-${plugin_suffix}" 2>/dev/null || true

################################################################################
# Database initialization
################################################################################

pulpcore-manager migrate --noinput
pulpcore-manager reset-admin-password --password password

################################################################################
# Shell aliases
################################################################################

cat >> ~/.bashrc << 'PULP_FUNCTIONS'
pulp-migrate() { pulpcore-manager migrate --noinput; }
pulp-api() { pulpcore-api --bind 127.0.0.1:24817 --timeout 90 --workers 2 --access-logfile -; }
pulp-content() { pulpcore-content --bind 127.0.0.1:24816 --timeout 90 --workers 2 --access-logfile -; }
pulp-worker() { pulpcore-worker; }
pulp-services() {
  local pids=()
  pulp-api 2>&1 | sed -u "s/^/$(printf '\033[32m')[api]$(printf '\033[0m') /" &
  pids+=($!)
  pulp-content 2>&1 | sed -u "s/^/$(printf '\033[34m')[content]$(printf '\033[0m') /" &
  pids+=($!)
  pulp-worker 2>&1 | sed -u "s/^/$(printf '\033[35m')[worker]$(printf '\033[0m') /" &
  pids+=($!)
  _pulp_cleanup() {
    for pid in "${pids[@]}"; do
      pkill -P "$pid" 2>/dev/null
      kill "$pid" 2>/dev/null
    done
    wait 2>/dev/null
    echo "Pulp services stopped."
  }
  trap '_pulp_cleanup; return 0' INT TERM
  wait
}
PULP_FUNCTIONS

declare -f pulp-core-local >> ~/.bashrc
declare -f pulp-core-pypi >> ~/.bashrc

################################################################################
# Claude Code: MCP servers and plugins
################################################################################

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true
