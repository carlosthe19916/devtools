#!/usr/bin/env bash

PULP_UV_VENV="${PULP_UV_VENV:-/workspace/.venv}"
PULP_UV_PYTHON="${PULP_UV_PYTHON:-3.11}"

pulp_uv_env_activate() {
  export UV_LINK_MODE="${UV_LINK_MODE:-copy}"
  export UV_PYTHON_PREFERENCE="${UV_PYTHON_PREFERENCE:-only-system}"
  export UV_CACHE_DIR="${UV_CACHE_DIR:-${HOME}/.cache/uv}"
  export UV_PROJECT_ENVIRONMENT="${PULP_UV_VENV}"
  export VIRTUAL_ENV="${PULP_UV_VENV}"
  if [ -n "${PATH:-}" ]; then
    PATH="$(printf '%s' "${PATH}" | awk -v v="${PULP_UV_VENV}/bin" -F: '{
      out = ""
      for (i = 1; i <= NF; i++) {
        if ($i == v || $i == "/usr/local/py-utils/bin") continue
        out = (out == "" ? $i : out ":" $i)
      }
      print out
    }')"
  fi
  export PATH="${PULP_UV_VENV}/bin:${PATH}"
  unset UV_SYSTEM_PYTHON
}

pulp_uv_env_ensure() {
  pulp_uv_env_activate
  if [ ! -x "${PULP_UV_VENV}/bin/python" ]; then
    if ! command -v uv >/dev/null 2>&1; then
      echo "ERROR: uv not found on PATH (install astral.sh-uv devcontainer feature)" >&2
      return 1
    fi
    echo "==> Creating ${PULP_UV_VENV} (python ${PULP_UV_PYTHON})"
    mkdir -p "$(dirname "${PULP_UV_VENV}")"
    uv venv "${PULP_UV_VENV}" --python "${PULP_UV_PYTHON}"
  fi
}
