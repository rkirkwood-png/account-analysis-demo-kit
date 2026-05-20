#!/usr/bin/env bash
set -euo pipefail

TARGET_ORG="${1:-${TARGET_ORG_ALIAS:-}}"
DEMO_ACCOUNT_NAME="${2:-${DEMO_ACCOUNT_NAME:-*CodeRabbit}}"

if [[ -z "${TARGET_ORG}" ]]; then
  echo "Usage: ./scripts/smoke-test.sh <target-org-alias> [demo-account-name]"
  exit 1
fi

echo "Running smoke checks in ${TARGET_ORG} for account '${DEMO_ACCOUNT_NAME}'..."

ACCOUNT_QUERY_JSON="$(sf data query \
  --target-org "${TARGET_ORG}" \
  --json \
  --query "SELECT Id, Name FROM Account WHERE Name = '${DEMO_ACCOUNT_NAME}' LIMIT 1")"

ACCOUNT_ID="$(python3 -c "import json,sys; d=json.load(sys.stdin); r=d.get('result',{}).get('records',[]); print(r[0].get('Id','') if r else '')" <<< "${ACCOUNT_QUERY_JSON}")"

if [[ -z "${ACCOUNT_ID}" ]]; then
  echo "Smoke test failed: demo account '${DEMO_ACCOUNT_NAME}' was not found."
  exit 1
fi

echo "Found demo account Id: ${ACCOUNT_ID}"

cat > /tmp/account-analysis-smoke.apex <<EOF
Id accountId = '${ACCOUNT_ID}';
String relationship = RelationshipHealthController.getRelationshipHealth(accountId);
String research = AccountResearchController.getAccountResearch(accountId);
String meetingPrep = MeetingPrepController.getMeetingPrep(accountId);
System.debug('SMOKE_REL=' + relationship);
System.debug('SMOKE_RESEARCH=' + research);
System.debug('SMOKE_PREP=' + meetingPrep);
if (String.isBlank(relationship)) {
    throw new AuraHandledException('Relationship health returned blank.');
}
if (String.isBlank(research)) {
    throw new AuraHandledException('Account research returned blank.');
}
if (String.isBlank(meetingPrep) || meetingPrep.contains('No content returned from Einstein.')) {
    throw new AuraHandledException('Meeting prep returned blank or no-content response.');
}
EOF

sf apex run \
  --target-org "${TARGET_ORG}" \
  --file /tmp/account-analysis-smoke.apex

rm -f /tmp/account-analysis-smoke.apex
echo "Smoke checks passed."
