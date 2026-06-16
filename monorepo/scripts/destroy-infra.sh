#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

if [[ "$ENVIRONMENT_NAME" == "production" ]]; then
  echo ""
  echo "Production deletion requested for resource group: $AZURE_RESOURCE_GROUP"
  read -r -p "Type DELETE-PRODUCTION to continue: " CONFIRMATION

  if [[ "$CONFIRMATION" != "DELETE-PRODUCTION" ]]; then
    echo "Production deletion cancelled."
    exit 1
  fi
fi

echo ""
echo "Deleting $ENVIRONMENT_NAME resource group: $AZURE_RESOURCE_GROUP"
echo ""

az group delete \
  --name "$AZURE_RESOURCE_GROUP" \
  --yes

echo ""
echo "Delete requested."
echo ""
