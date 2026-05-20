# Demo Runbook

## Pre-Demo Checklist (10 minutes)

1. Authenticate to target org:
   - `./scripts/setup-auth.sh <org-alias>`
2. Deploy latest metadata:
   - `./scripts/deploy.sh <org-alias>`
3. Reset demo data:
   - `./scripts/reset-demo-data.sh <org-alias>`
4. Validate runtime:
   - `./scripts/smoke-test.sh <org-alias>`

## Demo Flow

1. Open the `Deal Analysis` app page.
2. In **Deal Sourcing**, search and select `*CodeRabbit`.
3. Show:
   - Relationship health scoring
   - Account research summary
   - Meeting prep card sections + sources
4. Switch to **Portfolio Review**:
   - Select `Demo Growth Fund I`
   - Show fund health and investment breakdown

## Suggested Talk Track

- "This is a single-page deal desk for presales + investment workflows."
- "Data + AI analysis starts immediately after account selection."
- "Each panel is independently powered by Apex and prompt templates."
- "The runbook and scripts make this reproducible across teams and orgs."

## Between-Demo Reset

- Run `./scripts/reset-demo-data.sh <org-alias>` to restore baseline.
- Re-run `./scripts/smoke-test.sh <org-alias>` before next audience.

## Common Live-Demo Issues

- **No meeting prep content**
  - Check `Headless_Meeting_Prep` activation and AI access.
- **Portfolio tab empty**
  - Confirm org has `Fund__c` + `FINS_Investment__c`.
- **Search shows no account**
  - Re-run seed script and verify account name `*CodeRabbit`.

## Presenter Tips

- Keep browser zoom at 90-100% for best card layout.
- If sources are long, cards now wrap and display clickable links.
- Use the `Clear` button to quickly reset account context mid-demo.
