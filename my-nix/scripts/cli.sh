#!/usr/bin/env bash
set -euo pipefail

# MY_NIX_DIR is set by the Nix module that installs this script.
# Fall back to the directory containing this script if unset.
NIX_DIR="${MY_NIX_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/..}"

usage() {
  cat <<'EOF'
Usage:
  my-nix apply
  my-nix upgrade [args...]
  my-nix cleanup
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

cmd="${1:-}"
shift || true

case "${cmd}" in
apply)
  exec sudo darwin-rebuild switch --flake "${NIX_DIR}"
  ;;

upgrade)
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  update_script="${MY_NIX_DIR:+${MY_NIX_DIR}/base/my-nix/scripts/update.sh}"
  update_script="${update_script:-${SCRIPT_DIR}/update.sh}"

  if [[ -x "${update_script}" ]]; then
    exec "${update_script}" "$@"
  else
    die "No upgrade script found at: ${update_script}"
  fi
  ;;

cleanup)
  echo "Cleaning up Nix (keeping last 5 generations)..."

  echo "-> Deleting old generations (keep 5)"
  nix-env --delete-generations +5

  echo "-> Garbage collecting unreferenced store paths"
  nix-store --gc

  echo "-> Optimizing store (hardlink duplicates)"
  nix-store --optimise

  echo "Cleanup complete"
  ;;

"" | -h | --help | help)
  usage
  ;;

*)
  die "Unknown command: ${cmd}"
  ;;
esac
