public with sharing class FundReviewController {

    @AuraEnabled(cacheable=false)
    public static String getFundHealth(Id fundId) {
        Fund__c fund = [
            SELECT Name, FINS_Private_Equity_Closed__c, FINS_Private_Equity_Fund_EIN__c,
                   FINS_Private_Equity_Management_Fee__c, FINS_Private_Equity_Target_Size__c,
                   FINS_Private_Equity_Term__c, FINS_Private_Equity_Total_Investments_Ma__c
            FROM Fund__c
            WHERE Id = :fundId
            LIMIT 1
        ];
        try {
            String prompt = buildFundHealthPrompt(fund);
            String rawResponse = invokeEinstein(
                'You are a private equity fund analyst. Analyze this fund data and return a JSON object only — no markdown. Keys: name (string), isOpen (boolean), targetSize (string formatted as currency), totalInvestments (string formatted as currency), managementFee (string), term (string), ein (string), deploymentPercentage (integer 0-100), healthSummary (2-3 sentence string analysis of fund health), keyRisks (array of 2-3 strings).',
                prompt
            );
            if (String.isBlank(rawResponse)) {
                return getFundHealthFallback(fund);
            }
            return stripMarkdownFences(rawResponse);
        } catch (Exception ex) {
            return getFundHealthFallback(fund);
        }
    }

    @AuraEnabled(cacheable=false)
    public static String getInvestmentBreakdown(Id fundId) {
        List<FINS_Investment__c> investments = [
            SELECT Name, FINS_Private_Equity_Amount__c, FINS_Private_Equity_Investor__c,
                   Investor_Type__c, Capital_Called__c, Capital_Remaining__c, Investment_Opportunity__c
            FROM FINS_Investment__c
            WHERE FINS_Private_Equity_Fund__c = :fundId
            ORDER BY CreatedDate DESC
        ];
        Decimal totalAmountDeployed = 0;
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (FINS_Investment__c inv : investments) {
            Decimal amount = inv.FINS_Private_Equity_Amount__c == null ? 0 : inv.FINS_Private_Equity_Amount__c;
            totalAmountDeployed += amount;
            rows.add(new Map<String, Object>{
                'name' => inv.Name,
                'investorName' => String.valueOf(inv.FINS_Private_Equity_Investor__c),
                'investorType' => inv.Investor_Type__c,
                'amount' => inv.FINS_Private_Equity_Amount__c,
                'capitalCalled' => inv.Capital_Called__c,
                'capitalRemaining' => inv.Capital_Remaining__c,
                'opportunityId' => inv.Investment_Opportunity__c
            });
        }
        Map<String, Object> result = new Map<String, Object>{
            'totalCount' => investments.size(),
            'totalAmountDeployed' => totalAmountDeployed,
            'investments' => rows
        };
        return JSON.serialize(result);
    }

    private static String buildFundHealthPrompt(Fund__c fund) {
        String prompt = '';
        prompt += 'Analyze private equity fund health from CRM metadata.\n';
        prompt += 'Name: ' + safeText(fund.Name) + '\n';
        prompt += 'ClosedFlag: ' + safeText(String.valueOf(fund.FINS_Private_Equity_Closed__c)) + '\n';
        prompt += 'EIN: ' + safeText(fund.FINS_Private_Equity_Fund_EIN__c) + '\n';
        prompt += 'ManagementFee: ' + safeText(String.valueOf(fund.FINS_Private_Equity_Management_Fee__c)) + '\n';
        prompt += 'TargetSize: ' + safeText(String.valueOf(fund.FINS_Private_Equity_Target_Size__c)) + '\n';
        prompt += 'Term: ' + safeText(String.valueOf(fund.FINS_Private_Equity_Term__c)) + '\n';
        prompt += 'TotalInvestments: ' + safeText(String.valueOf(fund.FINS_Private_Equity_Total_Investments_Ma__c)) + '\n';
        prompt += 'Return JSON only with required keys.';
        return prompt;
    }

    private static String getFundHealthFallback(Fund__c fund) {
        Decimal target = fund.FINS_Private_Equity_Target_Size__c == null ? 0 : fund.FINS_Private_Equity_Target_Size__c;
        Decimal invested = fund.FINS_Private_Equity_Total_Investments_Ma__c == null ? 0 : fund.FINS_Private_Equity_Total_Investments_Ma__c;
        Integer deploymentPercentage = target > 0 ? Integer.valueOf(Math.round((invested / target) * 100)) : 0;
        deploymentPercentage = Math.max(0, Math.min(100, deploymentPercentage));
        String healthSummary = deploymentPercentage >= 70
            ? 'Deployment is tracking well against target size. Fund operations appear stable based on current CRM values.'
            : deploymentPercentage >= 40
                ? 'Deployment is progressing, but additional pipeline execution is needed to stay on plan.'
                : 'Deployment is behind target and may require acceleration or portfolio strategy adjustment.';
        List<String> keyRisks = new List<String>();
        if (deploymentPercentage < 40) {
            keyRisks.add('Capital deployment is materially below target trajectory.');
        }
        if (fund.FINS_Private_Equity_Management_Fee__c == null) {
            keyRisks.add('Management fee is not populated in CRM.');
        }
        if (String.isBlank(fund.FINS_Private_Equity_Fund_EIN__c)) {
            keyRisks.add('Fund EIN is missing from CRM data.');
        }
        if (keyRisks.isEmpty()) {
            keyRisks.add('No immediate data-quality or deployment risk surfaced from CRM fields.');
            keyRisks.add('Monitor concentration and pacing risk as capital is allocated.');
        }
        Map<String, Object> result = new Map<String, Object>{
            'name' => fund.Name,
            'isOpen' => !(fund.FINS_Private_Equity_Closed__c == true),
            'targetSize' => formatCurrency(target),
            'totalInvestments' => formatCurrency(invested),
            'managementFee' => String.valueOf(fund.FINS_Private_Equity_Management_Fee__c),
            'term' => String.valueOf(fund.FINS_Private_Equity_Term__c),
            'ein' => fund.FINS_Private_Equity_Fund_EIN__c,
            'deploymentPercentage' => deploymentPercentage,
            'healthSummary' => healthSummary,
            'keyRisks' => keyRisks
        };
        return JSON.serialize(result);
    }

    private static String formatCurrency(Decimal value) {
        Decimal normalized = value == null ? 0 : value.setScale(2);
        return '$' + String.valueOf(normalized);
    }

    private static String stripMarkdownFences(String rawResponse) {
        String cleaned = rawResponse == null ? '' : rawResponse.trim();
        if (cleaned.startsWith('```')) {
            Integer firstNewline = cleaned.indexOf('\n');
            if (firstNewline > -1) {
                cleaned = cleaned.substring(firstNewline + 1);
            }
            if (cleaned.endsWith('```')) {
                cleaned = cleaned.substring(0, cleaned.length() - 3);
            }
        }
        return cleaned.trim();
    }

    private static String safeText(String value) {
        return value == null ? 'null' : value.replace('\n', ' ').trim();
    }

    private static String invokeEinstein(String systemPrompt, String userPrompt) {
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.isPreview = false;
            ConnectApi.EinsteinLlmAdditionalConfigInput cfg = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            cfg.applicationName = 'PromptBuilderPreview';
            input.additionalConfig = cfg;
            ConnectApi.WrappedValue systemValue = new ConnectApi.WrappedValue();
            systemValue.value = systemPrompt;
            ConnectApi.WrappedValue userValue = new ConnectApi.WrappedValue();
            userValue.value = userPrompt;
            input.inputParams = new Map<String, ConnectApi.WrappedValue>{
                'Input:SystemPrompt' => systemValue,
                'Input:UserPrompt' => userValue
            };
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Fund_Review_Health', input);
            if (output == null || output.generations == null || output.generations.isEmpty()) {
                return null;
            }
            return output.generations[0].text;
        } catch (Exception ex) {
            return null;
        }
    }
}
