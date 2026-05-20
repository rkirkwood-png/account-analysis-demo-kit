#!/usr/bin/env bash
set -euo pipefail

TARGET_ORG="${1:-${TARGET_ORG_ALIAS:-}}"

if [[ -z "${TARGET_ORG}" ]]; then
  echo "Usage: ./scripts/seed-demo-data.sh <target-org-alias>"
  exit 1
fi

echo "Seeding demo data in ${TARGET_ORG}..."
sf apex run \
  --target-org "${TARGET_ORG}" \
  --file scripts/apex/seedDemoData.apex

echo "Demo data seed complete."
