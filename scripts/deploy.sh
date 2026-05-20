#!/usr/bin/env bash
set -euo pipefail

TARGET_ORG="${1:-${TARGET_ORG_ALIAS:-}}"

if [[ -z "${TARGET_ORG}" ]]; then
  echo "Usage: ./scripts/deploy.sh <target-org-alias>"
  exit 1
fi

echo "Deploying force-app metadata to ${TARGET_ORG}..."
sf project deploy start \
  --target-org "${TARGET_ORG}" \
  --source-dir force-app

echo "Deployment finished."
