public with sharing class MeetingPrepController {
    @AuraEnabled(cacheable=false)
    public static String getMeetingPrep(Id accountId) {
        try {
            String templateApiName = 'Headless_Meeting_Prep';
            List<String> inputKeys = new List<String>{
                'Input:Account',
                'accountId',
                'AccountId',
                'recordId'
            };
            List<Object> inputValues = new List<Object>{
                String.valueOf(accountId),
                accountId,
                new Map<String, Object>{ 'id' => String.valueOf(accountId) }
            };

            for (String key : inputKeys) {
                for (Object val : inputValues) {
                    String outputText = invokeTemplate(templateApiName, key, val);
                    if (String.isNotBlank(outputText)) {
                        return outputText;
                    }
                }
            }

            return 'No content returned from Einstein.';
        } catch (Exception ex) {
            return 'Error: ' + ex.getTypeName() + ' — ' + ex.getMessage();
        }
    }

    @AuraEnabled(cacheable=false)
    public static String getMeetingSummaries(Id accountId) {
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.isPreview = false;
            ConnectApi.EinsteinLlmAdditionalConfigInput cfg = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            cfg.applicationName = 'PromptBuilderPreview';
            input.additionalConfig = cfg;
            Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
            ConnectApi.WrappedValue accountValue = new ConnectApi.WrappedValue();
            accountValue.value = acc;
            input.inputParams = new Map<String, ConnectApi.WrappedValue>{
                'Input:Account' => accountValue
            };
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Headless_Meeting_Summaries', input);
            if (output != null && output.generations != null && !output.generations.isEmpty()) {
                return output.generations[0].text;
            }
            return null;
        } catch (Exception ex) {
            return 'Error: ' + ex.getTypeName() + ' — ' + ex.getMessage();
        }
    }

    private static String invokeTemplate(String templateApiName, String inputKey, Object inputValue) {
        ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        input.isPreview = false;
        ConnectApi.EinsteinLlmAdditionalConfigInput cfg = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        cfg.applicationName = 'PromptBuilderPreview';
        input.additionalConfig = cfg;

        ConnectApi.WrappedValue wrapped = new ConnectApi.WrappedValue();
        wrapped.value = inputValue;
        input.inputParams = new Map<String, ConnectApi.WrappedValue>{
            inputKey => wrapped
        };

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(templateApiName, input);
        if (output != null && output.generations != null && !output.generations.isEmpty()) {
            return output.generations[0].text;
        }
        return null;
    }

    @AuraEnabled(cacheable=false)
    public static String getInteractionSummary(Id accountId) {
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
        List<Event> events = [
            SELECT Subject, ActivityDateTime, Description, Owner.Name
            FROM Event
            WHERE (WhatId = :accountId OR Account.Id = :accountId) AND ActivityDateTime = LAST_N_DAYS:180
            ORDER BY ActivityDateTime DESC LIMIT 10
        ];
        List<Task> tasks = [
            SELECT Subject, ActivityDate, Description, Status, Owner.Name
            FROM Task
            WHERE WhatId = :accountId AND ActivityDate = LAST_N_DAYS:180
            ORDER BY ActivityDate DESC LIMIT 10
        ];
        String userPrompt = 'Account: ' + acc.Name + '\n';
        userPrompt += 'Meetings (' + events.size() + '):\n';
        for (Event e : events) {
            userPrompt += '- ' + String.valueOf(e.ActivityDateTime) + ': ' + e.Subject
                + ' (Owner: ' + (e.Owner != null ? e.Owner.Name : 'Unknown') + ')'
                + (e.Description != null ? ' — ' + e.Description : '') + '\n';
        }
        userPrompt += 'Tasks (' + tasks.size() + '):\n';
        for (Task t : tasks) {
            userPrompt += '- ' + String.valueOf(t.ActivityDate) + ': ' + t.Subject
                + ' [' + t.Status + ']'
                + ' (Owner: ' + (t.Owner != null ? t.Owner.Name : 'Unknown') + ')'
                + (t.Description != null ? ' — ' + t.Description : '') + '\n';
        }
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.isPreview = false;
            ConnectApi.EinsteinLlmAdditionalConfigInput cfg = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            cfg.applicationName = 'PromptBuilderPreview';
            input.additionalConfig = cfg;
            ConnectApi.WrappedValue sysVal = new ConnectApi.WrappedValue();
            sysVal.value = 'You are a private equity analyst. Summarize the following CRM interactions with this portfolio company. Write 2-4 short bullet points covering: what topics were discussed, who was involved, and any notable next steps. Be concise and factual. Return plain text only — no JSON, no markdown, no code blocks.';
            ConnectApi.WrappedValue userVal = new ConnectApi.WrappedValue();
            userVal.value = userPrompt;
            input.inputParams = new Map<String, ConnectApi.WrappedValue>{
                'Input:SystemPrompt' => sysVal,
                'Input:UserPrompt' => userVal
            };
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Account_Analysis_Relationship_Health', input);
            if (output == null || output.generations == null || output.generations.isEmpty()) {
                return null;
            }
            String text = output.generations[0].text;
            if (text != null) {
                text = text.trim();
                if (text.startsWith('```')) {
                    Integer nl = text.indexOf('\n');
                    if (nl > -1) text = text.substring(nl + 1);
                    if (text.endsWith('```')) text = text.substring(0, text.length() - 3);
                    text = text.trim();
                }
            }
            return text;
        } catch (Exception ex) {
            return null;
        }
    }
}
