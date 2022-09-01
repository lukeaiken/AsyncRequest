@IsTest
private class AsyncRequestTriggerHandlerTest {
    @IsTest static void testInsertRequest() {
        AsyncRequest__c asyncRequest = new AsyncRequest__c();
        asyncRequest.AsyncType__c = TestProcessor.class.getName();

        Test.startTest();

        insert asyncRequest;

        Test.stopTest();

        System.assert(AsyncRequestTriggerHandler.asyncTypesToEnqueue.contains(TestProcessor.class.getName()));
    }

    @IsTest static void testRetryAsyncRequests() {
        AsyncRequest__c asyncRequest = new AsyncRequest__c();
        asyncRequest.AsyncType__c = TestProcessor.class.getName();

        insert asyncRequest;

        asyncRequest.Error__c = true;
        update asyncRequest;

        Test.startTest();

        asyncRequest.Error__c = false;
        update asyncRequest;

        Test.stopTest();

        System.assert(AsyncRequestTriggerHandler.asyncTypesToEnqueue.contains(TestProcessor.class.getName()));
    }
}