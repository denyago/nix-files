#!/usr/bin/env bash
set -euo pipefail

NIX_DIR="${MY_NIX_DIR:?MY_NIX_DIR must be set}"
BASE_CONTRIBUTOR_NAME="${MY_NIX_BASE_CONTRIBUTOR_NAME:-}"
BASE_CONTRIBUTOR_EMAIL="${MY_NIX_BASE_CONTRIBUTOR_EMAIL:-}"
BASE_CONTRIBUTOR_SSH_KEY="${MY_NIX_BASE_CONTRIBUTOR_SSH_KEY:-}"

# Repos to process, inside-out.
declare -a REPO_LABELS=("nvim" "base" "overlay")
declare -a REPO_PATHS=(
  "${NIX_DIR}/base/modules/editor/nvim"
  "${NIX_DIR}/base"
  "${NIX_DIR}"
)
declare -a REPO_DEFAULTS=(
  "Update nvim config"
  "Update base"
  "Update config"
)
# "base" identity for nvim and base; empty for overlay (uses git config)
declare -a REPO_USE_BASE_IDENTITY=(1 1 0)

is_dirty() {
  [[ -n "$(git -C "$1" status --porcelain)" ]]
}

is_detached() {
  [[ "$(git -C "$1" rev-parse --abbrev-ref HEAD)" == "HEAD" ]]
}

has_remote() {
  git -C "$1" remote | grep -q .
}

# Build git command with optional identity override.
# Usage: git_cmd <repo_dir> <use_base_identity> [git args...]
git_cmd() {
  local repo_dir="$1" use_base="$2"
  shift 2
  local -a cmd=(git -C "$repo_dir")
  if [[ "$use_base" -eq 1 && -n "$BASE_CONTRIBUTOR_NAME" && -n "$BASE_CONTRIBUTOR_EMAIL" ]]; then
    cmd+=(-c "user.name=${BASE_CONTRIBUTOR_NAME}" -c "user.email=${BASE_CONTRIBUTOR_EMAIL}")
  fi
  "${cmd[@]}" "$@"
}

# Read a line with a default value.
# Usage: read_default <prompt> <default> <varname>
read_default() {
  local prompt="$1" default="$2" varname="$3"
  read -r -e -p "${prompt} [${default}]: " input
  printf -v "$varname" '%s' "${input:-$default}"
}

process_repo() {
  local label="$1" repo_dir="$2" default_msg="$3" use_base="$4"

  echo ""
  echo "── ${label} (${repo_dir}) ──"

  if ! [[ -d "${repo_dir}/.git" || -f "${repo_dir}/.git" ]]; then
    echo "  Not a git repo — skipping."
    return 0
  fi

  if ! is_dirty "$repo_dir"; then
    echo "  Clean — nothing to commit."
    return 0
  fi

  git -C "$repo_dir" add -A

  if git -C "$repo_dir" diff --cached --quiet; then
    echo "  Nothing staged — skipping."
    return 0
  fi

  echo ""
  git --no-pager -C "$repo_dir" diff --cached --stat
  echo ""

  read -r -p "  Commit changes? [Y/n] " yn
  case "${yn:-y}" in
    [Nn]*)
      git -C "$repo_dir" reset --quiet
      echo "  Skipped."
      return 0
      ;;
  esac

  local msg
  read_default "  Commit message" "$default_msg" msg

  git_cmd "$repo_dir" "$use_base" commit -m "$msg"

  # Offer to push
  if is_detached "$repo_dir"; then
    echo "  ⚠ Detached HEAD — skipping push."
  elif ! has_remote "$repo_dir"; then
    echo "  No remote configured — skipping push."
  else
    read -r -p "  Push? [Y/n] " push_yn
    case "${push_yn:-y}" in
      [Nn]*) echo "  Push skipped." ;;
      *)
        if [[ "$use_base" -eq 1 && -n "$BASE_CONTRIBUTOR_SSH_KEY" ]]; then
          GIT_SSH_COMMAND="ssh -i ${BASE_CONTRIBUTOR_SSH_KEY} -o IdentitiesOnly=yes" \
            git -C "$repo_dir" push
        else
          git -C "$repo_dir" push
        fi
        ;;
    esac
  fi
}

run_commit_flow() {
  if ! [[ -t 0 ]]; then
    echo "Not running in an interactive terminal — skipping commit flow."
    return 0
  fi

  echo ""
  echo "═══ Commit & push ═══"

  local i
  for i in "${!REPO_LABELS[@]}"; do
    process_repo \
      "${REPO_LABELS[$i]}" \
      "${REPO_PATHS[$i]}" \
      "${REPO_DEFAULTS[$i]}" \
      "${REPO_USE_BASE_IDENTITY[$i]}"
  done

  echo ""
  echo "Done."
}

run_commit_flow
