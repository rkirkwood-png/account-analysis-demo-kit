Account acc = [SELECT Id, Name FROM Account LIMIT 1];
System.debug('Account: ' + acc.Name + ' | ' + acc.Id);
ConnectApi.EinsteinPromptTemplateGenerationsInput input = new 
ConnectApi.EinsteinPromptTemplateGenerationsInput();
input.isPreview = false;
ConnectApi.EinsteinLlmAdditionalConfigInput cfg = new 
ConnectApi.EinsteinLlmAdditionalConfigInput();
cfg.applicationName = 'PromptBuilderPreview';
input.additionalConfig = cfg;
ConnectApi.WrappedValue accountValue = new ConnectApi.WrappedValue();
accountValue.value = acc;
input.inputParams = new Map<String, ConnectApi.WrappedValue>{
    'Input:Account' => accountValue
};
ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Headless_Meeting_Summaries', input);
System.debug('GENERATIONS: ' + output.generations);
System.debug('ERRORS: ' + output.generationErrors);
