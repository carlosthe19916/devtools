# Editable / PyPI package switches (workspace is the plugin).

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
    echo "Applying patches onto editable checkout ${path} ..."
    bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" apply "${path}"
  else
    echo "No checkout found at ${path} — using PyPI version of ${pkg}"
  fi
}

pulp-core-local() { _install_local_package /repositories/pulpcore pulpcore; }
pulp-core-pypi() { pip install "pulpcore"; bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" reapply; }
