# Sourced from ~/.bashrc — interactive helpers for the pulp-service devcontainer.
# Keep cwd (/workspace) from shadowing the editable pulp_service package:
# gunicorn inserts cfg.chdir at the front of sys.path unless we start elsewhere.

export PYTHONSAFEPATH=1
export PULP_PATCH_DIR="${PULP_PATCH_DIR:-/workspace/images/assets/patches}"
export PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"

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
    # Editable trees are not under site-packages; overlay RH patches onto the checkout.
    echo "Applying patches onto editable checkout ${path} ..."
    bash "${PULP_DEV_SCRIPTS}/patches.sh" apply "${path}"
  else
    echo "No checkout found at ${path} — using PyPI version of ${pkg}"
  fi
}

pulp-core-local() { _install_local_package /repositories/pulpcore pulpcore; }
pulp-core-pypi() { pip install "pulpcore"; bash "${PULP_DEV_SCRIPTS}/patches.sh" reapply; }

pulp-maven-local() { _install_local_package /repositories/pulp_maven pulp_maven; }
pulp-maven-pypi() { pip install "pulp-maven"; bash "${PULP_DEV_SCRIPTS}/patches.sh" reapply; }

pulp-python-local() { _install_local_package /repositories/pulp_python pulp_python; }
pulp-python-pypi() { pip install "pulp-python"; bash "${PULP_DEV_SCRIPTS}/patches.sh" reapply; }

pulp-migrate() { pulpcore-manager migrate --noinput; }
pulp-api() { bash "${PULP_DEV_SCRIPTS}/run-api.sh"; }
pulp-content() { bash "${PULP_DEV_SCRIPTS}/run-content.sh"; }
pulp-worker() { pulpcore-worker; }

pulp-services() {
  export PYTHONSAFEPATH=1
  concurrently --names "api,content,worker" --prefix-colors "green,blue,magenta" \
    "env PYTHONSAFEPATH=1 bash ${PULP_DEV_SCRIPTS}/run-api.sh" \
    "env PYTHONSAFEPATH=1 bash ${PULP_DEV_SCRIPTS}/run-content.sh" \
    "env PYTHONSAFEPATH=1 pulpcore-worker"
}

pulp-bindings() {
  bash "${PULP_DEV_SCRIPTS}/prepare-bindings.sh" --force \
    "${@:?Usage: pulp-bindings <component> [component2 ...]}"
}

pulp-patches() { bash "${PULP_DEV_SCRIPTS}/patches.sh" "$@"; }
pulp-check-versions() { bash "${PULP_DEV_SCRIPTS}/check-versions.sh" "$@"; }
pulp-psql() { env PGPASSWORD=pulp psql -U pulp -d pulp -h "$DB_HOST" -p 5432 "$@"; }
postgres-psql() { env PGPASSWORD=pulp psql -U pulp -d postgres -h "$DB_HOST" -p 5432 "$@"; }
