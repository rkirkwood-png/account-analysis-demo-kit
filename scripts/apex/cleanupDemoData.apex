String demoAccountName = '*CodeRabbit';
String demoFundName = 'Demo Growth Fund I';
Set<String> demoInvestmentNames = new Set<String>{
    'Demo Investment - Vector AI',
    'Demo Investment - Harbor Data',
    'Demo Investment - OpsPilot'
};

Map<String, Schema.SObjectType> globalMap = Schema.getGlobalDescribe();

List<Account> accounts = [SELECT Id FROM Account WHERE Name = :demoAccountName];
Set<Id> accountIds = new Set<Id>();
for (Account a : accounts) {
    accountIds.add(a.Id);
}

if (!accountIds.isEmpty()) {
    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId IN :accountIds];
    if (!opps.isEmpty()) delete opps;

    List<Case> cases = [SELECT Id FROM Case WHERE AccountId IN :accountIds];
    if (!cases.isEmpty()) delete cases;

    List<Event> events = [SELECT Id FROM Event WHERE WhatId IN :accountIds];
    if (!events.isEmpty()) delete events;

    List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :accountIds];
    if (!tasks.isEmpty()) delete tasks;

    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId IN :accountIds];
    if (!contacts.isEmpty()) delete contacts;

    List<Account> accToDelete = [SELECT Id FROM Account WHERE Id IN :accountIds];
    if (!accToDelete.isEmpty()) delete accToDelete;
}

if (globalMap.containsKey('Fund__c')) {
    List<SObject> fundRows = Database.query('SELECT Id FROM Fund__c WHERE Name = :demoFundName');
    Set<Id> fundIds = new Set<Id>();
    for (SObject f : fundRows) {
        fundIds.add((Id) f.get('Id'));
    }

    if (!fundIds.isEmpty() && globalMap.containsKey('FINS_Investment__c')) {
        Schema.DescribeSObjectResult invDescribe = globalMap.get('FINS_Investment__c').getDescribe();
        Map<String, Schema.SObjectField> invFields = invDescribe.fields.getMap();
        if (invFields.containsKey('FINS_Private_Equity_Fund__c')) {
            List<SObject> invRows = Database.query(
                'SELECT Id, Name FROM FINS_Investment__c WHERE FINS_Private_Equity_Fund__c IN :fundIds'
            );
            List<SObject> invToDelete = new List<SObject>();
            for (SObject inv : invRows) {
                String name = (String) inv.get('Name');
                if (name != null && demoInvestmentNames.contains(name)) {
                    invToDelete.add(inv);
                }
            }
            if (!invToDelete.isEmpty()) {
                delete invToDelete;
            }
        }
    }

    List<SObject> fundsToDelete = Database.query('SELECT Id FROM Fund__c WHERE Name = :demoFundName');
    if (!fundsToDelete.isEmpty()) {
        delete fundsToDelete;
    }
}

System.debug('Demo cleanup complete.');
