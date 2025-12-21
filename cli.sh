#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./cli.sh apply
  ./cli.sh upgrade [args...]
  ./cli.sh dev patch
  ./cli.sh dev push
  ./cli.sh dev merge-upstream
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
  exec sudo darwin-rebuild switch --flake .
  ;;

upgrade)
  if [[ -x "./scripts/update.sh" ]]; then
    exec "./scripts/update.sh" "$@"
  else
    die "No upgrade script found. Expected executable: ./scripts/update.sh"
  fi
  ;;

dev)
  sub="${1:-}"
  shift || true
  case "${sub}" in
  patch)
    # Run this from the upstream-pointing folder. It applies the diff from ~/nix-files.
    exec bash -lc 'git -C ~/nix-files diff | git apply -'
    ;;
  push)
    exec git push origin master
    ;;
  merge-upstream)
    exec bash -lc 'git fetch --all && git merge upstream/master && git submodule update --init --recursive'
    ;;
  "" | -h | --help | help)
    usage
    ;;
  *)
    die "Unknown dev subcommand: ${sub}"
    ;;
  esac
  ;;

"" | -h | --help | help)
  usage
  ;;

*)
  die "Unknown command: ${cmd}"
  ;;
esac
