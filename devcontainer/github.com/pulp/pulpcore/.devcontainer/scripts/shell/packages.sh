# Editable / PyPI package switches for optional sibling plugins.
# Patches under /opt/pulp-dev/patches target pulpcore only — never overlay them
# onto sibling plugin checkouts (unlike pulp-service RH multi-package patches).

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

# Workspace is already an editable pulpcore install (includes pulp_file).
pulp-maven-local() { _install_local_package /repositories/pulp_maven pulp_maven; }
pulp-maven-pypi() { pip install "pulp-maven"; }

pulp-python-local() { _install_local_package /repositories/pulp_python pulp_python; }
pulp-python-pypi() { pip install "pulp-python"; }
