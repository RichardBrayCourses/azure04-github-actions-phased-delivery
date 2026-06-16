#!/usr/bin/env bash

set -euo pipefail

REMOTE_URL="${1:-}"
COURSE_BRANCHES=(main testing staging production)
SHOULD_PUSH_BRANCHES=false

ensure_initial_commit() {
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    return
  fi

  git add .
  git commit -m "Initial course repository"
}

ensure_branch() {
  local branch="$1"
  local start_point="$2"

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Branch already exists: $branch"
  else
    git branch "$branch" "$start_point"
    echo "Created branch: $branch"
  fi
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Git repository already exists. Checking course branches..."
else
  git init --initial-branch=main
fi

ensure_initial_commit

if ! git show-ref --verify --quiet "refs/heads/main"; then
  git branch main HEAD
  echo "Created branch: main"
else
  echo "Branch already exists: main"
fi

ensure_branch testing main
ensure_branch staging main
ensure_branch production main

if [[ -n "$REMOTE_URL" ]]; then
  if git remote get-url origin >/dev/null 2>&1; then
    EXISTING_REMOTE_URL="$(git remote get-url origin)"
    if [[ "$EXISTING_REMOTE_URL" != "$REMOTE_URL" ]]; then
      echo "Remote origin already exists with a different URL:"
      echo "$EXISTING_REMOTE_URL"
      exit 1
    fi
  else
    git remote add origin "$REMOTE_URL"
  fi

  SHOULD_PUSH_BRANCHES=true
elif git remote get-url origin >/dev/null 2>&1; then
  SHOULD_PUSH_BRANCHES=true
fi

if [[ "$SHOULD_PUSH_BRANCHES" == "true" ]]; then
  for branch in "${COURSE_BRANCHES[@]}"; do
    git push -u origin "$branch"
  done
else
  echo "Remote origin is not configured. Local course branches are ready but not published."
fi

echo ""
echo "Course branches are ready:"
printf '%s\n' "${COURSE_BRANCHES[@]}"
echo ""
