ConnectApi.EinsteinPromptTemplateGenerationsInput input = new
ConnectApi.EinsteinPromptTemplateGenerationsInput();
input.isPreview = false;
ConnectApi.EinsteinLlmAdditionalConfigInput cfg = new 
ConnectApi.EinsteinLlmAdditionalConfigInput();
cfg.applicationName = 'PromptBuilderPreview';
input.additionalConfig = cfg;
ConnectApi.WrappedValue systemValue = new ConnectApi.WrappedValue();
systemValue.value = 'You are a research analyst. Return JSON only.';
ConnectApi.WrappedValue userValue = new ConnectApi.WrappedValue();
userValue.value = 'Test company: Acme Corp';
input.inputParams = new Map<String, ConnectApi.WrappedValue>{
    'Input:SystemPrompt' => systemValue,
    'Input:UserPrompt' => userValue
};
ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Account_Analysis_Research',
 input);
System.debug('OUTPUT: ' + output);
