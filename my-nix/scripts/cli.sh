#!/usr/bin/env bash
set -euo pipefail

# MY_NIX_DIR is set by the Nix module that installs this script.
# Fall back to the directory containing this script if unset.
NIX_DIR="${MY_NIX_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/..}"

usage() {
  cat <<'EOF'
Usage:
  my-nix apply
  my-nix commit
  my-nix upgrade [args...]
  my-nix do-release-upgrade [args...]
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
  sudo darwin-rebuild switch --flake "${NIX_DIR}"
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  commit_script="${MY_NIX_DIR:+${MY_NIX_DIR}/base/my-nix/scripts/commit.sh}"
  commit_script="${commit_script:-${SCRIPT_DIR}/commit.sh}"
  if [[ -x "${commit_script}" ]]; then
    # shellcheck disable=SC1090
    source "${commit_script}"
  fi
  ;;

commit)
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  commit_script="${MY_NIX_DIR:+${MY_NIX_DIR}/base/my-nix/scripts/commit.sh}"
  commit_script="${commit_script:-${SCRIPT_DIR}/commit.sh}"
  if [[ -x "${commit_script}" ]]; then
    # shellcheck disable=SC1090
    source "${commit_script}"
  else
    die "No commit script found at: ${commit_script}"
  fi
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

do-release-upgrade)
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  release_upgrade_script="${MY_NIX_DIR:+${MY_NIX_DIR}/base/my-nix/scripts/do-release-upgrade.sh}"
  release_upgrade_script="${release_upgrade_script:-${SCRIPT_DIR}/do-release-upgrade.sh}"

  if [[ -x "${release_upgrade_script}" ]]; then
    exec "${release_upgrade_script}" "$@"
  else
    die "No release-upgrade script found at: ${release_upgrade_script}"
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
