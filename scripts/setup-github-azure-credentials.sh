#!/usr/bin/env bash

set -euo pipefail

APP_PREFIX="${APP_PREFIX:-all-checks-out-github-actions}"
GITHUB_SECRET_NAME="${GITHUB_SECRET_NAME:-AZURE_CREDENTIALS}"
SECRET_FILE="$(mktemp "${TMPDIR:-/tmp}/${APP_PREFIX}.XXXXXX.json")"
ASSUME_YES=false

if [[ "${1:-}" == "--yes" ]]; then
  ASSUME_YES=true
elif [[ -n "${1:-}" ]]; then
  echo "Unknown option: $1"
  echo "Usage: pnpm run setup:github-azure [-- --yes]"
  exit 1
fi

cleanup() {
  rm -f "$SECRET_FILE"
}
trap cleanup EXIT

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name"
    exit 1
  fi
}

require_command az
require_command gh

SUBSCRIPTION_ID="$(az account show --query id --output tsv)"

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "No Azure subscription selected. Run az login first."
  exit 1
fi

echo ""
echo "Azure subscription:"
az account show --query "{name:name,id:id,tenantId:tenantId}" --output table

echo ""
echo "GitHub repository:"
gh repo view --json nameWithOwner --jq .nameWithOwner

echo ""
echo "Existing app registrations:"
az ad app list --all \
  --query "[?starts_with(displayName, '$APP_PREFIX')].{name:displayName, appId:appId, objectId:id}" \
  --output table

echo ""
echo "Existing service principals:"
az ad sp list --all \
  --query "[?starts_with(displayName, '$APP_PREFIX')].{name:displayName, appId:appId, objectId:id}" \
  --output table

APP_IDS="$(
  {
    az ad app list --all \
      --query "[?starts_with(displayName, '$APP_PREFIX')].appId" \
      --output tsv
    az ad sp list --all \
      --query "[?starts_with(displayName, '$APP_PREFIX')].appId" \
      --output tsv
  } | sort -u
)"

if [[ -n "$APP_IDS" ]]; then
  if [[ "$ASSUME_YES" != "true" ]]; then
    echo ""
    read -r -p "Type SETUP-GITHUB-AZURE to delete the matching identities shown above and create a new GitHub secret: " CONFIRMATION

    if [[ "$CONFIRMATION" != "SETUP-GITHUB-AZURE" ]]; then
      echo "Cancelled."
      exit 1
    fi
  fi

  while IFS= read -r app_id; do
    if [[ -z "$app_id" ]]; then
      continue
    fi

    echo "Deleting service principal, if present: $app_id"
    az ad sp delete --id "$app_id" >/dev/null 2>&1 || true

    echo "Deleting app registration, if present: $app_id"
    az ad app delete --id "$app_id" >/dev/null 2>&1 || true
  done <<< "$APP_IDS"
else
  echo ""
  echo "No matching Azure identities found. Nothing to delete."
fi

SP_NAME="${APP_PREFIX}-$(date +%Y%m%d%H%M%S)"

echo ""
echo "Creating new service principal: $SP_NAME"

az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --query "{clientId:appId,clientSecret:password,subscriptionId:'$SUBSCRIPTION_ID',tenantId:tenant}" \
  --output json \
  > "$SECRET_FILE"

echo "Updating GitHub Actions secret: $GITHUB_SECRET_NAME"
gh secret set "$GITHUB_SECRET_NAME" < "$SECRET_FILE"

echo ""
echo "GitHub-to-Azure setup complete."
echo "Created service principal: $SP_NAME"
echo "Local temporary secret file deleted."
echo ""
