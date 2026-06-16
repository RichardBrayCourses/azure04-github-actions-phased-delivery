#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT_NAME="${1:-}"

if [[ -z "$ENVIRONMENT_NAME" ]]; then
  echo "No environment selected."
  echo "Use one of: testing, staging, production."
  exit 1
fi

case "$ENVIRONMENT_NAME" in
  testing | staging | production) ;;
  *)
    echo "Unknown environment: $ENVIRONMENT_NAME"
    echo "Use one of: testing, staging, production."
    exit 1
    ;;
esac

if ! command -v gh >/dev/null 2>&1; then
  echo "Missing required command: gh"
  echo "Install GitHub CLI and run gh auth login first."
  exit 1
fi

echo ""
echo "Waiting for the latest GitHub Actions deployment on branch: $ENVIRONMENT_NAME"
echo ""

RUN_ID=""

for _ in {1..30}; do
  RUN_ID="$(gh run list \
    --workflow deploy.yml \
    --branch "$ENVIRONMENT_NAME" \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId // ""')"

  if [[ -n "$RUN_ID" ]]; then
    break
  fi

  sleep 2
done

if [[ -z "$RUN_ID" ]]; then
  echo "No GitHub Actions run was found for branch: $ENVIRONMENT_NAME"
  echo "Check the Actions tab in GitHub, then retry this command."
  exit 1
fi

echo "Watching run: $RUN_ID"
echo ""

gh run watch "$RUN_ID" --exit-status

echo ""
echo "GitHub Actions deployment completed for: $ENVIRONMENT_NAME"
echo ""
