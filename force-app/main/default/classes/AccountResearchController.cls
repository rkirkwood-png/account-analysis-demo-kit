public with sharing class AccountResearchController {

    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchTerm) {
        String query = '%' + searchTerm + '%';
        return [SELECT Id, Name, Industry, BillingCity FROM Account
                WHERE Name LIKE :query ORDER BY Name LIMIT 10];
    }

    @AuraEnabled(cacheable=false)
    public static String getAccountResearch(Id accountId) {
        Account acc = [
            SELECT Id, Name, Industry, BillingCity, BillingState, BillingCountry,
                   Website, Description, NumberOfEmployees, AnnualRevenue,
                   Type, OwnerId
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        List<Contact> contacts = [
            SELECT Name, Title FROM Contact
            WHERE AccountId = :accountId
            AND Title != null
            ORDER BY Title
            LIMIT 5
        ];
        try {
            String prompt = buildResearchPrompt(acc, contacts);
            String rawResponse = invokeEinstein(
                'You are a private equity research analyst. Using the Salesforce data provided plus your knowledge of this company, return a JSON object only — no explanation, no markdown. The JSON must have these exact keys: overview (string), industry (string), headquarters (string), products (string), targetMarket (string), website (string), executives (array of strings in format "Name — Title"), news (array of objects with keys: date, title, summary, url — use your training knowledge for recent news, note it may not be current; url must be the source article link as a string, or an empty string if unknown).',
                prompt
            );
            if (String.isBlank(rawResponse)) {
                return getAccountResearchFallback(acc, contacts, accountId);
            }
            return stripMarkdownFences(rawResponse);
        } catch (Exception ex) {
            return getAccountResearchFallback(acc, contacts, accountId);
        }
    }

    private static String buildResearchPrompt(Account acc, List<Contact> contacts) {
        String headquarters = getHeadquarters(acc);
        String prompt = '';
        prompt += 'Company research request from Salesforce CRM data.\n';
        prompt += 'Account Name: ' + safeText(acc.Name) + '\n';
        prompt += 'Industry: ' + safeText(acc.Industry) + '\n';
        prompt += 'Headquarters: ' + safeText(headquarters) + '\n';
        prompt += 'Website: ' + safeText(acc.Website) + '\n';
        prompt += 'Description: ' + safeText(acc.Description) + '\n';
        prompt += 'EmployeeCount: ' + safeText(String.valueOf(acc.NumberOfEmployees)) + '\n';
        prompt += 'AnnualRevenue: ' + safeText(String.valueOf(acc.AnnualRevenue)) + '\n';
        prompt += 'Contacts with titles (' + contacts.size() + '):\n';
        for (Contact c : contacts) {
            prompt += '- ' + safeText(c.Name) + ' — ' + safeText(c.Title) + '\n';
        }
        prompt += 'Return JSON only with required keys.';
        return prompt;
    }

    private static String getAccountResearchFallback(Account acc, List<Contact> contacts, Id accountId) {
        List<String> executives = new List<String>();
        for (Contact c : contacts) {
            executives.add(c.Name + ' — ' + c.Title);
        }
        if (executives.isEmpty()) {
            executives.add('No contacts with titles found in Salesforce.');
        }
        String hq = getHeadquarters(acc);
        String overview = acc.Description != null
            ? acc.Description
            : acc.Name + ' is a ' + (acc.Industry != null ? acc.Industry : 'company') +
              ' based in ' + hq + '.';
        Map<String, Object> dealSnapshot = getLatestDealSnapshot(accountId);
        Map<String, Object> result = new Map<String, Object>{
            'overview' => overview,
            'industry' => acc.Industry != null ? acc.Industry : 'Not on record',
            'headquarters' => hq,
            'products' => 'See account description for details',
            'targetMarket' => acc.Type != null ? acc.Type : 'General market',
            'website' => acc.Website != null ? acc.Website : 'Not on record',
            'executives' => executives,
            'news' => new List<Object>{
                new Map<String, Object>{
                    'date' => String.valueOf(Date.today()),
                    'title' => 'No LLM research available',
                    'summary' => 'Returned Salesforce-only fallback content because Einstein generation was unavailable.',
                    'url' => ''
                }
            },
            'dealName' => dealSnapshot.get('dealName')
        };
        return JSON.serialize(result);
    }

    private static String getHeadquarters(Account acc) {
        String hq = '';
        if (acc.BillingCity != null) hq += acc.BillingCity;
        if (acc.BillingState != null) hq += (hq != '' ? ', ' : '') + acc.BillingState;
        if (acc.BillingCountry != null) hq += (hq != '' ? ', ' : '') + acc.BillingCountry;
        return hq == '' ? 'Not on record' : hq;
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
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Account_Analysis_Research', input);
            if (output == null || output.generations == null || output.generations.isEmpty()) {
                return null;
            }
            return output.generations[0].text;
        } catch (Exception ex) {
            return null;
        }
    }

    private static Map<String, Object> getLatestDealSnapshot(Id accountId) {
        Map<String, Object> snapshot = new Map<String, Object>{
            'dealName' => 'No Financial Deal found',
            'dealStage' => 'Not available',
            'processOwner' => 'Not available',
            'daysInStage' => 0,
            'nextMilestone' => 'Capture milestone fields on Financial Deal',
            'dataQuality' => 'Using Account and Contact data. Financial_Deal__c was not found in scope.'
        };

        Map<String, Schema.SObjectType> globalMap = Schema.getGlobalDescribe();
        if (!globalMap.containsKey('Financial_Deal__c')) {
            return snapshot;
        }

        Schema.DescribeSObjectResult dealDescribe = globalMap.get('Financial_Deal__c').getDescribe();
        Map<String, Schema.SObjectField> fieldMap = dealDescribe.fields.getMap();

        String accountLookupField = resolveAccountLookupField(fieldMap);
        List<String> selectFields = new List<String>{ 'Id', 'Name', 'OwnerId', 'LastModifiedDate' };
        addIfPresent(selectFields, fieldMap, new List<String>{ 'Stage__c', 'Deal_Stage__c', 'Status__c' });
        addIfPresent(selectFields, fieldMap, new List<String>{ 'Stage_Start_Date__c', 'Current_Stage_Date__c' });
        addIfPresent(selectFields, fieldMap, new List<String>{ 'Next_Milestone__c', 'Upcoming_Milestone__c' });
        if (accountLookupField != null) {
            selectFields.add(accountLookupField);
        }

        String soql = 'SELECT ' + String.join(selectFields, ',') + ' FROM Financial_Deal__c';
        if (accountLookupField != null) {
            soql += ' WHERE ' + accountLookupField + ' = :accountId';
        }
        soql += ' ORDER BY LastModifiedDate DESC LIMIT 1';

        List<SObject> deals = Database.query(soql);
        if (deals.isEmpty()) {
            snapshot.put(
                'dataQuality',
                'Financial_Deal__c is available, but no deal record was found for this account mapping.'
            );
            return snapshot;
        }

        SObject deal = deals[0];
        snapshot.put('dealName', String.valueOf(deal.get('Name')));
        snapshot.put('dealStage', getStringFromCandidates(deal, new List<String>{ 'Stage__c', 'Deal_Stage__c', 'Status__c' }, 'Not available'));
        snapshot.put('nextMilestone', getStringFromCandidates(deal, new List<String>{ 'Next_Milestone__c', 'Upcoming_Milestone__c' }, 'Capture milestone fields on Financial Deal'));

        Id ownerId = (Id) deal.get('OwnerId');
        if (ownerId != null) {
            User owner = [SELECT Name FROM User WHERE Id = :ownerId LIMIT 1];
            snapshot.put('processOwner', owner.Name);
        }

        Integer daysInStage = 0;
        Date stageDate = (Date) getFromCandidates(deal, new List<String>{ 'Stage_Start_Date__c', 'Current_Stage_Date__c' });
        if (stageDate != null) {
            daysInStage = stageDate.daysBetween(Date.today());
        } else {
            Datetime lastTouched = (Datetime) deal.get('LastModifiedDate');
            daysInStage = lastTouched == null ? 0 : lastTouched.date().daysBetween(Date.today());
        }
        snapshot.put('daysInStage', daysInStage);
        snapshot.put('dataQuality', 'Financial_Deal__c context loaded from CRM.');
        return snapshot;
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

    private static String getStringFromCandidates(
        SObject record,
        List<String> candidateFields,
        String fallback
    ) {
        Object value = getFromCandidates(record, candidateFields);
        return value == null ? fallback : String.valueOf(value);
    }
}