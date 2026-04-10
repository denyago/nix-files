#!/usr/bin/env bash
set -euo pipefail

DO_BREW=1
AUTO_YES=0
DO_SWITCH=1

usage() {
  cat <<'EOF'
Usage: ./update.sh [options]

Options:
  --no-brew      Skip Homebrew update/preview/upgrade.
  --yes          Non-interactive: apply changes without prompting.
  --build-only   Update + build + show previews, but do not apply.
  -h, --help     Show help.
EOF
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

echo "🔄 Pulling nvim submodule…"
git -C "${NIX_DIR}/base/modules/editor/nvim" pull --rebase

echo ""
echo "🔄 Pulling base submodule…"
git -C "${NIX_DIR}/base" pull --rebase

echo ""
echo "🔄 Updating flake inputs (flake.lock)…"
nix flake update

echo
echo "🔨 Building new system (no activation)…"
darwin-rebuild build --flake .

echo
echo "📦 Nix changes (current -> ./result):"
# nvd sometimes returns non-zero depending on differences; don't fail the script on preview
nix run nixpkgs#nvd -- diff /run/current-system ./result || true

BREW_OUTDATED_FORMULAE=""
BREW_OUTDATED_CASKS=""
if [[ "$DO_BREW" -eq 1 ]]; then
  if command -v brew >/dev/null; then
    echo
    echo "🍺 Homebrew: updating taps/formula metadata…"
    brew update

    echo
    echo "📦 Homebrew pending upgrades (formulae):"
    # --verbose prints "foo (old) < new" style when available
    BREW_OUTDATED_FORMULAE="$(brew outdated --verbose || true)"
    if [[ -n "$BREW_OUTDATED_FORMULAE" ]]; then
      echo "$BREW_OUTDATED_FORMULAE"
    else
      echo "(none)"
    fi
  else
    echo
    echo "⚠️  brew not found; skipping Homebrew preview/upgrade."
    DO_BREW=0
  fi
fi

echo
if [[ "$DO_SWITCH" -eq 0 ]]; then
  echo "✅ Build-only complete. No changes applied."
  exit 0
fi

apply() {
  if [[ "$DO_BREW" -eq 1 ]]; then
    echo
    echo "⬆️  Applying Homebrew upgrades…"
    brew upgrade || true
    echo "🧹 Cleaning up Homebrew…"
    brew cleanup || true
  fi

  echo
  echo "🚀 Applying nix-darwin switch…"
  sudo darwin-rebuild switch --flake .
}

if [[ "$AUTO_YES" -eq 1 ]]; then
  apply
else
  read -r -p "🚀 Apply BOTH Homebrew upgrades and nix-darwin switch? [y/N] " yn
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
