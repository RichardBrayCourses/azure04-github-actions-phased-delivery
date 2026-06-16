#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

OUTPUT_MODE="${1:-summary}"

case "$OUTPUT_MODE" in
  summary | --target-only) ;;
  *)
    echo "Unknown option: $OUTPUT_MODE"
    echo "Usage: bash scripts/show-url.sh [--target-only]"
    exit 1
    ;;
esac

if ! STORAGE_ACCOUNT_NAME=$(az deployment group show \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$AZURE_DEPLOYMENT_NAME" \
  --query "properties.outputs.storageAccountName.value" \
  --output tsv 2>/dev/null); then
  echo ""
  echo "The $ENVIRONMENT_NAME Azure deployment is not available yet."
  echo "Resource group: $AZURE_RESOURCE_GROUP"
  echo ""
  echo "If you just ran pnpm run release:$ENVIRONMENT_NAME, wait for GitHub Actions to finish:"
  echo "pnpm run $ENVIRONMENT_NAME:wait-for-deploy"
  echo ""
  echo "Then retry:"
  echo "pnpm run $ENVIRONMENT_NAME:get-storage-account"
  echo ""
  exit 1
fi

WEBSITE_URL=$(az storage account show \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT_NAME" \
  --query "primaryEndpoints.web" \
  --output tsv)
WEBSITE_HOST="${WEBSITE_URL#https://}"
WEBSITE_HOST="${WEBSITE_HOST#http://}"
WEBSITE_HOST="${WEBSITE_HOST%/}"

if [[ -z "$WEBSITE_URL" || "$WEBSITE_URL" == "null" ]]; then
  echo ""
  echo "Static website URL was not found for storage account: $STORAGE_ACCOUNT_NAME"
  echo "Run pnpm run infra:deploy first so static website hosting is enabled."
  echo ""
  exit 1
fi

if [[ "$OUTPUT_MODE" == "--target-only" ]]; then
  echo "$WEBSITE_HOST"
  exit 0
fi

echo ""
echo "Azure static website URL:"
echo "$WEBSITE_URL"
echo ""
echo "Cloudflare CNAME target:"
echo "$WEBSITE_HOST"
echo ""
echo "Public environment URL:"
echo "https://$AZURE_DOMAIN_NAME"
echo ""

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## Deployed $ENVIRONMENT_NAME"
    echo ""
    echo "| URL type | URL |"
    echo "| --- | --- |"
    echo "| Azure static website | $WEBSITE_URL |"
    echo "| Cloudflare CNAME target | $WEBSITE_HOST |"
    echo "| Public environment | https://$AZURE_DOMAIN_NAME |"
    echo ""
  } >> "$GITHUB_STEP_SUMMARY"
fi
