String demoAccountName = '*CodeRabbit';
String demoFundName = 'Demo Growth Fund I';

Map<String, Schema.SObjectType> globalMap = Schema.getGlobalDescribe();

Account demoAccount;
List<Account> accounts = [
    SELECT Id, Name, Industry, BillingCity, BillingState, BillingCountry, Website, Description, Type
    FROM Account
    WHERE Name = :demoAccountName
    LIMIT 1
];
if (accounts.isEmpty()) {
    demoAccount = new Account(
        Name = demoAccountName,
        Industry = 'Technology',
        BillingCity = 'San Francisco',
        BillingState = 'CA',
        BillingCountry = 'United States',
        Website = 'https://www.coderabbit.ai/',
        Description = 'Demo account for Account Analysis app.',
        Type = 'Mid-Market'
    );
    insert demoAccount;
    System.debug('Created demo account: ' + demoAccount.Id);
} else {
    demoAccount = accounts[0];
    demoAccount.Industry = 'Technology';
    demoAccount.BillingCity = 'San Francisco';
    demoAccount.BillingState = 'CA';
    demoAccount.BillingCountry = 'United States';
    demoAccount.Website = 'https://www.coderabbit.ai/';
    demoAccount.Description = 'Demo account for Account Analysis app.';
    demoAccount.Type = 'Mid-Market';
    update demoAccount;
    System.debug('Updated demo account: ' + demoAccount.Id);
}

List<Map<String, String>> contactDefs = new List<Map<String, String>>{
    new Map<String, String>{ 'name' => 'Laura Thomas', 'title' => 'CEO' },
    new Map<String, String>{ 'name' => 'Kristen Wang', 'title' => 'CFO' },
    new Map<String, String>{ 'name' => 'Boris Jabes', 'title' => 'CEO & Founder' },
    new Map<String, String>{ 'name' => 'Abigail Anderson', 'title' => 'Chief Product Officer' },
    new Map<String, String>{ 'name' => 'Zeynab Mohammed', 'title' => 'VP Operations' }
};

Map<String, Contact> existingContactsByName = new Map<String, Contact>();
for (Contact c : [
    SELECT Id, Name, Title
    FROM Contact
    WHERE AccountId = :demoAccount.Id
]) {
    existingContactsByName.put(c.Name, c);
}

List<Contact> contactsToUpsert = new List<Contact>();
for (Map<String, String> def : contactDefs) {
    String fullName = def.get('name');
    String[] parts = fullName.split(' ');
    String firstName = parts.size() > 1 ? parts[0] : null;
    String lastName = parts.size() > 1 ? parts[parts.size() - 1] : fullName;
    Contact existing = existingContactsByName.get(fullName);
    if (existing == null) {
        Contact c = new Contact();
        c.AccountId = demoAccount.Id;
        c.FirstName = firstName;
        c.LastName = lastName;
        c.Title = def.get('title');
        contactsToUpsert.add(c);
    } else {
        existing.Title = def.get('title');
        contactsToUpsert.add(existing);
    }
}
if (!contactsToUpsert.isEmpty()) {
    upsert contactsToUpsert;
}

Map<String, Task> existingTasksBySubject = new Map<String, Task>();
for (Task t : [
    SELECT Id, Subject, Status, Priority, ActivityDate
    FROM Task
    WHERE WhatId = :demoAccount.Id
]) {
    existingTasksBySubject.put(t.Subject, t);
}

List<Task> tasksToUpsert = new List<Task>();
List<Map<String, Object>> taskDefs = new List<Map<String, Object>>{
    new Map<String, Object>{ 'Subject' => 'Demo Follow-up Call', 'Status' => 'Completed', 'Priority' => 'High', 'OffsetDays' => -12 },
    new Map<String, Object>{ 'Subject' => 'Demo Diligence Checklist Review', 'Status' => 'Completed', 'Priority' => 'Normal', 'OffsetDays' => -7 }
};
for (Map<String, Object> def : taskDefs) {
    String subject = (String) def.get('Subject');
    Task t = existingTasksBySubject.containsKey(subject) ? existingTasksBySubject.get(subject) : new Task();
    t.Subject = subject;
    t.WhatId = demoAccount.Id;
    t.Status = (String) def.get('Status');
    t.Priority = (String) def.get('Priority');
    t.ActivityDate = Date.today().addDays((Integer) def.get('OffsetDays'));
    tasksToUpsert.add(t);
}
if (!tasksToUpsert.isEmpty()) {
    upsert tasksToUpsert;
}

Map<String, Event> existingEventsBySubject = new Map<String, Event>();
for (Event e : [
    SELECT Id, Subject, StartDateTime, EndDateTime
    FROM Event
    WHERE WhatId = :demoAccount.Id
]) {
    existingEventsBySubject.put(e.Subject, e);
}

List<Event> eventsToUpsert = new List<Event>();
List<Map<String, Object>> eventDefs = new List<Map<String, Object>>{
    new Map<String, Object>{ 'Subject' => 'Demo IC Prep Meeting', 'OffsetDays' => -10, 'DurationMins' => 45 },
    new Map<String, Object>{ 'Subject' => 'Demo Management Sync', 'OffsetDays' => -3, 'DurationMins' => 30 }
};
for (Map<String, Object> def : eventDefs) {
    String subject = (String) def.get('Subject');
    Event e = existingEventsBySubject.containsKey(subject) ? existingEventsBySubject.get(subject) : new Event();
    Datetime startDt = Datetime.now().addDays((Integer) def.get('OffsetDays'));
    Integer durationMins = (Integer) def.get('DurationMins');
    e.Subject = subject;
    e.WhatId = demoAccount.Id;
    e.StartDateTime = startDt;
    e.EndDateTime = startDt.addMinutes(durationMins);
    eventsToUpsert.add(e);
}
if (!eventsToUpsert.isEmpty()) {
    upsert eventsToUpsert;
}

Map<String, Case> existingCasesBySubject = new Map<String, Case>();
for (Case c : [
    SELECT Id, Subject, Status, Priority, Origin
    FROM Case
    WHERE AccountId = :demoAccount.Id
]) {
    existingCasesBySubject.put(c.Subject, c);
}

Case openCase = existingCasesBySubject.get('Demo Integration Question');
if (openCase == null) {
    openCase = new Case();
    openCase.AccountId = demoAccount.Id;
    openCase.Subject = 'Demo Integration Question';
}
openCase.Status = 'New';
openCase.Priority = 'Medium';
openCase.Origin = 'Web';
upsert openCase;

Map<String, Opportunity> existingOppsByName = new Map<String, Opportunity>();
for (Opportunity o : [
    SELECT Id, Name, StageName, Amount, CloseDate
    FROM Opportunity
    WHERE AccountId = :demoAccount.Id
]) {
    existingOppsByName.put(o.Name, o);
}

Opportunity activeOpp = existingOppsByName.get('Demo Series C Extension');
if (activeOpp == null) {
    activeOpp = new Opportunity();
    activeOpp.AccountId = demoAccount.Id;
    activeOpp.Name = 'Demo Series C Extension';
}
activeOpp.StageName = 'Proposal/Price Quote';
activeOpp.Amount = 8500000;
activeOpp.CloseDate = Date.today().addDays(45);
upsert activeOpp;

Opportunity lostOpp = existingOppsByName.get('Demo Prior Round');
if (lostOpp == null) {
    lostOpp = new Opportunity();
    lostOpp.AccountId = demoAccount.Id;
    lostOpp.Name = 'Demo Prior Round';
}
lostOpp.StageName = 'Closed Lost';
lostOpp.Amount = 3200000;
lostOpp.CloseDate = Date.today().addDays(-20);
upsert lostOpp;

if (globalMap.containsKey('Fund__c')) {
    Schema.DescribeSObjectResult fundDescribe = globalMap.get('Fund__c').getDescribe();
    Map<String, Schema.SObjectField> fundFields = fundDescribe.fields.getMap();
    String fundId;

    List<SObject> existingFunds = Database.query('SELECT Id, Name FROM Fund__c WHERE Name = :demoFundName LIMIT 1');
    SObject fundRecord = existingFunds.isEmpty() ? globalMap.get('Fund__c').newSObject() : existingFunds[0];
    fundRecord.put('Name', demoFundName);

    if (fundFields.containsKey('FINS_Private_Equity_Closed__c')) {
        fundRecord.put('FINS_Private_Equity_Closed__c', false);
    }
    if (fundFields.containsKey('FINS_Private_Equity_Fund_EIN__c')) {
        fundRecord.put('FINS_Private_Equity_Fund_EIN__c', '12-3456789');
    }
    if (fundFields.containsKey('FINS_Private_Equity_Management_Fee__c')) {
        fundRecord.put('FINS_Private_Equity_Management_Fee__c', 2);
    }
    if (fundFields.containsKey('FINS_Private_Equity_Target_Size__c')) {
        fundRecord.put('FINS_Private_Equity_Target_Size__c', 100000000);
    }
    if (fundFields.containsKey('FINS_Private_Equity_Term__c')) {
        fundRecord.put('FINS_Private_Equity_Term__c', 10);
    }
    if (fundFields.containsKey('FINS_Private_Equity_Total_Investments_Ma__c')) {
        fundRecord.put('FINS_Private_Equity_Total_Investments_Ma__c', 48000000);
    }

    if (existingFunds.isEmpty()) {
        insert fundRecord;
    } else {
        update fundRecord;
    }
    fundId = (String) fundRecord.get('Id');
    System.debug('Seeded fund record: ' + fundId);

    if (globalMap.containsKey('FINS_Investment__c')) {
        Schema.DescribeSObjectResult invDescribe = globalMap.get('FINS_Investment__c').getDescribe();
        Map<String, Schema.SObjectField> invFields = invDescribe.fields.getMap();
        if (invFields.containsKey('FINS_Private_Equity_Fund__c')) {
            List<Map<String, Object>> investmentDefs = new List<Map<String, Object>>{
                new Map<String, Object>{ 'Name' => 'Demo Investment - Vector AI', 'Amount' => 18000000, 'Type' => 'Institutional Investor', 'Called' => 12000000, 'Remaining' => 6000000 },
                new Map<String, Object>{ 'Name' => 'Demo Investment - Harbor Data', 'Amount' => 14000000, 'Type' => 'Family Office', 'Called' => 7000000, 'Remaining' => 7000000 },
                new Map<String, Object>{ 'Name' => 'Demo Investment - OpsPilot', 'Amount' => 16000000, 'Type' => 'Corporate Investor', 'Called' => 9000000, 'Remaining' => 7000000 }
            };

            Map<String, SObject> existingInvByName = new Map<String, SObject>();
            for (SObject inv : Database.query('SELECT Id, Name FROM FINS_Investment__c WHERE FINS_Private_Equity_Fund__c = :fundId')) {
                existingInvByName.put((String) inv.get('Name'), inv);
            }

            List<SObject> investmentsToUpsert = new List<SObject>();
            for (Map<String, Object> def : investmentDefs) {
                String invName = (String) def.get('Name');
                SObject invRecord = existingInvByName.containsKey(invName)
                    ? existingInvByName.get(invName)
                    : globalMap.get('FINS_Investment__c').newSObject();

                invRecord.put('Name', invName);
                invRecord.put('FINS_Private_Equity_Fund__c', fundId);
                if (invFields.containsKey('FINS_Private_Equity_Amount__c')) {
                    invRecord.put('FINS_Private_Equity_Amount__c', def.get('Amount'));
                }
                if (invFields.containsKey('Investor_Type__c')) {
                    invRecord.put('Investor_Type__c', def.get('Type'));
                }
                if (invFields.containsKey('Capital_Called__c')) {
                    invRecord.put('Capital_Called__c', def.get('Called'));
                }
                if (invFields.containsKey('Capital_Remaining__c')) {
                    invRecord.put('Capital_Remaining__c', def.get('Remaining'));
                }
                investmentsToUpsert.add(invRecord);
            }
            if (!investmentsToUpsert.isEmpty()) {
                upsert investmentsToUpsert;
            }
        }
    }
}

System.debug('Demo data seed complete.');
