@IsTest
private class AsyncRequestProcessorTest {
    private static final String TEST_TYPE = TestProcessor.class.getName();

    @TestSetup static void setup() {
        AsyncRequestTestUtil.createAsyncUser();
    }

    @IsTest static void testEnqueueJob() {
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequest__c asyncRequest = new AsyncRequest__c(AsyncType__c = TEST_TYPE);

            insert asyncRequest;

            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, null, TEST_TYPE);
            Test.stopTest();
        }
    }

    @IsTest static void testTryToQueue() {
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequest__c asyncRequest = new AsyncRequest__c(AsyncType__c = TEST_TYPE);

            insert asyncRequest;

            Test.startTest();
            AsyncRequestProcessor.tryToQueue(null, null, TEST_TYPE);
            Test.stopTest();
        }
    }

    @IsTest static void testTryToQueueWithRequestId() {
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequest__c asyncRequest = new AsyncRequest__c(AsyncType__c = TEST_TYPE);

            insert asyncRequest;

            Test.startTest();
            AsyncRequestProcessor.tryToQueue(null, asyncRequest.Id, TEST_TYPE);
            Test.stopTest();
        }
    }

    @IsTest static void testProcessedRequestIsPurged() {
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{
                    new AsyncRequest__c(AsyncType__c = TEST_TYPE)});

            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, null, TEST_TYPE);
            Test.stopTest();

            Assert.areEqual(0, [SELECT COUNT() FROM AsyncRequest__c], 'Processed request should be purged');
        }
    }

    @IsTest static void testProcessedRequestIsDeactivatedWhenPurgeDisabled() {
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AppConfig.testConfig.AsyncRequestsPurged__c = false;

            AsyncRequest__c asyncRequest = new AsyncRequest__c(AsyncType__c = TEST_TYPE);
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{asyncRequest});

            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, null, TEST_TYPE);
            Test.stopTest();

            AsyncRequest__c processed = [SELECT StartDatetime__c, NumberOfAttempts__c FROM AsyncRequest__c WHERE Id = :asyncRequest.Id];
            Assert.isNull(processed.StartDatetime__c, 'Processed request should be deactivated, not deleted');
            Assert.areEqual(1, processed.NumberOfAttempts__c, 'Attempt count should be incremented');
        }
    }

    @IsTest static void testParentWithSingleChildRequest() {
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequest__c parentAsyncRequest = new AsyncRequest__c(AsyncType__c = TEST_TYPE, StartDatetime__c = null);
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{parentAsyncRequest});

            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{
                    new AsyncRequest__c(AsyncType__c = TEST_TYPE, ParentRequest__c = parentAsyncRequest.Id)});

            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, parentAsyncRequest.Id, TEST_TYPE);
            Test.stopTest();

            Assert.areEqual(0, [SELECT COUNT() FROM AsyncRequest__c],
                    'Parent and its only child should both be purged once the child completes');
        }
    }

    @IsTest static void testParentWithMultipleChildRequest() {
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequest__c parentAsyncRequest = new AsyncRequest__c(AsyncType__c = TEST_TYPE, StartDatetime__c = null);
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{parentAsyncRequest});

            List<AsyncRequest__c> childRequests = new List<AsyncRequest__c>();

            for (Integer i = 0; i < 2; i++) {
                childRequests.add(new AsyncRequest__c(
                        AsyncType__c = TEST_TYPE,
                        ParentRequest__c = parentAsyncRequest.Id));
            }

            AsyncRequestTestUtil.insertWithoutTrigger(childRequests);

            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, parentAsyncRequest.Id, TEST_TYPE);
            Test.stopTest();

            Assert.areEqual(1, [SELECT COUNT() FROM AsyncRequest__c WHERE ParentRequest__c = :parentAsyncRequest.Id],
                    'Only the processed child should be purged');
            Assert.areEqual(1, [SELECT COUNT() FROM AsyncRequest__c WHERE Id = :parentAsyncRequest.Id],
                    'Parent should remain while a child is still pending');
        }
    }

    @IsTest static void testExceptionHandling() {
        AsyncRequestProcessor.testExpectException = true;

        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequest__c asyncRequest = new AsyncRequest__c(
                    AsyncType__c = TEST_TYPE,
                    Params__c = 'TestProcessorException');

            insert asyncRequest;

            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, null, TEST_TYPE);
            Test.stopTest();
        }
    }

    @IsTest static void testDependentRequestExceptionIsRecorded() {
        AsyncRequestProcessor.testExpectException = true;

        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequest__c parentAsyncRequest = new AsyncRequest__c(AsyncType__c = TEST_TYPE, StartDatetime__c = null);
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{parentAsyncRequest});

            AsyncRequest__c childAsyncRequest = new AsyncRequest__c(
                    AsyncType__c = TEST_TYPE,
                    ParentRequest__c = parentAsyncRequest.Id,
                    Params__c = 'TestProcessorException',
                    RetryCount__c = 0);
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{childAsyncRequest});

            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, parentAsyncRequest.Id, TEST_TYPE);
            Test.stopTest();

            AsyncRequest__c failed = [SELECT Error__c, ErrorMessage__c FROM AsyncRequest__c WHERE Id = :childAsyncRequest.Id];
            Assert.isTrue(failed.Error__c, 'Failed child should be flagged as errored');
            Assert.areEqual('TestProcessorException', failed.ErrorMessage__c, 'Exception message should be stored');
        }
    }

    @IsTest static void testFailedRequestIsRescheduledWhileRetriesRemain() {
        AsyncRequestProcessor.testExpectException = true;

        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequest__c asyncRequest = new AsyncRequest__c(
                    AsyncType__c = TEST_TYPE,
                    Params__c = 'TestProcessorException',
                    RetryCount__c = 3);
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{asyncRequest});
            Datetime earliestRetry = Datetime.now().addMinutes(4);

            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, null, TEST_TYPE);
            Test.stopTest();

            AsyncRequest__c failed = [SELECT Error__c, NumberOfAttempts__c, StartDatetime__c FROM AsyncRequest__c WHERE Id = :asyncRequest.Id];
            Assert.isFalse(failed.Error__c, 'Request with retries left should not be errored');
            Assert.areEqual(1, failed.NumberOfAttempts__c, 'Attempt should be counted');
            Assert.isTrue(failed.StartDatetime__c > earliestRetry, 'Retry should wait the default delay');
        }
    }

    @IsTest static void testFailedRequestErrorsWhenRetriesAreExceeded() {
        AsyncRequestProcessor.testExpectException = true;

        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequest__c asyncRequest = new AsyncRequest__c(
                    AsyncType__c = TEST_TYPE,
                    Params__c = 'TestProcessorException',
                    NumberOfAttempts__c = 3,
                    RetryCount__c = 3);
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{asyncRequest});

            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, null, TEST_TYPE);
            Test.stopTest();

            AsyncRequest__c failed = [SELECT Error__c, NumberOfAttempts__c FROM AsyncRequest__c WHERE Id = :asyncRequest.Id];
            Assert.isTrue(failed.Error__c, 'Request should be errored once its retries are used up');
            Assert.areEqual(4, failed.NumberOfAttempts__c, 'Final attempt should be counted');
        }
    }

    @IsTest static void testEnqueueJobWithInvalidTypeIsHandled() {
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            Test.startTest();
            AsyncRequestProcessor.enqueueJob(null, null, 'NotAnAsyncRequestProcessor');
            Assert.areEqual(0, Limits.getQueueableJobs(), 'No job should be queued for an unknown type');
            Test.stopTest();
        }
    }

    @IsTest static void testFinalizerLogsUnhandledException() {
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequestProcessor processor = new TestProcessor();

            Test.startTest();
            processor.execute(new FailedFinalizerContext());
            Test.stopTest();

            Assert.isNotNull(processor, 'Finalizer should handle an unhandled exception without rethrowing');
        }
    }

    private class FailedFinalizerContext implements FinalizerContext {
        public Id getAsyncApexJobId() { return null; }
        public String getRequestId() { return null; }
        public ParentJobResult getResult() { return ParentJobResult.UNHANDLED_EXCEPTION; }
        public Exception getException() { return new DmlException('Simulated failure'); }
    }
}
