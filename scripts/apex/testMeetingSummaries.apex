Account acc = [SELECT Id, Name FROM Account LIMIT 1];
System.debug('Testing account: ' + acc.Name + ' | ' + acc.Id);
try {
    String result = MeetingPrepController.getMeetingSummaries(acc.Id);
    System.debug('RESULT: ' + result);
} catch(Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
