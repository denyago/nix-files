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
  my-nix do-release-upgrade <release|latest> [args...]
  my-nix audit [--init] [--min-score N] <path>
  my-nix cleanup [--keep N | --all]
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

  if [[ -f "${release_upgrade_script}" ]]; then
    exec bash "${release_upgrade_script}" "$@"
  else
    die "No release-upgrade script found at: ${release_upgrade_script}"
  fi
  ;;

audit)
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  audit_script="${MY_NIX_DIR:+${MY_NIX_DIR}/base/my-nix/scripts/audit.sh}"
  audit_script="${audit_script:-${SCRIPT_DIR}/audit.sh}"
  if [[ -x "${audit_script}" ]]; then
    exec "${audit_script}" "$@"
  else
    die "No audit script found at: ${audit_script}"
  fi
  ;;

cleanup)
  keep=5
  delete_all=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --keep)
        [[ -n "${2:-}" && "${2}" =~ ^[0-9]+$ ]] || die "--keep requires a positive integer"
        keep="$2"
        shift 2
        ;;
      --all)
        delete_all=true
        shift
        ;;
      *)
        die "Unknown cleanup option: $1"
        ;;
    esac
  done

  if [[ "${delete_all}" == true ]]; then
    echo "Cleaning up Nix (deleting all old generations)..."
    echo "-> Deleting all generations except current"
    nix-env --delete-generations old
  else
    echo "Cleaning up Nix (keeping last ${keep} generations)..."
    echo "-> Deleting old generations (keep ${keep})"
    nix-env --delete-generations "+${keep}"
  fi

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
