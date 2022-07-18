@IsTest
private class DataRetentionEvalProcessorTest {
    @TestSetup static void testSetup() {
        Account account = new Account(Name = 'Test Account');
        insert account;
    }

    @IsTest static void testProcessRequest() {
        DataRetentionPolicy__mdt defaultSetting = new DataRetentionPolicyMdt('Account').getConfig();

        DataRetentionPolicyMdt.testConfig = new DataRetentionPolicy__mdt(
                Active__c = true,
                Purge__c = true,
                DaysToRetain__c = 0,
                WhereClause__c = 'Name = \'Test Account\''
        );
        DataRetentionPolicyMdt.testObjApiName = 'Account';

        Test.startTest();

        DataRetentionEvalProcessor processor = new DataRetentionEvalProcessor();
        processor.processRequest(new AsyncRequest__c());

        Test.stopTest();
    }
}