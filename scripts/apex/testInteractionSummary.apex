Account acc = [SELECT Id, Name FROM Account WHERE Name LIKE '%CodeRabbit%' LIMIT 1];
System.debug('Account: ' + acc.Name + ' | ' + acc.Id);
ConnectApi.EinsteinPromptTemplateGenerationsInput input = new 
ConnectApi.EinsteinPromptTemplateGenerationsInput();
input.isPreview = false;
ConnectApi.EinsteinLlmAdditionalConfigInput cfg = new 
ConnectApi.EinsteinLlmAdditionalConfigInput();
cfg.applicationName = 'PromptBuilderPreview';
input.additionalConfig = cfg;
ConnectApi.WrappedValue sysVal = new ConnectApi.WrappedValue();
sysVal.value = 'You are a private equity analyst. Summarize CRM interactions in 2-4 bullet points.';
ConnectApi.WrappedValue userVal = new ConnectApi.WrappedValue();
userVal.value = 'Account: ' + acc.Name;
input.inputParams = new Map<String, ConnectApi.WrappedValue>{
    'Input:SystemPrompt' => sysVal,
    'Input:UserPrompt' => userVal
};
ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Account_Analysis_Relationship_Health', 
input);
System.debug('GENERATIONS: ' + output.generations);
System.debug('ERRORS: ' + output.generationErrors);
