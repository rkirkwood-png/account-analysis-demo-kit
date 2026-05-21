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
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('RK_Interactions_Summary_Prompt', input);
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
}
