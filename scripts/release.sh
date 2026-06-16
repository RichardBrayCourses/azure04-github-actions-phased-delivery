#!/usr/bin/env bash

set -euo pipefail

TARGET_BRANCH="${1:-}"

case "$TARGET_BRANCH" in
  testing)
    SOURCE_BRANCH="main"
    ;;
  staging)
    SOURCE_BRANCH="testing"
    ;;
  production)
    SOURCE_BRANCH="staging"
    ;;
  *)
    echo "Usage: pnpm run release:testing|release:staging|release:production"
    exit 1
    ;;
esac

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This command must be run inside a Git repository."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit or stash changes before releasing."
  exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
  git fetch origin --prune
else
  echo "Remote 'origin' is not configured. Add a GitHub remote before releasing."
  exit 1
fi

if ! git show-ref --verify --quiet "refs/heads/$SOURCE_BRANCH"; then
  if git show-ref --verify --quiet "refs/remotes/origin/$SOURCE_BRANCH"; then
    git branch "$SOURCE_BRANCH" "origin/$SOURCE_BRANCH"
  else
    echo "Source branch not found: $SOURCE_BRANCH"
    exit 1
  fi
fi

if ! git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
  if git show-ref --verify --quiet "refs/remotes/origin/$TARGET_BRANCH"; then
    git branch "$TARGET_BRANCH" "origin/$TARGET_BRANCH"
  else
    git branch "$TARGET_BRANCH" "$SOURCE_BRANCH"
  fi
fi

echo ""
echo "Promoting $SOURCE_BRANCH -> $TARGET_BRANCH"
echo ""

git checkout "$TARGET_BRANCH"
git merge --ff-only "$SOURCE_BRANCH"
git push -u origin "$TARGET_BRANCH"

echo ""
echo "Release promotion complete."
echo "GitHub Actions will deploy the $TARGET_BRANCH branch."
echo ""
