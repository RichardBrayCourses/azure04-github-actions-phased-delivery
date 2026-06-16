#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOREPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

AZURE_ENVIRONMENT="${AZURE_ENVIRONMENT:-${DEPLOY_ENV:-}}"

if [[ -z "$AZURE_ENVIRONMENT" ]]; then
  echo "No environment selected."
  echo "Use one of: testing, staging, production."
  echo "Example: DEPLOY_ENV=testing pnpm run deploy-everything"
  exit 1
fi

case "$AZURE_ENVIRONMENT" in
  testing | staging | production) ;;
  *)
    echo "Unknown environment: $AZURE_ENVIRONMENT"
    echo "Use one of: testing, staging, production."
    exit 1
    ;;
esac

ENVIRONMENT_FILE="$MONOREPO_DIR/environments/$AZURE_ENVIRONMENT.json"

if [[ ! -f "$ENVIRONMENT_FILE" ]]; then
  echo "Environment configuration not found: $ENVIRONMENT_FILE"
  exit 1
fi

read_environment_value() {
  local key="$1"
  node -e "const fs = require('fs'); const config = JSON.parse(fs.readFileSync(process.argv[1], 'utf8')); const value = config[process.argv[2]]; if (value === undefined || value === null || value === '') process.exit(1); process.stdout.write(String(value));" "$ENVIRONMENT_FILE" "$key"
}

ENVIRONMENT_NAME="$(read_environment_value environmentName)"
AZURE_LOCATION="${AZURE_LOCATION:-$(read_environment_value location)}"
AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-$(read_environment_value resourceGroup)}"
AZURE_DEPLOYMENT_NAME="${AZURE_DEPLOYMENT_NAME:-$(read_environment_value deploymentName)}"
AZURE_APP_NAME="${AZURE_APP_NAME:-$(read_environment_value appName)}"
AZURE_DOMAIN_NAME="${AZURE_DOMAIN_NAME:-$(read_environment_value domainName)}"
AZURE_STORAGE_AUTH_MODE="${AZURE_STORAGE_AUTH_MODE:-key}"
UI_DIST_DIR="${UI_DIST_DIR:-$MONOREPO_DIR/apps/ui/dist}"
BICEP_TEMPLATE_FILE="${BICEP_TEMPLATE_FILE:-$MONOREPO_DIR/infra/main.bicep}"
