# Editable / PyPI package switches. Behavior depends on PULP_DEV_KIND.

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
  local apply_patches="${3:-0}"
  if [ -f "${path}/pyproject.toml" ] || [ -f "${path}/setup.cfg" ] || [ -f "${path}/setup.py" ]; then
    pip install -e "${path}" --no-build-isolation
    _remove_shadowed_package "${pkg}"
    if [ "${apply_patches}" = "1" ]; then
      echo "Applying patches onto editable checkout ${path} ..."
      bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" apply "${path}"
    fi
  else
    echo "No checkout found at ${path} — using PyPI version of ${pkg}"
  fi
}

case "${PULP_DEV_KIND:-plugin}" in
  core)
    # Patches under /opt/pulp-dev/patches target pulpcore only — never overlay them
    # onto sibling plugin checkouts (unlike pulp-service RH multi-package patches).
    pulp-maven-local() { _install_local_package /repositories/pulp_maven pulp_maven 0; }
    pulp-maven-pypi() { pip install "pulp-maven"; }
    pulp-python-local() { _install_local_package /repositories/pulp_python pulp_python 0; }
    pulp-python-pypi() { pip install "pulp-python"; }
    ;;
  service)
    pulp-core-local() { _install_local_package /repositories/pulpcore pulpcore 1; }
    pulp-core-pypi() { pip install "pulpcore"; bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" reapply; }
    pulp-maven-local() { _install_local_package /repositories/pulp_maven pulp_maven 1; }
    pulp-maven-pypi() { pip install "pulp-maven"; bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" reapply; }
    pulp-python-local() { _install_local_package /repositories/pulp_python pulp_python 1; }
    pulp-python-pypi() { pip install "pulp-python"; bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" reapply; }
    ;;
  plugin|*)
    pulp-core-local() { _install_local_package /repositories/pulpcore pulpcore 1; }
    pulp-core-pypi() { pip install "pulpcore"; bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" reapply; }
    ;;
esac
