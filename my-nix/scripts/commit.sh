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

push_repo() {
  local repo_dir="$1" use_base="$2"
  if [[ "$use_base" -eq 1 && -n "$BASE_CONTRIBUTOR_SSH_KEY" ]]; then
    GIT_SSH_COMMAND="ssh -F /dev/null -i ${BASE_CONTRIBUTOR_SSH_KEY} -o IdentitiesOnly=yes" \
      git -C "$repo_dir" push
  else
    git -C "$repo_dir" push
  fi
}

commits_ahead() {
  local repo_dir="$1"
  local upstream
  upstream="$(git -C "$repo_dir" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)" || return 1
  local count
  count="$(git -C "$repo_dir" rev-list --count "${upstream}..HEAD")"
  [[ "$count" -gt 0 ]]
}

process_repo() {
  local label="$1" repo_dir="$2" default_msg="$3" use_base="$4"

  echo ""
  echo "── ${label} (${repo_dir}) ──"

  if ! [[ -d "${repo_dir}/.git" || -f "${repo_dir}/.git" ]]; then
    echo "  Not a git repo — skipping."
    return 0
  fi

  # Handle detached HEAD — offer to checkout main branch
  if is_detached "$repo_dir"; then
    local default_branch
    default_branch="$(git -C "$repo_dir" config init.defaultBranch 2>/dev/null || echo "master")"
    if git -C "$repo_dir" rev-parse --verify "$default_branch" &>/dev/null; then
      echo "  Detached HEAD. Checking out ${default_branch}..."
      git -C "$repo_dir" checkout "$default_branch"
    else
      echo "  ⚠ Detached HEAD — no ${default_branch} branch found, skipping."
      return 0
    fi
  fi

  # Commit if dirty
  if is_dirty "$repo_dir"; then
    git -C "$repo_dir" add -A

    if ! git -C "$repo_dir" diff --cached --quiet; then
      echo ""
      git --no-pager -C "$repo_dir" diff --cached --stat
      echo ""

      read -r -p "  Commit changes? [Y/n] " yn
      case "${yn:-y}" in
        [Nn]*)
          git -C "$repo_dir" reset --quiet
          echo "  Commit skipped."
          ;;
        *)
          local msg
          read_default "  Commit message" "$default_msg" msg
          git_cmd "$repo_dir" "$use_base" commit -m "$msg"
          ;;
      esac
    fi
  else
    echo "  Clean — nothing to commit."
  fi

  # Push if there are unpushed commits
  if ! has_remote "$repo_dir"; then
    return 0
  fi
  if commits_ahead "$repo_dir"; then
    local ahead
    ahead="$(git -C "$repo_dir" rev-list --count '@{upstream}..HEAD')"
    read -r -p "  ${ahead} unpushed commit(s). Push? [Y/n] " push_yn
    case "${push_yn:-y}" in
      [Nn]*) echo "  Push skipped." ;;
      *) push_repo "$repo_dir" "$use_base" ;;
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
