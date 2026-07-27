#!/bin/bash

sudo chown -R "$(id -u):$(id -g)" ~/.claude 2>/dev/null || true
sudo chown -R "$(id -u):$(id -g)" /var/lib/pulp /etc/pulp

################################################################################
# Helpers: switch optional deps between local mounts and PyPI
################################################################################

_remove_shadowed_package() {
    local pkg="$1"
    python - "$pkg" <<'PY'
import pathlib, shutil, site, sys
pkg = sys.argv[1]
for sp in site.getsitepackages():
    target = pathlib.Path(sp) / pkg
    if target.is_dir():
        shutil.rmtree(target)
        print(f"Removed shadowed {target}")
PY
}

_install_local_package() {
    local path="$1"
    local pkg="$2"
    if [ -f "${path}/pyproject.toml" ] || [ -f "${path}/setup.cfg" ] || [ -f "${path}/setup.py" ]; then
        pip install -e "${path}" --no-build-isolation
        _remove_shadowed_package "${pkg}"
    else
        echo "No checkout found at ${path} — using PyPI version of ${pkg}"
    fi
}

pulp-core-local() { _install_local_package /repositories/pulpcore pulpcore; }
pulp-core-pypi() { pip install "pulpcore"; }

pulp-maven-local() { _install_local_package /repositories/pulp_maven pulp_maven; }
pulp-maven-pypi() { pip install "pulp-maven"; }

pulp-python-local() { _install_local_package /repositories/pulp_python pulp_python; }
pulp-python-pypi() { pip install "pulp-python"; }

################################################################################
# Python dependencies (PyPI pins via pulp-service requirements by default)
################################################################################

# Repo is mounted at /workspace; setuptools project is ./pulp_service/
pip install -e /workspace/pulp_service
for req in /workspace/pulp_service/functest_requirements.txt \
           /workspace/pulp_service/lint_requirements.txt \
           /workspace/pulp_service/unittest_requirements.txt \
           /workspace/pulp_service/test_requirements.txt \
           /workspace/pulp_service/doc_requirements.txt; do
    [ -f "$req" ] && pip install -r "$req"
done

# pulp-file is used by pulpcore/pulp_service functional fixtures (file_bindings)
# and is listed in pulp-test COMPONENTS even though it is not in requirements.txt
pip install pulp-file

pip install httpie pulp-cli packaging
npm install -g concurrently

################################################################################
# Apply patches only when a local pulpcore checkout is present
################################################################################

if [ -d /tmp/patches ] && [ -d /repositories/pulpcore/.git ]; then
    for p in /tmp/patches/*.patch; do
        [ -f "$p" ] || continue
        patch -p1 --forward --no-backup-if-mismatch -d /repositories/pulpcore < "$p" || true
    done
fi

################################################################################
# Database initialization
################################################################################

python3 -c "import redis; redis.from_url('$REDIS_URL').flushall(); print('Redis flushed')" 2>/dev/null || true
pulpcore-manager migrate --noinput
pulpcore-manager reset-admin-password --password password

################################################################################
# pulp-smash configuration
################################################################################

sudo mkdir -p /etc/xdg/pulp_smash
sudo tee /etc/xdg/pulp_smash/settings.json > /dev/null << 'SMASH_CONFIG'
{
  "pulp": {
    "auth": ["admin", "password"],
    "selinux enabled": false,
    "version": "3"
  },
  "hosts": [
    {
      "hostname": "localhost",
      "roles": {
        "api": {
          "port": 24817,
          "scheme": "http",
          "service": "pulpcore-api"
        },
        "content": {
          "port": 24816,
          "scheme": "http",
          "service": "pulp_content_app"
        },
        "pulp resource manager": {},
        "pulp workers": {},
        "redis": {},
        "shell": {
          "transport": "local"
        }
      }
    }
  ]
}
SMASH_CONFIG

################################################################################
# Shell aliases
################################################################################

cat >> ~/.bashrc << 'PULP_FUNCTIONS'
# Keep cwd (/workspace) from shadowing the editable pulp_service package.
# PYTHONSAFEPATH alone is not enough for gunicorn: it inserts cfg.chdir (cwd)
# at the front of sys.path, so /workspace/pulp_service becomes a namespace package
# without default_app_config. Start api/content from a neutral directory.
export PYTHONSAFEPATH=1

_pulp_gunicorn_cwd=/home/vscode

pulp-migrate() { pulpcore-manager migrate --noinput; }
pulp-api() {
  (cd "$_pulp_gunicorn_cwd" && pulpcore-api --bind 127.0.0.1:24817 --timeout 90 --workers 2 --access-logfile -)
}
pulp-content() {
  (cd "$_pulp_gunicorn_cwd" && pulpcore-content --bind 127.0.0.1:24816 --timeout 90 --workers 2 --access-logfile -)
}
pulp-worker() { pulpcore-worker; }
pulp-services() {
  export PYTHONSAFEPATH=1
  concurrently --names "api,content,worker" --prefix-colors "green,blue,magenta" \
    "cd ${_pulp_gunicorn_cwd} && env PYTHONSAFEPATH=1 pulpcore-api --bind 127.0.0.1:24817 --timeout 90 --workers 2 --access-logfile -" \
    "cd ${_pulp_gunicorn_cwd} && env PYTHONSAFEPATH=1 pulpcore-content --bind 127.0.0.1:24816 --timeout 90 --workers 2 --access-logfile -" \
    "env PYTHONSAFEPATH=1 pulpcore-worker"
}
pulp-bindings() {
  bash /tmp/prepare-bindings.sh --force "${@:?Usage: pulp-bindings <component> [component2 ...]}"
}
pulp-psql() { env PGPASSWORD=pulp psql -U pulp -d pulp -h "$DB_HOST" -p 5432 "$@"; }
postgres-psql() { env PGPASSWORD=pulp psql -U pulp -d postgres -h "$DB_HOST" -p 5432 "$@"; }
PULP_FUNCTIONS

declare -f _remove_shadowed_package >> ~/.bashrc
declare -f _install_local_package >> ~/.bashrc
declare -f pulp-core-local >> ~/.bashrc
declare -f pulp-core-pypi >> ~/.bashrc
declare -f pulp-maven-local >> ~/.bashrc
declare -f pulp-maven-pypi >> ~/.bashrc
declare -f pulp-python-local >> ~/.bashrc
declare -f pulp-python-pypi >> ~/.bashrc

################################################################################
# Claude Code: MCP servers and plugins
################################################################################

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true

if [ -d /tmp/claude-skills ]; then
    mkdir -p ~/.claude/skills
    cp -r /tmp/claude-skills/* ~/.claude/skills/
fi
