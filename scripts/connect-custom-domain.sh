#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

STORAGE_ACCOUNT_NAME=$(az deployment group show \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$AZURE_DEPLOYMENT_NAME" \
  --query "properties.outputs.storageAccountName.value" \
  --output tsv)

if [[ -z "$STORAGE_ACCOUNT_NAME" || "$STORAGE_ACCOUNT_NAME" == "null" ]]; then
  echo ""
  echo "Storage account was not found for deployment: $AZURE_DEPLOYMENT_NAME"
  echo "Run the deployment first, then retry this command."
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
BLOB_HOST="$STORAGE_ACCOUNT_NAME.blob.core.windows.net"

echo ""
echo "Connecting Azure Storage custom domain"
echo "Environment:     $ENVIRONMENT_NAME"
echo "Resource group:  $AZURE_RESOURCE_GROUP"
echo "Storage account: $STORAGE_ACCOUNT_NAME"
echo "Custom domain:   $AZURE_DOMAIN_NAME"
echo "Expected CNAME:  $WEBSITE_HOST"
echo ""
echo "Cloudflare note:"
echo "The CNAME record must be visible to Azure while this runs."
echo "If verification fails, temporarily set the Cloudflare record to DNS only,"
echo "rerun this command, then switch it back to Proxied."
echo ""

if command -v dig >/dev/null 2>&1; then
  DNS_CNAME="$(dig +short CNAME "$AZURE_DOMAIN_NAME" | sed 's/\.$//' | head -n 1)"

  if [[ -z "$DNS_CNAME" ]]; then
    echo "Azure cannot verify this domain yet."
    echo ""
    echo "Public DNS does not currently show a CNAME for:"
    echo "$AZURE_DOMAIN_NAME"
    echo ""
    echo "Current DNS answer:"
    dig +short "$AZURE_DOMAIN_NAME" || true
    echo ""
    echo "In Cloudflare, set this record to DNS only and wait until this command prints:"
    echo "$WEBSITE_HOST"
    echo ""
    echo "Check with:"
    echo "dig +short CNAME $AZURE_DOMAIN_NAME"
    echo ""
    exit 1
  fi

  if [[ "$DNS_CNAME" != "$WEBSITE_HOST" && "$DNS_CNAME" != "$BLOB_HOST" ]]; then
    echo "Azure cannot verify this domain yet."
    echo ""
    echo "Expected CNAME:"
    echo "$WEBSITE_HOST"
    echo ""
    echo "Current CNAME:"
    echo "$DNS_CNAME"
    echo ""
    echo "Update the Cloudflare target, wait for DNS to settle, then rerun this command."
    echo ""
    exit 1
  fi
fi

az storage account update \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT_NAME" \
  --custom-domain "$AZURE_DOMAIN_NAME" \
  --use-subdomain false \
  --output none

echo "Azure Storage now accepts requests for:"
echo "https://$AZURE_DOMAIN_NAME"
echo ""
