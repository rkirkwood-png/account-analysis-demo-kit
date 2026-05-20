# Account Analysis Demo Kit

Reusable Salesforce demo application for presales engineers. This repo is designed as a
turnkey "clone, deploy, seed, and demo" package for Agentforce-backed account and fund
analysis flows.

## What This Includes

- LWC app bundles in `force-app/main/default/lwc`
- Apex controllers in `force-app/main/default/classes`
- Lightning App Page: `Deal Analysis` in
  `force-app/main/default/flexipages/Deal_Analysis.flexipage-meta.xml`
- Prompt Template metadata in `force-app/main/default/genAiPromptTemplates`
- Logo static resource in `force-app/main/default/staticresources/dealAnalysisLogo.resource`
- Reusable scripts for auth, deploy, seed/reset, and smoke tests in `scripts/`

## Prerequisites

- Salesforce CLI `sf` installed and authenticated to a target org
- Org permissions to deploy metadata and run anonymous Apex
- Agentforce / Einstein features enabled in target org
- Prompt templates deployed and activated (see `docs/prompt-templates.md`)
- Optional: Python 3 (used by smoke test script for JSON parsing)

## 5-Minute Quickstart

1. Clone this repository.
2. Authenticate to your org alias:
   - `./scripts/setup-auth.sh <org-alias>`
3. Deploy all metadata:
   - `./scripts/deploy.sh <org-alias>`
4. Seed deterministic demo data:
   - `./scripts/seed-demo-data.sh <org-alias>`
5. Run smoke validation:
   - `./scripts/smoke-test.sh <org-alias>`

Then open the `Deal Analysis` app page in Salesforce and search for `*CodeRabbit`.

## Script Reference

- `scripts/setup-auth.sh`  
  Validates Salesforce CLI authentication and prints next steps.
- `scripts/deploy.sh`  
  Deploys `force-app` source to target org.
- `scripts/seed-demo-data.sh`  
  Seeds idempotent demo data for account + relationship + fund workflows.
- `scripts/reset-demo-data.sh`  
  Cleans demo-tagged records and reseeds from baseline.
- `scripts/smoke-test.sh`  
  Executes Apex controller checks and confirms expected demo record availability.

## Prompt Template Requirements

This project references these template API names in Apex:

- `Account_Analysis_Relationship_Health`
- `Account_Analysis_Research`
- `Fund_Review_Health`
- `Headless_Meeting_Prep` (used by `MeetingPrepController`)

If `Headless_Meeting_Prep` is not in this repo metadata yet, create/retrieve and deploy it
to each target org. Details are in `docs/prompt-templates.md`.

## Target Org Setup Checklist

- Ensure LWC deployment is allowed in target org
- Ensure prompt templates are active and accessible
- Ensure running user has access to:
  - Account, Contact, Task, Event, Case, Opportunity
  - Fund object model (`Fund__c`, `FINS_Investment__c`) if portfolio tab is used
- Add `Deal Analysis` app page to an app/navigation menu as needed

## Known Constraints

- Meeting prep quality depends on your `Headless_Meeting_Prep` prompt definition and org
  AI configuration.
- Portfolio Review cards require custom Financial Services objects/fields in the org.
- Some generated narrative content depends on external model behavior and can vary run to
  run.

## Documentation

- `docs/architecture.md`
- `docs/prompt-templates.md`
- `docs/demo-runbook.md`
- `docs/publishing.md`

## Recommended Branch + Release Process

- Work in a branch such as `demo-reusable`
- Open PR with script/docs/metadata updates
- Tag release after validation (for example `v1.0-demo-kit`)
- Publish release notes with exact quickstart commands and known prerequisites
