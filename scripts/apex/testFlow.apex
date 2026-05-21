List<FlowDefinitionView> flows = [SELECT ApiName, Label FROM FlowDefinitionView WHERE ApiName = 
'RK_Prompt_Flow_Get_Interactions'];
System.debug('FLOW COUNT: ' + flows.size());
if (!flows.isEmpty()) System.debug('FLOW: ' + flows[0].Label);
