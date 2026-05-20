#!/usr/bin/env bash
set -euo pipefail

TARGET_ORG="${1:-${TARGET_ORG_ALIAS:-}}"

if [[ -z "${TARGET_ORG}" ]]; then
  echo "Usage: ./scripts/setup-auth.sh <target-org-alias>"
  echo "Example: ./scripts/setup-auth.sh tsilk@pe.onfsc"
  exit 1
fi

echo "Checking Salesforce CLI authentication for: ${TARGET_ORG}"
if sf org display --target-org "${TARGET_ORG}" >/dev/null 2>&1; then
  echo "Authenticated org alias is available: ${TARGET_ORG}"
  exit 0
fi

echo "Org alias '${TARGET_ORG}' is not authenticated yet."
echo "Run one of the following and retry:"
echo "  sf org login web --alias ${TARGET_ORG}"
echo "  sf org login sfdx-url --sfdx-url-file <auth-file> --alias ${TARGET_ORG}"
exit 1
