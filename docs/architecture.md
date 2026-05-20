# Architecture Overview

## Functional Scope

`accountAnalysis` is the main entry component with two tabs:

- **Deal Sourcing**
  - Account search + selection
  - Relationship Health panel
  - Account Research panel
  - Meeting Prep brief panel
- **Portfolio Review**
  - Fund selection panel
  - Fund Health panel
  - Investment Breakdown panel

## Component Map

- `accountAnalysis`
  - `relationshipHealth` -> `RelationshipHealthController.getRelationshipHealth`
  - `accountResearch` -> `AccountResearchController.getAccountResearch`
  - `meetingPrepBrief` -> `MeetingPrepController.getMeetingPrep`
  - `fundReview`
    - `fundHealth` -> `FundReviewController.getFundHealth`
    - `investmentBreakdown` -> `FundReviewController.getInvestmentBreakdown`

## Apex + Prompt Dependencies

- `RelationshipHealthController`
  - Prompt template: `Account_Analysis_Relationship_Health`
- `AccountResearchController`
  - Prompt template: `Account_Analysis_Research`
- `FundReviewController`
  - Prompt template: `Fund_Review_Health`
- `MeetingPrepController`
  - Prompt template: `Headless_Meeting_Prep`

## Data Dependencies

### Standard objects

- Account
- Contact
- Task
- Event
- Case
- Opportunity

### Optional custom/FSC objects

- `Fund__c`
- `FINS_Investment__c`
- `Financial_Deal__c` (optional context used by account controllers when available)

## Runtime Behavior

- LWC components call Apex imperatively.
- Apex tries LLM prompt generation first.
- When LLM output is unavailable, fallback responses are returned in JSON/text.
- `meetingPrepBrief` parses markdown-style sections into card UI blocks.

## Demo Reliability Features

- Idempotent data seeding script (`scripts/apex/seedDemoData.apex`)
- Reset script (`scripts/apex/cleanupDemoData.apex` + reseed)
- Smoke test script validates key controller responses before demos
