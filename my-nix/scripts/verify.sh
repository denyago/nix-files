#!/usr/bin/env bash
# Build the system configuration without activating it or creating ./result.
set -euo pipefail

EVAL_ONLY=0

usage() {
  cat <<'EOT'
Usage: my-nix verify [options]

Options:
  --eval-only    Only evaluate the configuration; skip building.
  -h, --help     Show help.
EOT
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --eval-only)
    EVAL_ONLY=1
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
NIX_DIR="${MY_NIX_DIR:-$SCRIPT_DIR/../../..}"
cd "${NIX_DIR}"

[[ -f flake.nix ]] || {
  echo "❌ flake.nix not found in $NIX_DIR"
  exit 1
}
[[ -n "${MY_NIX_HOSTNAME:-}" ]] || {
  echo "❌ MY_NIX_HOSTNAME is not set"
  exit 1
}

echo "🔎 Checking flake inputs…"
"${SCRIPT_DIR}/check-inputs.sh"

attr=".#darwinConfigurations.${MY_NIX_HOSTNAME}.config.system.build.toplevel"

if [[ "$EVAL_ONLY" -eq 1 ]]; then
  echo "🔎 Evaluating ${MY_NIX_HOSTNAME}…"
  nix eval --raw "${attr}.drvPath" >/dev/null
  echo "✅ Evaluation OK."
else
  echo "🔨 Building ${MY_NIX_HOSTNAME} (no activation)…"
  nix build --no-link "${attr}"
  echo "✅ Build OK. Nothing applied."
fi
