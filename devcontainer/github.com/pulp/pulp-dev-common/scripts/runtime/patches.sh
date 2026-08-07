#!/usr/bin/env bash
# Apply / reverse patches from DEVCONTAINER_PATCH_DIR (default: /opt/pulp-dev/patches).
#
# Usage:
#   patches.sh apply [tree]
#   patches.sh remove [patch_name]
#   patches.sh reapply
#
# Default tree:
#   DEVCONTAINER_PATCH_TREE if set
#   else site-packages when DEVCONTAINER_DEV_KIND=service
#   else /repositories/pulpcore
#
# STRICT mode (fail hard on apply errors / missing patch dir):
#   DEVCONTAINER_PATCH_STRICT=1, or default on when DEVCONTAINER_DEV_KIND=service and applying
#   to the default (site-packages) tree. Editable checkout trees stay best-effort.
set -euo pipefail

PATCH_DIR="${DEVCONTAINER_PATCH_DIR:-/opt/pulp-dev/patches}"

if [ -n "${DEVCONTAINER_PATCH_TREE:-}" ]; then
  DEFAULT_TREE="${DEVCONTAINER_PATCH_TREE}"
elif [ "${DEVCONTAINER_DEV_KIND:-}" = "service" ]; then
  DEFAULT_TREE="$(python3 -c 'import site; print(site.getsitepackages()[0])')"
else
  DEFAULT_TREE="/repositories/pulpcore"
fi

# Explicit env wins; otherwise service defaults to strict for the site-packages tree.
if [ -n "${DEVCONTAINER_PATCH_STRICT:-}" ]; then
  STRICT_DEFAULT="${DEVCONTAINER_PATCH_STRICT}"
elif [ "${DEVCONTAINER_DEV_KIND:-}" = "service" ]; then
  STRICT_DEFAULT="1"
else
  STRICT_DEFAULT="0"
fi

usage() {
  echo "Usage: $0 [apply [tree] | remove [patch_name] | reapply]"
  echo "  apply [tree]       Apply all patches (default tree: ${DEFAULT_TREE})"
  echo "  remove             Reverse all patches from ${DEFAULT_TREE}"
  echo "  remove <name>      Reverse one patch (e.g. 0044-....patch)"
  echo "  reapply            Reverse all, then apply to ${DEFAULT_TREE}"
  exit 1
}

MODE="${1:-}"
ARG2="${2:-}"

# GNU patch may exit 1 for already-applied hunks (--forward) or offsets/fuzz.
# Fail only on hard errors / rejects when STRICT=1.
apply_one() {
  local patch_file="$1"
  local tree="$2"
  local strict="$3"
  local name out status
  name="$(basename "$patch_file")"
  echo "Applying ${name} -> ${tree}"
  status=0
  out="$(patch -p1 --forward --no-backup-if-mismatch --batch -d "$tree" < "$patch_file" 2>&1)" || status=$?
  printf '%s\n' "$out"

  if find "$tree" -name '*.rej' -print -quit 2>/dev/null | grep -q .; then
    echo "ERROR: reject files left after ${name}" >&2
    find "$tree" -name '*.rej' -print >&2 || true
    return 1
  fi

  if [ "$status" -eq 0 ]; then
    return 0
  fi

  if printf '%s\n' "$out" | grep -Eqi 'Skipping patch|previously applied|Reversed \(or previously applied\)'; then
    echo "NOTE: ${name} already applied (ignored)"
    return 0
  fi

  if printf '%s\n' "$out" | grep -Eq 'succeeded at|patching file' \
     && ! printf '%s\n' "$out" | grep -Eqi "FAILED|REJECTED|ignoring|can't find file|No file to patch"; then
    echo "NOTE: ${name} applied with offset/fuzz (exit ${status})"
    return 0
  fi

  if [ "$strict" = "1" ]; then
    echo "ERROR: failed to apply ${name} (exit ${status})" >&2
    return 1
  fi

  echo "NOTE: ${name} skipped (exit ${status})"
  return 0
}

do_apply() {
  local tree="${1:-$DEFAULT_TREE}"
  local strict="${STRICT_DEFAULT}"
  # Editable checkouts under service: only some patches target that package.
  if [ "${DEVCONTAINER_DEV_KIND:-}" = "service" ] && [ "$tree" != "$DEFAULT_TREE" ]; then
    strict="0"
  fi

  if [ ! -d "$PATCH_DIR" ]; then
    if [ "$strict" = "1" ]; then
      echo "ERROR: patch directory not found: ${PATCH_DIR}" >&2
      exit 1
    fi
    echo "NOTE: patch directory not found: ${PATCH_DIR} (skipping)"
    return 0
  fi

  shopt -s nullglob
  local patches=("$PATCH_DIR"/*.patch)
  if [ ${#patches[@]} -eq 0 ]; then
    if [ "$strict" = "1" ]; then
      echo "ERROR: no .patch files in ${PATCH_DIR}" >&2
      exit 1
    fi
    echo "NOTE: no .patch files in ${PATCH_DIR} (skipping)"
    return 0
  fi

  echo "==> Applying patches from ${PATCH_DIR} to ${tree}..."
  local failed=0
  local patch_file
  for patch_file in "${patches[@]}"; do
    if ! apply_one "$patch_file" "$tree" "$strict"; then
      failed=1
    fi
  done

  if [ "$failed" -ne 0 ]; then
    exit 1
  fi
  echo "Patch pass complete for ${tree}"
}

do_remove() {
  local tree="$DEFAULT_TREE"
  shopt -s nullglob
  if [ -n "$ARG2" ]; then
    local f="${PATCH_DIR}/${ARG2}"
    if [ ! -f "$f" ]; then
      echo "ERROR: patch not found: ${f}" >&2
      exit 1
    fi
    echo "==> Reversing patch: ${ARG2}"
    if [ "${STRICT_DEFAULT}" = "1" ]; then
      patch -R -p1 --forward --no-backup-if-mismatch --batch -d "$tree" < "$f"
    else
      patch -R -p1 --forward --no-backup-if-mismatch --batch -d "$tree" < "$f" || true
    fi
  else
    echo "==> Reversing all patches (reverse order)..."
    local patches=("$PATCH_DIR"/*.patch)
    local i
    for ((i=${#patches[@]}-1; i>=0; i--)); do
      local p="${patches[$i]}"
      echo "Reversing $(basename "$p")"
      patch -R -p1 --forward --no-backup-if-mismatch --batch -d "$tree" < "$p" || true
    done
  fi
}

do_reapply() {
  ARG2=""
  do_remove
  do_apply "$DEFAULT_TREE"
  echo "==> Patches reapplied. Restart Pulp processes (pkill / pulp-services)."
}

case "$MODE" in
  apply)
    if [ -n "$ARG2" ]; then
      do_apply "$ARG2"
    else
      do_apply "$DEFAULT_TREE"
    fi
    ;;
  remove)  do_remove ;;
  reapply) do_reapply ;;
  *)       usage ;;
esac
