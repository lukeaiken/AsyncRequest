@IsTest
private class AsyncRequestProcessorTest {

    @IsTest static void testEnqueueJob() {
        AsyncRequest__c asyncRequest = new AsyncRequest__c(AsyncType__c = TestProcessor.class.getName());

        insert asyncRequest;

        Test.startTest();
        AsyncRequestProcessor.enqueueJob(null, null, TestProcessor.class.getName());
        Test.stopTest();
    }

    @IsTest static void testTryToQueue() {
        AsyncRequest__c asyncRequest = new AsyncRequest__c(AsyncType__c = TestProcessor.class.getName());

        insert asyncRequest;

        Test.startTest();
        AsyncRequestProcessor.tryToQueue(null, null, TestProcessor.class.getName());
        Test.stopTest();
    }

    @IsTest static void testTryToQueueWithRequestId() {
        AsyncRequest__c asyncRequest = new AsyncRequest__c(AsyncType__c = TestProcessor.class.getName());

        insert asyncRequest;

        Test.startTest();
        AsyncRequestProcessor.tryToQueue(null, asyncRequest.Id, TestProcessor.class.getName());
        Test.stopTest();
    }

    @IsTest static void testParentWithSingleChildRequest() {
        AsyncRequest__c parentAsyncRequest = new AsyncRequest__c(
                AsyncType__c = TestProcessor.class.getName(),
                StartDatetime__c = Datetime.now().addDays(-1));

        insert parentAsyncRequest;

        AsyncRequest__c childAsyncRequest = new AsyncRequest__c(AsyncType__c = TestProcessor.class.getName());
        childAsyncRequest.ParentRequest__c = parentAsyncRequest.Id;

        insert childAsyncRequest;

        Test.startTest();
        AsyncRequestProcessor.testChildContext = true;
        AsyncRequestProcessor.enqueueJob(null, parentAsyncRequest.Id, TestProcessor.class.getName());
        Test.stopTest();
    }

    @IsTest static void testParentWithMultipleChildRequest() {
        AsyncRequest__c parentAsyncRequest = new AsyncRequest__c(
                AsyncType__c = TestProcessor.class.getName(),
                StartDatetime__c = Datetime.now().addDays(-1)
        );
        insert parentAsyncRequest;

        List<AsyncRequest__c> childRequests = new List<AsyncRequest__c>();

        for (Integer i = 0; i < 2; i++) {
            childRequests.add(new AsyncRequest__c(
                    AsyncType__c = TestProcessor.class.getName(),
                    ParentRequest__c = parentAsyncRequest.Id));
        }

        insert childRequests;

        Test.startTest();
        AsyncRequestProcessor.testChildContext = true;
        AsyncRequestProcessor.enqueueJob(null, parentAsyncRequest.Id, TestProcessor.class.getName());
        Test.stopTest();
    }

    @IsTest static void testExceptionHandling() {
        AsyncRequestProcessor.testExpectException = true;

        AsyncRequest__c asyncRequest = new AsyncRequest__c(
                AsyncType__c = TestProcessor.class.getName(),
                Params__c = 'TestProcessorException');

        insert asyncRequest;

        Test.startTest();
        AsyncRequestProcessor.enqueueJob(null, null, TestProcessor.class.getName());
        Test.stopTest();
    }
}