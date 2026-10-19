#!/usr/bin/env bash
# Verify that the top-level flake declares every input the base flake declares.
# Base modules reference `inputs.<name>`, which resolves against the top-level
# flake's inputs, so a missing declaration fails evaluation.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NIX_DIR="${MY_NIX_DIR:-$SCRIPT_DIR/../../..}"

base_flake="${NIX_DIR}/base/flake.nix"
top_flake="${NIX_DIR}/flake.nix"

# Nothing to compare when running inside base itself.
[[ -f "${base_flake}" && -f "${top_flake}" ]] || exit 0

input_names() {
  nix eval --impure --raw --expr \
    "builtins.concatStringsSep \"\\n\" (builtins.filter (n: n != \"self\") (builtins.attrNames (import $1).inputs))"
}

missing="$(comm -23 <(input_names "${base_flake}" | sort) <(input_names "${top_flake}" | sort))"

if [[ -n "${missing}" ]]; then
  echo "❌ ${top_flake} is missing inputs declared by base/flake.nix:" >&2
  sed 's/^/  - /' <<<"${missing}" >&2
  echo "  Copy their declarations (including any 'follows') from base/flake.nix, then re-run." >&2
  exit 1
fi
