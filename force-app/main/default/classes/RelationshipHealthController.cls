public with sharing class RelationshipHealthController {

    @AuraEnabled(cacheable=false)
    public static String getRelationshipHealth(Id accountId) {
        List<Task> tasks = [
            SELECT Id, Subject, Status, Priority, ActivityDate, Owner.Name
            FROM Task
            WHERE WhatId = :accountId AND ActivityDate = LAST_N_DAYS:90
            ORDER BY ActivityDate DESC
        ];
        List<Event> events = [
            SELECT Id, Subject, ActivityDateTime, DurationInMinutes, Owner.Name
            FROM Event
            WHERE WhatId = :accountId AND ActivityDateTime = LAST_N_DAYS:90
            ORDER BY ActivityDateTime DESC
        ];
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Priority, Status, Origin, CreatedDate
            FROM Case
            WHERE AccountId = :accountId AND IsClosed = false
            ORDER BY CreatedDate DESC
        ];
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Amount, CloseDate, Probability
            FROM Opportunity
            WHERE AccountId = :accountId AND IsClosed = false
            ORDER BY CloseDate ASC NULLS LAST
        ];
        List<Opportunity> lostOpps = [
            SELECT Id, Name, Amount, CloseDate
            FROM Opportunity
            WHERE AccountId = :accountId AND StageName = 'Closed Lost'
            AND CloseDate = LAST_N_DAYS:90
        ];
        Map<String, Object> dealContext = getDealContext(accountId);
        try {
            String prompt = buildLlmPrompt(accountId, tasks, events, cases, opps, lostOpps, dealContext);
            String rawResponse = invokeEinstein(
                'You are a private equity relationship analyst. Analyze the CRM data provided and return a JSON object only — no explanation, no markdown. The JSON must have these exact keys: score (integer 0-100), status (string: Healthy, Needs Attention, or At Risk), trend (string: Improving, Stable, or Declining), renewalLikelihood (string: Likely, Moderate, or Unlikely), insights (array of 3-4 strings), actions (array of 2-3 actionable strings).',
                prompt
            );
            if (String.isBlank(rawResponse)) {
                return getRelationshipHealthFallback(tasks, events, cases, opps, lostOpps, dealContext);
            }
            return stripMarkdownFences(rawResponse);
        } catch (Exception ex) {
            return getRelationshipHealthFallback(tasks, events, cases, opps, lostOpps, dealContext);
        }
    }

    private static String buildLlmPrompt(
        Id accountId,
        List<Task> tasks,
        List<Event> events,
        List<Case> cases,
        List<Opportunity> opps,
        List<Opportunity> lostOpps,
        Map<String, Object> dealContext
    ) {
        String prompt = '';
        prompt += 'Analyze account relationship health from CRM activity over the last 90 days.\n';
        prompt += 'AccountId: ' + String.valueOf(accountId) + '\n';
        prompt += 'Tasks (' + tasks.size() + '):\n';
        for (Task t : tasks) {
            prompt += '- Id=' + String.valueOf(t.Id)
                + ', Subject=' + safeText(t.Subject)
                + ', Status=' + safeText(t.Status)
                + ', Priority=' + safeText(t.Priority)
                + ', DueDate=' + safeText(String.valueOf(t.ActivityDate))
                + ', Owner=' + safeText(t.Owner == null ? null : t.Owner.Name) + '\n';
        }
        prompt += 'Events (' + events.size() + '):\n';
        for (Event e : events) {
            prompt += '- Id=' + String.valueOf(e.Id)
                + ', Subject=' + safeText(e.Subject)
                + ', DateTime=' + safeText(String.valueOf(e.ActivityDateTime))
                + ', DurationMinutes=' + safeText(String.valueOf(e.DurationInMinutes))
                + ', Owner=' + safeText(e.Owner == null ? null : e.Owner.Name) + '\n';
        }
        prompt += 'Open Cases (' + cases.size() + '):\n';
        for (Case c : cases) {
            prompt += '- CaseNumber=' + safeText(c.CaseNumber)
                + ', Subject=' + safeText(c.Subject)
                + ', Priority=' + safeText(c.Priority)
                + ', Status=' + safeText(c.Status)
                + ', Origin=' + safeText(c.Origin)
                + ', CreatedDate=' + safeText(String.valueOf(c.CreatedDate)) + '\n';
        }
        prompt += 'Open Opportunities (' + opps.size() + '):\n';
        for (Opportunity o : opps) {
            prompt += '- Id=' + String.valueOf(o.Id)
                + ', Name=' + safeText(o.Name)
                + ', Stage=' + safeText(o.StageName)
                + ', Amount=' + safeText(String.valueOf(o.Amount))
                + ', Probability=' + safeText(String.valueOf(o.Probability))
                + ', CloseDate=' + safeText(String.valueOf(o.CloseDate)) + '\n';
        }
        prompt += 'Closed Lost Opportunities in last 90 days (' + lostOpps.size() + '):\n';
        for (Opportunity lost : lostOpps) {
            prompt += '- Id=' + String.valueOf(lost.Id)
                + ', Name=' + safeText(lost.Name)
                + ', Amount=' + safeText(String.valueOf(lost.Amount))
                + ', CloseDate=' + safeText(String.valueOf(lost.CloseDate)) + '\n';
        }
        prompt += 'Deal Context:\n';
        prompt += '- activeDeals=' + safeText(String.valueOf(dealContext.get('activeDeals'))) + '\n';
        prompt += '- daysInCurrentStage=' + safeText(String.valueOf(dealContext.get('daysInCurrentStage'))) + '\n';
        prompt += '- hasStalledDeal=' + safeText(String.valueOf(dealContext.get('hasStalledDeal'))) + '\n';
        prompt += 'Return JSON only with the required keys.';
        return prompt;
    }

    private static String getRelationshipHealthFallback(
        List<Task> tasks,
        List<Event> events,
        List<Case> cases,
        List<Opportunity> opps,
        List<Opportunity> lostOpps,
        Map<String, Object> dealContext
    ) {
        Integer score = 100;
        Integer activeDeals = (Integer) dealContext.get('activeDeals');
        Integer daysInCurrentStage = (Integer) dealContext.get('daysInCurrentStage');
        Boolean hasStalledDeal = (Boolean) dealContext.get('hasStalledDeal');
        if (events.size() == 0 && tasks.size() == 0) score -= 30;
        else if (events.size() + tasks.size() < 3) score -= 15;
        if (cases.size() > 3) score -= 20;
        else if (cases.size() > 0) score -= 10;
        if (lostOpps.size() > 0) score -= 20;
        if (hasStalledDeal) score -= 15;
        if (activeDeals == 0) score -= 10;
        score = Math.max(0, Math.min(100, score));
        String status = score >= 70 ? 'Healthy' : score >= 40 ? 'Needs Attention' : 'At Risk';
        String trend = hasStalledDeal || lostOpps.size() > 0 ? 'Declining' : events.size() > 5 ? 'Improving' : 'Stable';
        String renewalLikelihood = score >= 70 ? 'Likely' : score >= 40 ? 'Moderate' : 'Unlikely';
        List<String> insights = new List<String>();
        if (tasks.size() == 0 && events.size() == 0) {
            insights.add('No activity recorded in the last 90 days; coverage risk is elevated.');
        } else {
            insights.add(events.size() + ' meetings and ' + tasks.size() + ' tasks logged in the last 90 days.');
        }
        if (activeDeals > 0) insights.add(activeDeals + ' Financial Deal record(s) are in process.');
        if (hasStalledDeal) insights.add('Current deal appears stalled due to stage aging.');
        if (cases.size() > 0) insights.add(cases.size() + ' open case(s) may impact relationship quality.');
        while (insights.size() > 4) {
            insights.remove(insights.size() - 1);
        }
        List<String> actions = new List<String>();
        if (events.size() == 0) actions.add('Schedule a management touchpoint within 7 days.');
        if (hasStalledDeal) actions.add('Escalate stage blockers and assign owners.');
        if (cases.size() > 0) actions.add('Resolve high-priority open support cases.');
        if (actions.isEmpty()) actions.add('Maintain current execution cadence.');
        while (actions.size() > 3) {
            actions.remove(actions.size() - 1);
        }
        Map<String, Object> result = new Map<String, Object>{
            'score' => score,
            'status' => status,
            'trend' => trend,
            'renewalLikelihood' => renewalLikelihood,
            'insights' => insights,
            'actions' => actions
        };
        return JSON.serialize(result);
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
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Account_Analysis_Relationship_Health', input);
            if (output == null || output.generations == null || output.generations.isEmpty()) {
                return null;
            }
            return output.generations[0].text;
        } catch (Exception ex) {
            return null;
        }
    }

    private static Map<String, Object> getDealContext(Id accountId) {
        Map<String, Object> context = new Map<String, Object>{
            'activeDeals' => 0,
            'daysInCurrentStage' => 0,
            'hasStalledDeal' => false
        };

        Map<String, Schema.SObjectType> globalMap = Schema.getGlobalDescribe();
        if (!globalMap.containsKey('Financial_Deal__c')) {
            return context;
        }

        Schema.DescribeSObjectResult dealDescribe = globalMap.get('Financial_Deal__c').getDescribe();
        Map<String, Schema.SObjectField> fieldMap = dealDescribe.fields.getMap();
        String accountLookupField = resolveAccountLookupField(fieldMap);
        if (accountLookupField == null) {
            return context;
        }

        List<String> selectFields = new List<String>{ 'Id', 'LastModifiedDate', accountLookupField };
        addIfPresent(selectFields, fieldMap, new List<String>{ 'Stage_Start_Date__c', 'Current_Stage_Date__c' });
        addIfPresent(selectFields, fieldMap, new List<String>{ 'Is_Closed__c', 'Active__c' });
        String soql = 'SELECT ' + String.join(selectFields, ',') +
            ' FROM Financial_Deal__c WHERE ' + accountLookupField + ' = :accountId ORDER BY LastModifiedDate DESC LIMIT 25';

        List<SObject> deals = Database.query(soql);
        if (deals.isEmpty()) {
            return context;
        }

        context.put('activeDeals', deals.size());

        SObject latestDeal = deals[0];
        Date stageDate = (Date) getFromCandidates(latestDeal, new List<String>{ 'Stage_Start_Date__c', 'Current_Stage_Date__c' });
        Integer daysInCurrentStage;
        if (stageDate != null) {
            daysInCurrentStage = stageDate.daysBetween(Date.today());
        } else {
            Datetime lastTouched = (Datetime) latestDeal.get('LastModifiedDate');
            daysInCurrentStage = lastTouched == null ? 0 : lastTouched.date().daysBetween(Date.today());
        }

        context.put('daysInCurrentStage', daysInCurrentStage);
        context.put('hasStalledDeal', daysInCurrentStage > 45);
        return context;
    }

    private static String resolveAccountLookupField(Map<String, Schema.SObjectField> fieldMap) {
        List<String> commonNames = new List<String>{ 'Account__c', 'Target_Account__c', 'Company__c', 'AccountId' };
        for (String name : commonNames) {
            if (fieldMap.containsKey(name)) {
                return name;
            }
        }

        for (String name : fieldMap.keySet()) {
            Schema.DescribeFieldResult describe = fieldMap.get(name).getDescribe();
            if (describe.getType() == Schema.DisplayType.REFERENCE) {
                for (Schema.SObjectType ref : describe.getReferenceTo()) {
                    if (ref.getDescribe().getName() == 'Account') {
                        return name;
                    }
                }
            }
        }
        return null;
    }

    private static void addIfPresent(
        List<String> selectFields,
        Map<String, Schema.SObjectField> fieldMap,
        List<String> candidateFields
    ) {
        for (String fieldName : candidateFields) {
            if (fieldMap.containsKey(fieldName)) {
                selectFields.add(fieldName);
                return;
            }
        }
    }

    private static Object getFromCandidates(SObject record, List<String> candidateFields) {
        Map<String, Schema.SObjectField> fieldLookup = record.getSObjectType().getDescribe().fields.getMap();
        for (String fieldName : candidateFields) {
            if (fieldLookup.containsKey(fieldName)) {
                return record.get(fieldName);
            }
        }
        return null;
    }
}