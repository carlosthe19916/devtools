#!/usr/bin/env bash
# Apply / reverse RH overlays from pulp-service/images/assets/patches.
#
# Usage:
#   patches.sh apply [tree]
#   patches.sh remove [patch_name]
#   patches.sh reapply
#
# Default tree is site-packages (fail-hard on rejects).
# Pass a checkout path (e.g. /repositories/pulpcore) for best-effort editable overlay.
set -euo pipefail

PATCH_DIR="${PULP_PATCH_DIR:-/workspace/images/assets/patches}"
DEFAULT_TREE="$(python3 -c 'import site; print(site.getsitepackages()[0])')"

usage() {
  echo "Usage: $0 [apply [tree] | remove [patch_name] | reapply]"
  echo "  apply [tree]       Apply all patches (default tree: site-packages)"
  echo "  remove             Reverse all patches from site-packages"
  echo "  remove <name>      Reverse one patch (e.g. 0061-....patch)"
  echo "  reapply            Reverse all, then apply to site-packages"
  exit 1
}

MODE="${1:-}"
ARG2="${2:-}"

# GNU patch may exit 1 for already-applied hunks (--forward) or offsets/fuzz.
# Fail only on hard errors / rejects when STRICT=1 (site-packages default).
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

  echo "NOTE: ${name} skipped on editable tree (exit ${status})"
  return 0
}

do_apply() {
  local tree="${1:-$DEFAULT_TREE}"
  local strict="1"
  if [ "$tree" != "$DEFAULT_TREE" ]; then
    # Editable checkouts: only some patches target that package; others no-op.
    strict="0"
  fi

  if [ ! -d "$PATCH_DIR" ]; then
    echo "ERROR: patch directory not found: ${PATCH_DIR}" >&2
    exit 1
  fi

  shopt -s nullglob
  local patches=("$PATCH_DIR"/*.patch)
  if [ ${#patches[@]} -eq 0 ]; then
    echo "ERROR: no .patch files in ${PATCH_DIR}" >&2
    exit 1
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
  echo "All patches applied to ${tree}"
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
    patch -R -p1 --forward --no-backup-if-mismatch --batch -d "$tree" < "$f"
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
