#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NIX_DIR="${MY_NIX_DIR:-${SCRIPT_DIR}/..}"

AUTO_YES=0
TARGET=""
UPDATE_ARGS=()

usage() {
  cat <<'EOF'
Usage: ./do-release-upgrade.sh [--yes] <release|latest> [upgrade args...]

Examples:
  my-nix do-release-upgrade 26.05
  my-nix do-release-upgrade latest
EOF
}

current_flake_release() {
  local file_path="$1"
  local input_name="$2"
  local release

  release="$(
    grep -E "^[[:space:]]*${input_name}\\.url = \"github:[^\"]+/[^\"]+/[^\"]+\";" "$file_path" 2>/dev/null \
      | head -n 1 \
      | sed -E 's#.*github:[^/]+/[^/]+/([^\"]+)";#\1#' \
      || true
  )"

  printf '%s\n' "${release}"
}

is_release_name() {
  [[ "$1" =~ ^[0-9]{2}\.[0-9]{2}$ ]]
}

target_urls() {
  local target="$1"
  if [[ "$target" == "latest" ]]; then
    printf '%s\n%s\n' \
      'github:NixOS/nixpkgs' \
      'github:nix-community/home-manager'
  else
    printf '%s\n%s\n' \
      "github:NixOS/nixpkgs/nixos-${target}" \
      "github:nix-community/home-manager/release-${target}"
  fi
}

bump_in_file() {
  local file_path="$1"
  local nixpkgs_url="$2"
  local home_manager_url="$3"

  perl -0pi -e "s#github:NixOS/nixpkgs(?:/[^\"]+)?#${nixpkgs_url}#g; s#github:nix-community/home-manager(?:/[^\"]+)?#${home_manager_url}#g" "$file_path"
}

pull_submodules() {
  echo "🔄 Pulling nvim submodule…"
  git -C "${NIX_DIR}/base/modules/editor/nvim" pull --rebase

  echo ""
  echo "🔄 Pulling base submodule…"
  git -C "${NIX_DIR}/base" pull --rebase
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --yes)
    AUTO_YES=1
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    if [[ -z "${TARGET}" ]]; then
      TARGET="$1"
    else
      UPDATE_ARGS+=("$1")
    fi
    shift
    ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  usage
  exit 2
fi

if [[ "${TARGET}" != "latest" ]] && ! is_release_name "${TARGET}"; then
  echo "❌ Invalid target: ${TARGET}"
  echo "   Use NN.NN (for example 26.05) or 'latest'."
  exit 2
fi

[[ -f "${NIX_DIR}/flake.nix" ]] || {
  echo "❌ flake.nix not found in ${NIX_DIR}"
  exit 1
}

current_nixpkgs="$(current_flake_release "${NIX_DIR}/flake.nix" nixpkgs)"
current_home_manager="$(current_flake_release "${NIX_DIR}/flake.nix" home-manager)"
{
  read -r nixpkgs_url
  read -r home_manager_url
} < <(target_urls "${TARGET}")

if [[ "${TARGET}" != "latest" ]]; then
  desired_nixpkgs="nixos-${TARGET}"
  desired_home_manager="release-${TARGET}"

  if [[ "${current_nixpkgs}" == "${desired_nixpkgs}" && "${current_home_manager}" == "${desired_home_manager}" ]]; then
    echo "✅ Already on ${TARGET}."
    exit 0
  fi
fi

echo "📣 Release upgrade target: ${TARGET}"
if [[ "${TARGET}" == "latest" ]]; then
  echo "  - Nixpkgs: ${current_nixpkgs:-branchless} -> latest commit"
  echo "  - Home Manager: ${current_home_manager:-branchless} -> latest commit"
else
  echo "  - Nixpkgs: ${current_nixpkgs:-branchless} -> nixos-${TARGET}"
  echo "  - Home Manager: ${current_home_manager:-branchless} -> release-${TARGET}"
fi

if [[ "${AUTO_YES}" -ne 1 ]]; then
  echo
  read -r -p "Proceed with the release upgrade? [y/N] " yn || true
  case "$yn" in
  [Yy]*) ;;
  *)
    echo "❌ Aborted. Nothing changed."
    exit 0
    ;;
  esac
fi

pull_submodules

bump_in_file "${NIX_DIR}/flake.nix" "${nixpkgs_url}" "${home_manager_url}"
bump_in_file "${NIX_DIR}/base/flake.nix" "${nixpkgs_url}" "${home_manager_url}"

echo
echo "🔄 Refreshing release lockfiles…"
nix flake update --flake "${NIX_DIR}" >/dev/null
nix flake update --flake "${NIX_DIR}/base" >/dev/null

exec "${SCRIPT_DIR}/update.sh" --skip-pull "${UPDATE_ARGS[@]}"
