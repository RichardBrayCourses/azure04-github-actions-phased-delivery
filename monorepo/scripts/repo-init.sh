#!/usr/bin/env bash

set -euo pipefail

REMOTE_URL="${1:-}"

if [[ -d ".git" ]] || git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Git repository already exists. repo:init must be run in a copied folder before Git is initialised."
  exit 1
fi

git init --initial-branch=main
git add .
git commit -m "Initial course repository"

git branch testing
git branch staging
git branch production

if [[ -n "$REMOTE_URL" ]]; then
  git remote add origin "$REMOTE_URL"
  git push -u origin main
  git push -u origin testing
  git push -u origin staging
  git push -u origin production
fi

echo ""
echo "Repository initialised with branches:"
echo "main"
echo "testing"
echo "staging"
echo "production"
echo ""
