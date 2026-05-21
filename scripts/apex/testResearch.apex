Account acc = [SELECT Id, Name FROM Account LIMIT 1];
System.debug('Testing account: ' + acc.Name);
try {
    String result = AccountResearchController.getAccountResearch(acc.Id);
    System.debug('RESULT: ' + result);
} catch(Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('STACK: ' + e.getStackTraceString());
}
