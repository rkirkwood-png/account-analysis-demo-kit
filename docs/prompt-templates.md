# Prompt Template Contract

This app depends on Prompt Builder templates referenced by Apex.

## Required Template API Names

- `Account_Analysis_Relationship_Health`
- `Account_Analysis_Research`
- `Fund_Review_Health`
- `Headless_Meeting_Prep`

## Input Expectations by Controller

### `RelationshipHealthController`

- Template: `Account_Analysis_Relationship_Health`
- Inputs:
  - `Input:SystemPrompt` (string)
  - `Input:UserPrompt` (string)

### `AccountResearchController`

- Template: `Account_Analysis_Research`
- Inputs:
  - `Input:SystemPrompt` (string)
  - `Input:UserPrompt` (string)

### `FundReviewController`

- Template: `Fund_Review_Health`
- Inputs:
  - `Input:SystemPrompt` (string)
  - `Input:UserPrompt` (string)

### `MeetingPrepController`

- Template: `Headless_Meeting_Prep`
- Input key/value fallback matrix attempted by Apex:
  - Keys: `Input:Account`, `accountId`, `AccountId`, `recordId`
  - Values: string id, `Id`, `{ "id": "<Id>" }`

## Template Type Recommendation

- Use **Flex / Headless** style templates for Apex-invoked prompts where you control
  explicit input contracts.
- Record summary templates can fail silently if input shape does not match expected
  runtime context.

## Activation + Validation Steps

1. Deploy/retrieve templates into source control.
2. In Prompt Builder, verify each template is active.
3. Confirm running user has access to Prompt Builder templates.
4. Run:
   - `./scripts/smoke-test.sh <org-alias>`

## Troubleshooting

- If meeting prep returns `No content returned from Einstein.`:
  - Confirm `Headless_Meeting_Prep` exists and is active in target org.
  - Confirm model access and Einstein features are enabled.
  - Validate template input variable names in Prompt Builder.
- If controllers return fallback JSON:
  - Prompt invocation likely failed or returned empty generations.
  - Check debug logs and org feature enablement.
