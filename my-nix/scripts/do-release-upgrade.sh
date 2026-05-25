#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NIX_DIR="${MY_NIX_DIR:-${SCRIPT_DIR}/..}"

AUTO_YES=0
UPDATE_ARGS=()

usage() {
  cat <<'EOF'
Usage: ./do-release-upgrade.sh [--yes] [upgrade args...]

Bumps nixpkgs + Home Manager to the newest release train,
then runs the regular my-nix upgrade flow.
EOF
}

current_flake_release() {
  local file_path="$1"
  local input_name="$2"

  grep -E "^[[:space:]]*${input_name}\\.url = \\\"github:[^\\\"]+/[^\\\"]+/[^\\\"]+\\\";" "$file_path" 2>/dev/null \
    | head -n 1 \
    | sed -E 's#.*github:[^/]+/[^/]+/([^"]+)";#\1#' \
    || true
}

latest_github_branch() {
  local repo_slug="$1"
  local branch_prefix="$2"

  { git ls-remote --heads "https://github.com/${repo_slug}.git" "refs/heads/${branch_prefix}-*" 2>/dev/null || true; } \
    | awk '{print $2}' \
    | sed -E 's#refs/heads/##' \
    | sort -V \
    | tail -n 1
}

bump_in_file() {
  local file_path="$1"
  local nixpkgs_release="$2"
  local home_manager_release="$3"

  perl -0pi -e "s#github:NixOS/nixpkgs/[^\"]+#github:NixOS/nixpkgs/${nixpkgs_release}#g; s#github:nix-community/home-manager/[^\"]+#github:nix-community/home-manager/${home_manager_release}#g" "$file_path"
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
      UPDATE_ARGS+=("$1")
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      UPDATE_ARGS+=("$1")
      shift
      ;;
  esac
done

[[ -f "${NIX_DIR}/flake.nix" ]] || {
  echo "❌ flake.nix not found in ${NIX_DIR}"
  exit 1
}

current_nixpkgs="$(current_flake_release "${NIX_DIR}/flake.nix" nixpkgs)"
current_home_manager="$(current_flake_release "${NIX_DIR}/flake.nix" home-manager)"
latest_nixpkgs="$(latest_github_branch "NixOS/nixpkgs" "nixos")"
latest_home_manager="$(latest_github_branch "nix-community/home-manager" "release")"

if [[ -z "${latest_nixpkgs}" || -z "${latest_home_manager}" ]]; then
  echo "❌ Could not determine latest release branches."
  exit 1
fi

if [[ "${current_nixpkgs}" == "${latest_nixpkgs}" && "${current_home_manager}" == "${latest_home_manager}" ]]; then
  echo "✅ Already on the latest release train."
  exit 0
fi

echo "📣 Release train bump:"
[[ "${current_nixpkgs}" != "${latest_nixpkgs}" ]] && echo "  - Nixpkgs: ${current_nixpkgs} -> ${latest_nixpkgs}"
[[ "${current_home_manager}" != "${latest_home_manager}" ]] && echo "  - Home Manager: ${current_home_manager} -> ${latest_home_manager}"

if [[ "${AUTO_YES}" -ne 1 ]]; then
  echo
  read -r -p "Proceed with the release bump? [y/N] " yn || true
  case "$yn" in
    [Yy]*) ;;
    *)
      echo "❌ Aborted. Nothing changed."
      exit 0
      ;;
  esac
fi

pull_submodules

bump_in_file "${NIX_DIR}/flake.nix" "${latest_nixpkgs}" "${latest_home_manager}"
bump_in_file "${NIX_DIR}/base/flake.nix" "${latest_nixpkgs}" "${latest_home_manager}"

echo
echo "🔄 Refreshing release lockfiles…"
nix flake update --flake "${NIX_DIR}" >/dev/null
nix flake update --flake "${NIX_DIR}/base" >/dev/null

exec "${SCRIPT_DIR}/update.sh" --skip-pull "${UPDATE_ARGS[@]}"
