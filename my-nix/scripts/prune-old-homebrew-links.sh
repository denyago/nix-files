#!/usr/bin/env bash
set -euo pipefail

APPLY=0
VERBOSE=0
REMOVE_BROKEN_MISSING=0
OLD_PREFIX="/usr/local"
REPORT="${PWD}/obsolete-homebrew-links-missing.tsv"
REMOVED_REPORT="${PWD}/obsolete-homebrew-links-removed.tsv"
NEW_PREFIX=""

usage() {
  cat <<'EOF'
Usage: prune-old-homebrew-links.sh [options]

Scans /usr/local for symlinks that point into an obsolete Intel Homebrew
installation. If a replacement binary/file exists in the active Nix/Homebrew
environment, the symlink can be removed. If no replacement is found, a record
is written to the missing report and the symlink is left in place.

Options:
  --apply              Remove verified obsolete symlinks. Default is dry-run.
  --old-prefix PATH    Old Homebrew prefix to scan. Default: /usr/local
  --new-prefix PATH    Active Homebrew prefix. Default: Nix config or brew --prefix
  --report PATH        Missing replacement report TSV.
  --removed-report PATH
                       Removed symlink report TSV.
  --remove-broken-missing
                       With --apply, also remove obsolete symlinks that have no
                       replacement if their current target is already missing.
  --verbose            Print missing replacements as they are found.
  -h, --help           Show help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --apply)
    APPLY=1
    shift
    ;;
  --old-prefix)
    OLD_PREFIX="$2"
    shift 2
    ;;
  --new-prefix)
    NEW_PREFIX="$2"
    shift 2
    ;;
  --report)
    REPORT="$2"
    shift 2
    ;;
  --removed-report)
    REMOVED_REPORT="$2"
    shift 2
    ;;
  --remove-broken-missing)
    REMOVE_BROKEN_MISSING=1
    shift
    ;;
  --verbose)
    VERBOSE=1
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
  esac
done

path_exists() {
  [[ -e "$1" || -L "$1" ]]
}

detect_new_prefix() {
  local hostname nix_dir prefix

  if [[ -n "${NEW_PREFIX}" ]]; then
    return 0
  fi

  nix_dir="${MY_NIX_DIR:-}"
  hostname="${MY_NIX_HOSTNAME:-}"

  if [[ -z "${nix_dir}" ]]; then
    nix_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
  fi

  if [[ -z "${hostname}" && -f "${nix_dir}/modules/identity.nix" ]]; then
    hostname="$(sed -n 's/^[[:space:]]*hostname[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "${nix_dir}/modules/identity.nix" | head -n 1)"
  fi

  if [[ -n "${hostname}" && -f "${nix_dir}/flake.nix" ]]; then
    prefix="$(nix eval --raw "${nix_dir}#darwinConfigurations.${hostname}.config.homebrew.prefix" 2>/dev/null || true)"
    if [[ -n "${prefix}" && -x "${prefix}/bin/brew" ]]; then
      NEW_PREFIX="${prefix}"
      return 0
    fi
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    NEW_PREFIX="$(/opt/homebrew/bin/brew --prefix)"
    return 0
  fi

  if command -v brew >/dev/null; then
    prefix="$(brew --prefix 2>/dev/null || true)"
    if [[ -n "${prefix}" && "${prefix}" != "${OLD_PREFIX}" ]]; then
      NEW_PREFIX="${prefix}"
      return 0
    fi
  fi

  return 1
}

is_old_homebrew_target() {
  local target="$1"

  case "${target}" in
  "${OLD_PREFIX}/Homebrew"* | "${OLD_PREFIX}/Cellar"* | "${OLD_PREFIX}/Caskroom"*) return 0 ;;
  *"/../Homebrew/"* | *"/../Cellar/"* | *"/../Caskroom/"*) return 0 ;;
  *"/../../Homebrew/"* | *"/../../Cellar/"* | *"/../../Caskroom/"*) return 0 ;;
  *"/../../../Homebrew/"* | *"/../../../Cellar/"* | *"/../../../Caskroom/"*) return 0 ;;
  *"/../../../../Homebrew/"* | *"/../../../../Cellar/"* | *"/../../../../Caskroom/"*) return 0 ;;
  ../Homebrew/* | ../Cellar/* | ../Caskroom/*) return 0 ;;
  ../../Homebrew/* | ../../Cellar/* | ../../Caskroom/*) return 0 ;;
  ../../../Homebrew/* | ../../../Cellar/* | ../../../Caskroom/*) return 0 ;;
  ../../../../Homebrew/* | ../../../../Cellar/* | ../../../../Caskroom/*) return 0 ;;
  *) return 1 ;;
  esac
}

candidate_exists() {
  local candidate

  for candidate in "$@"; do
    if path_exists "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  return 1
}

replacement_for_command() {
  local name="$1"

  candidate_exists \
    "${NEW_PREFIX}/bin/${name}" \
    "${NEW_PREFIX}/sbin/${name}" \
    "/run/current-system/sw/bin/${name}" \
    "/etc/profiles/per-user/${USER}/bin/${name}" \
    "${HOME}/.nix-profile/bin/${name}" \
    "/nix/var/nix/profiles/default/bin/${name}"
}

replacement_from_cellar_target() {
  local target="$1"
  local rest formula version rel candidate

  rest="${target#*Cellar/}"
  [[ "${rest}" != "${target}" ]] || return 1

  formula="${rest%%/*}"
  rest="${rest#*/}"
  version="${rest%%/*}"
  rel="${rest#*/}"

  [[ -n "${formula}" && "${version}" != "${rest}" && -n "${rel}" ]] || return 1

  for candidate in "${NEW_PREFIX}/Cellar/${formula}"/*/"${rel}"; do
    if path_exists "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  candidate_exists \
    "/run/current-system/sw/${rel}" \
    "/etc/profiles/per-user/${USER}/${rel}" \
    "${HOME}/.nix-profile/${rel}" \
    "/nix/var/nix/profiles/default/${rel}"
}

replacement_from_caskroom_target() {
  local target="$1"
  local rest cask version rel candidate

  rest="${target#*Caskroom/}"
  [[ "${rest}" != "${target}" ]] || return 1

  cask="${rest%%/*}"
  rest="${rest#*/}"
  version="${rest%%/*}"
  rel="${rest#*/}"

  [[ -n "${cask}" && "${version}" != "${rest}" && -n "${rel}" ]] || return 1

  for candidate in "${NEW_PREFIX}/Caskroom/${cask}"/*/"${rel}"; do
    if path_exists "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  return 1
}

replacement_for_link() {
  local link="$1"
  local target="$2"
  local name opt_name rel

  name="$(basename -- "${link}")"

  case "${link}" in
  "${OLD_PREFIX}/bin/"* | "${OLD_PREFIX}/sbin/"*)
    replacement_for_command "${name}" && return 0
    ;;
  "${OLD_PREFIX}/opt/"*)
    opt_name="$(basename -- "${link}")"
    candidate_exists "${NEW_PREFIX}/opt/${opt_name}" && return 0
    ;;
  esac

  case "${target}" in
  *Homebrew/bin/*)
    replacement_for_command "${name}" && return 0
    ;;
  *Cellar/*)
    replacement_from_cellar_target "${target}" && return 0
    ;;
  *Caskroom/*)
    replacement_from_caskroom_target "${target}" && return 0
    ;;
  esac

  if [[ "${link}" == "${OLD_PREFIX}/share/"* ]]; then
    rel="share/${link#${OLD_PREFIX}/share/}"
    candidate_exists "${NEW_PREFIX}/${rel}" "/run/current-system/sw/${rel}" "/etc/profiles/per-user/${USER}/${rel}" && return 0
  fi

  return 1
}

scan_dirs() {
  local dir

  for dir in \
    "${OLD_PREFIX}/bin" \
    "${OLD_PREFIX}/sbin" \
    "${OLD_PREFIX}/opt" \
    "${OLD_PREFIX}/share" \
    "${OLD_PREFIX}/lib" \
    "${OLD_PREFIX}/include" \
    "${OLD_PREFIX}/Frameworks"; do
    [[ -d "${dir}" ]] && printf '%s\0' "${dir}"
  done
}

detect_new_prefix || {
  echo "Could not determine active Homebrew prefix. Pass --new-prefix PATH." >&2
  exit 1
}

mkdir -p -- "$(dirname -- "${REPORT}")" "$(dirname -- "${REMOVED_REPORT}")"
printf 'link\ttarget\treason\n' >"${REPORT}"
printf 'link\ttarget\treplacement\n' >"${REMOVED_REPORT}"

checked=0
obsolete=0
verified=0
missing=0
removed=0

while IFS= read -r -d '' dir; do
  while IFS= read -r -d '' link; do
    target="$(readlink -- "${link}")"
    checked=$((checked + 1))

    is_old_homebrew_target "${target}" || continue
    obsolete=$((obsolete + 1))

    if replacement="$(replacement_for_link "${link}" "${target}" 2>/dev/null)"; then
      verified=$((verified + 1))
      printf '%s\t%s\t%s\n' "${link}" "${target}" "${replacement}" >>"${REMOVED_REPORT}"
      if [[ "${APPLY}" -eq 1 ]]; then
        rm -- "${link}"
        removed=$((removed + 1))
        echo "removed: ${link} -> ${target} (replacement: ${replacement})"
      else
        echo "would remove: ${link} -> ${target} (replacement: ${replacement})"
      fi
    else
      missing=$((missing + 1))
      printf '%s\t%s\t%s\n' "${link}" "${target}" "replacement not found" >>"${REPORT}"
      if [[ "${APPLY}" -eq 1 && "${REMOVE_BROKEN_MISSING}" -eq 1 && ! -e "${link}" ]]; then
        rm -- "${link}"
        removed=$((removed + 1))
        echo "removed broken missing: ${link} -> ${target}"
      elif [[ "${VERBOSE}" -eq 1 ]]; then
        echo "kept missing replacement: ${link} -> ${target}"
      fi
    fi
  done < <(find "${dir}" -type l -print0)
done < <(scan_dirs)

echo
echo "Active Homebrew prefix: ${NEW_PREFIX}"
echo "Checked symlinks: ${checked}"
echo "Obsolete Homebrew symlinks: ${obsolete}"
echo "Verified replacements: ${verified}"
echo "Missing replacements: ${missing}"
if [[ "${APPLY}" -eq 1 ]]; then
  echo "Removed symlinks: ${removed}"
else
  echo "Dry-run only. Re-run with --apply to remove verified symlinks."
  echo "Use --apply --remove-broken-missing to also remove obsolete broken symlinks without replacements."
fi
echo "Missing report: ${REPORT}"
echo "Verified/removal report: ${REMOVED_REPORT}"
