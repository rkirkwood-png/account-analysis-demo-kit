# GitHub Publishing Workflow

## Branching Model

- Primary reusable branch: `demo-reusable`
- Create feature branches from `demo-reusable` for changes
- Merge via PR with script/docs/smoke-test verification

## Pull Request Checklist

- [ ] README updated for any behavior/setup changes
- [ ] `docs/` updates included for prompt/data/runtime changes
- [ ] Seed/reset scripts still idempotent
- [ ] Smoke test passes in at least one target org
- [ ] No org-specific secrets committed

## Release Process

1. Merge approved PR into `demo-reusable`.
2. Create version tag (example: `v1.0-demo-kit`).
3. Publish GitHub release notes including:
   - supported CLI/API version
   - quickstart commands
   - required prompt templates
   - known constraints and troubleshooting links

## Suggested Release Notes Template

### Included

- LWC app + Apex controllers + FlexiPage metadata
- Prompt template integration contract
- Demo seed/reset/smoke scripts
- Architecture and demo runbook documentation

### Quickstart

```bash
./scripts/setup-auth.sh <org-alias>
./scripts/deploy.sh <org-alias>
./scripts/seed-demo-data.sh <org-alias>
./scripts/smoke-test.sh <org-alias>
```

### Notes

- Requires active Prompt Builder templates:
  `Account_Analysis_Relationship_Health`, `Account_Analysis_Research`,
  `Fund_Review_Health`, `Headless_Meeting_Prep`.
- Portfolio Review features require `Fund__c` and `FINS_Investment__c`.

## Optional CI Recommendation

Add GitHub Actions to run:

- LWC lint checks
- static validation checks
- `sf project deploy start --dry-run` (for metadata sanity)
