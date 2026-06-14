#!/usr/bin/env bash
set -euo pipefail

DO_BREW=1
AUTO_YES=0
DO_SWITCH=1
DO_PULL=1
BREW_BIN=""
FLAKE_UPDATE_OUTPUT=""
FLAKE_LOCK_BEFORE=""

usage() {
  cat <<'EOF'
Usage: ./update.sh [options]

Options:
  --no-brew      Skip Homebrew update/preview/upgrade.
  --yes          Non-interactive: apply changes without prompting.
  --build-only   Update + build + show previews, but do not apply.
  --skip-pull    Internal: skip submodule pull step.
  -h, --help     Show help.
EOF
}

resolve_brew() {
  local prefix

  [[ -n "${MY_NIX_HOSTNAME:-}" ]] || return 1

  prefix="$(nix eval --raw "${NIX_DIR}#darwinConfigurations.${MY_NIX_HOSTNAME}.config.homebrew.prefix" 2>/dev/null || true)"
  [[ -n "${prefix}" && -x "${prefix}/bin/brew" ]] || return 1

  BREW_BIN="${prefix}/bin/brew"
}

current_flake_release() {
  local file_path="$1"
  local input_name="$2"
  local release

  release="$(
    grep -E "^[[:space:]]*${input_name}\.url = \"github:[^\"]+/[^\"]+/[^\"]+\";" "$file_path" 2>/dev/null \
      | head -n 1 \
      | sed -E 's#.*github:[^/]+/[^/]+/([^\"]+)";#\1#' \
      || true
  )"

  printf '%s\n' "${release}"
}

latest_github_branch() {
  local repo_slug="$1"
  local branch_prefix="$2"

  { git ls-remote --heads "https://github.com/${repo_slug}.git" 2>/dev/null || true; } \
    | awk -v prefix="${branch_prefix}" '$2 ~ "^refs/heads/" prefix "-[0-9][0-9]\\.[0-9][0-9]$" { print $2 }' \
    | sed -E 's#refs/heads/##' \
    | sort -V \
    | tail -n 1
}

propose_release_bump() {
  local label="$1"
  local file_path="$2"
  local input_name="$3"
  local repo_slug="$4"
  local branch_prefix="$5"
  local current_release
  local latest_release

  current_release="$(current_flake_release "$file_path" "$input_name")"
  [[ -n "${current_release}" ]] || return 0

  latest_release="$(latest_github_branch "$repo_slug" "$branch_prefix")"
  [[ -n "${latest_release}" ]] || return 0

  if [[ "$(printf '%s\n%s\n' "${current_release}" "${latest_release}" | sort -V | tail -n 1)" != "${current_release}" ]]; then
    echo "  - ${label}: ${current_release} -> ${latest_release}"
  fi
}

summarize_release_bumps() {
  local proposals=()
  local line

  while IFS= read -r line; do
    proposals+=("${line}")
  done < <(
    propose_release_bump "Nixpkgs release" "flake.nix" "nixpkgs" "NixOS/nixpkgs" "nixos"
    propose_release_bump "nix-darwin release" "flake.nix" "nix-darwin" "nix-darwin/nix-darwin" "nix-darwin"
    propose_release_bump "Home Manager release" "flake.nix" "home-manager" "nix-community/home-manager" "release"
  )

  if [[ "${#proposals[@]}" -gt 0 ]]; then
    echo
    echo "📣 Proposed release train bumps:"
    printf '%s\n' "${proposals[@]}"
  fi
}

update_flake() {
  local github_token
  local flake_update_output
  local lockfile_before

  lockfile_before="$(mktemp)"
  cp flake.lock "${lockfile_before}"
  FLAKE_LOCK_BEFORE="${lockfile_before}"

  if command -v gh >/dev/null && github_token="$(gh auth token 2>/dev/null)" && [[ -n "${github_token}" ]]; then
    echo "  → using GitHub token from gh auth"
    flake_update_output="$(NIX_CONFIG="${NIX_CONFIG:+${NIX_CONFIG}$'\n'}access-tokens = github.com=${github_token}" nix flake update 2>&1)"
  else
    flake_update_output="$(nix flake update 2>&1)"
  fi

  FLAKE_UPDATE_OUTPUT="${flake_update_output}"
  printf '%s\n' "${flake_update_output}"
}

summarize_flake_updates() {
  local diff_output
  local proposed=()

  diff_output="$(git diff --no-index --unified=0 -- "${FLAKE_LOCK_BEFORE}" flake.lock 2>/dev/null || true)"

  if grep -q '"nixpkgs"' <<< "${diff_output}"; then
    proposed+=("Nixpkgs package set")
  fi
  if grep -q '"nix-darwin"' <<< "${diff_output}"; then
    proposed+=("nix-darwin release")
  fi
  if grep -q '"home-manager"' <<< "${diff_output}"; then
    proposed+=("Home Manager release")
  fi

  if [[ "${#proposed[@]}" -gt 0 ]]; then
    echo
    echo "📣 Proposed release updates:"
    for line in "${proposed[@]}"; do
      echo "  - ${line}"
    done
    echo "  Use my-nix do-release-upgrade <release|latest> to apply a release train bump."
  fi

  rm -f "${FLAKE_LOCK_BEFORE}"
  FLAKE_LOCK_BEFORE=""
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-brew)
    DO_BREW=0
    shift
    ;;
  --yes)
    AUTO_YES=1
    shift
    ;;
  --build-only)
    DO_SWITCH=0
    shift
    ;;
  --skip-pull)
    DO_PULL=0
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    usage
    exit 2
    ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NIX_DIR="${MY_NIX_DIR:-$SCRIPT_DIR/..}"
cd "${NIX_DIR}"

[[ -f flake.nix ]] || {
  echo "❌ flake.nix not found in $NIX_DIR"
  exit 1
}
command -v nix >/dev/null || {
  echo "❌ nix not found"
  exit 1
}
command -v darwin-rebuild >/dev/null || {
  echo "❌ darwin-rebuild not found"
  exit 1
}

if [[ "$DO_PULL" -eq 1 ]]; then
  echo "🔄 Pulling nvim submodule…"
  git -C "${NIX_DIR}/base/modules/editor/nvim" pull --rebase

  echo ""
  echo "🔄 Pulling base submodule…"
  git -C "${NIX_DIR}/base" pull --rebase
else
  echo "🔄 Skipping submodule pulls (handled by release upgrade)…"
fi

echo ""
echo "🔄 Updating flake inputs (flake.lock)…"
summarize_release_bumps
update_flake
summarize_flake_updates

echo ""
echo "🔄 Updating nvfetcher sources…"
find "${NIX_DIR}" -name "nvfetcher.toml" | while read -r toml; do
  dir="$(dirname "$toml")"
  echo "  → $toml"
  nvfetcher -c "$toml" -o "${dir}/_sources"
done

echo
echo "🔨 Building new system (no activation)…"
darwin-rebuild build --flake .

NIX_CHANGED=0
if [[ "$(realpath /run/current-system)" != "$(realpath ./result)" ]]; then
  NIX_CHANGED=1
fi

echo
echo "📦 Nix changes (current -> ./result):"
if [[ "$NIX_CHANGED" -eq 1 ]]; then
  # nvd sometimes returns non-zero depending on differences; don't fail the script on preview
  nix run nixpkgs#nvd -- diff /run/current-system ./result || true
else
  echo "(none)"
fi

BREW_OUTDATED_FORMULAE=""
BREW_OUTDATED_CASKS=""
if [[ "$DO_BREW" -eq 1 ]]; then
  if resolve_brew; then
    echo
    echo "🍺 Homebrew: updating taps/formula metadata with ${BREW_BIN}…"
    "${BREW_BIN}" update

    echo
    echo "📦 Homebrew pending upgrades (formulae):"
    # --verbose prints "foo (old) < new" style when available
    BREW_OUTDATED_FORMULAE="$("${BREW_BIN}" outdated --verbose || true)"
    BREW_OUTDATED_CASKS="$("${BREW_BIN}" outdated --cask --verbose || true)"
    if [[ -n "${BREW_OUTDATED_FORMULAE}" || -n "${BREW_OUTDATED_CASKS}" ]]; then
      echo "📣 Proposed Homebrew updates:"
    fi
    if [[ -n "$BREW_OUTDATED_FORMULAE" ]]; then
      echo "  Formulae:"
      echo "$BREW_OUTDATED_FORMULAE"
    else
      echo "  Formulae: (none)"
    fi

    if [[ -n "${BREW_OUTDATED_CASKS}" ]]; then
      echo "  Casks:"
      echo "${BREW_OUTDATED_CASKS}"
    else
      echo "  Casks: (none)"
    fi
  else
    echo
    echo "⚠️  Nix-selected brew not found; skipping Homebrew preview/upgrade."
    DO_BREW=0
  fi
fi

echo
if [[ "$DO_SWITCH" -eq 0 ]]; then
  echo "✅ Build-only complete. No changes applied."
  exit 0
fi

if [[ "$NIX_CHANGED" -eq 0 && ( "$DO_BREW" -eq 0 || ( -z "$BREW_OUTDATED_FORMULAE" && -z "$BREW_OUTDATED_CASKS" ) ) ]]; then
  echo "✅ Nothing to do — Nix and Homebrew are up to date."
  exit 0
fi
if [[ "$NIX_CHANGED" -eq 0 && ( -n "$BREW_OUTDATED_FORMULAE" || -n "$BREW_OUTDATED_CASKS" ) ]]; then
  echo "ℹ️  No Nix changes — will only apply Homebrew upgrades."
fi

apply() {
  if [[ "$DO_BREW" -eq 1 && ( -n "$BREW_OUTDATED_FORMULAE" || -n "$BREW_OUTDATED_CASKS" ) ]]; then
    echo
    echo "⬆️  Applying Homebrew upgrades…"
    "${BREW_BIN}" upgrade || true
    echo "🧹 Cleaning up Homebrew…"
    "${BREW_BIN}" cleanup || true
  fi

  if [[ "$NIX_CHANGED" -eq 1 ]]; then
    echo
    echo "🚀 Applying nix-darwin switch…"
    sudo darwin-rebuild switch --flake .
  fi
}

if [[ "$AUTO_YES" -eq 1 ]]; then
  apply
else
  if [[ "$NIX_CHANGED" -eq 1 && "$DO_BREW" -eq 1 && ( -n "$BREW_OUTDATED_FORMULAE" || -n "$BREW_OUTDATED_CASKS" ) ]]; then
    prompt="🚀 Apply proposed Nix and Homebrew updates? [y/N] "
  elif [[ "$NIX_CHANGED" -eq 1 ]]; then
    prompt="🚀 Apply proposed Nix updates? [y/N] "
  else
    prompt="🚀 Apply proposed Homebrew updates? [y/N] "
  fi
  read -r -p "$prompt" yn || true
  case "$yn" in
  [Yy]*) apply ;;
  *)
    echo "❌ Aborted. Nothing applied."
    exit 0
    ;;
  esac
fi

commit_script="${NIX_DIR}/base/my-nix/scripts/commit.sh"
if [[ -x "${commit_script}" ]]; then
  # shellcheck disable=SC1090
  source "${commit_script}"
fi

echo
echo "✅ Done."
