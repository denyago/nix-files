#!/usr/bin/env bash
# Run a build command and, when it fails because a fixed-output derivation's
# pinned hash is stale, rewrite that hash in the nix sources and retry.
#
# Covers every hash that nvfetcher can't track: pnpmDeps.hash, cargoHash,
# vendorHash, npmDepsHash, ... Nix reports them uniformly as
#
#   error: hash mismatch in fixed-output derivation '/nix/store/...-foo.drv':
#            specified: sha256-<old>
#               got:    sha256-<new>
#
# so no per-package registry is needed. Requirement for packages: the hash
# must be written literally in a .nix file, and the FOD's name must change when
# the source version does (cargoDeps/goModules/npmDeps do; for fetchPnpmDeps
# pass `pname = "${pname}-${version}"`). Otherwise nix reuses the old FOD output
# from the store and never reports a mismatch.
#
# Usage: build-fix-hashes.sh <build command...>
#   e.g. build-fix-hashes.sh darwin-rebuild build --flake .
set -euo pipefail

[[ $# -gt 0 ]] || {
  echo "Usage: $0 <build command...>" >&2
  exit 2
}

NIX_DIR="${MY_NIX_DIR:-$PWD}"
MAX_ATTEMPTS=8

log="$(mktemp)"
trap 'rm -f "${log}"' EXIT

# Print "<old> <new> <derivation>" for every hash mismatch in the build log.
parse_mismatches() {
  awk '
    /hash mismatch in fixed-output derivation/ {
      drv = $0
      sub(/.*derivation .\/nix\/store\/[a-z0-9]+-/, "", drv)
      sub(/\.drv.*/, "", drv)
    }
    /^[[:space:]]*specified:/ { old = $2 }
    /^[[:space:]]*got:/ {
      if (old != "") { print old, $2, drv }
      old = ""
    }
  ' "$1" | sort -u
}

# Rewrite stale hashes found in the log. Returns 0 if at least one was fixed.
fix_hashes() {
  local fixed=0 old new drv
  local -a files

  while read -r old new drv; do
    [[ -n "${old}" ]] || continue

    # _sources/ is nvfetcher output (source hashes), never edited by hand.
    files=()
    while IFS= read -r f; do
      files+=("${f}")
    done < <(grep -rlF --include='*.nix' --exclude-dir=.git --exclude-dir=_sources -- "${old}" "${NIX_DIR}" || true)

    if [[ "${#files[@]}" -ne 1 ]] || [[ "$(grep -cF -- "${old}" "${files[0]}")" -ne 1 ]]; then
      echo "❌ ${drv}: stale hash ${old} must appear exactly once in the nix sources; found in: ${files[*]:-(nowhere)}" >&2
      echo "   Expected hash: ${new}" >&2
      return 1
    fi

    OLD="${old}" NEW="${new}" perl -pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/' "${files[0]}"
    echo "🔧 ${drv}: updated hash in ${files[0]#"${NIX_DIR}"/}"
    echo "   ${old} -> ${new}"
    fixed=1
  done < <(parse_mismatches "${log}")

  [[ "${fixed}" -eq 1 ]]
}

for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
  set +e
  "$@" 2>&1 | tee "${log}"
  status="${PIPESTATUS[0]}"
  set -e

  [[ "${status}" -eq 0 ]] && exit 0

  # Not a hash problem (or one we can't fix): surface the original failure.
  fix_hashes || exit "${status}"

  echo
  echo "🔁 Retrying build with updated hashes (attempt $((attempt + 1))/${MAX_ATTEMPTS})…"
done

echo "❌ Build still failing after ${MAX_ATTEMPTS} attempts." >&2
exit 1
