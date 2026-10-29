@IsTest
private class AsyncRequestKickstarterTest {
    private static final String KICKSTARTER_JOB_PREFIX = 'Async Request Kickstarter Dispatch%';
    private static final String CRON_EXPRESSION = '0 0 0 1 1 ? ' + (Date.today().year() + 1);

    @TestSetup static void setup() {
        AsyncRequestTestUtil.createAsyncUser();
    }

    @IsTest static void testExecuteEnqueuesReadyRequestsAndReschedules() {
        abortExistingKickstarterJobs();
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{
                    new AsyncRequest__c(AsyncType__c = TestProcessor.class.getName(), StartDatetime__c = Datetime.now().addMinutes(-1))});

            // No startTest/stopTest: stopTest would run the newly scheduled job and change the CronTrigger count
            new AsyncRequestKickstarter().execute(null);

            Assert.areEqual(1, Limits.getQueueableJobs(), 'Ready request type should be enqueued');
            Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :KICKSTARTER_JOB_PREFIX],
                    'Kickstarter should schedule its next run');
        }
    }

    @IsTest static void testExecuteEnqueuesErroredRequestsWithRetriesRemaining() {
        abortExistingKickstarterJobs();
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{
                    new AsyncRequest__c(AsyncType__c = TestProcessor.class.getName(), StartDatetime__c = Datetime.now().addMinutes(-1),
                            Error__c = true, NumberOfAttempts__c = 3, RetryCount__c = 5)});

            new AsyncRequestKickstarter().execute(null);

            Assert.areEqual(1, Limits.getQueueableJobs(), 'Errored request with retries remaining should be enqueued');
        }
    }

    @IsTest static void testExecuteSkipsErroredRequestsWithoutRetriesRemaining() {
        abortExistingKickstarterJobs();
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            AsyncRequestTestUtil.insertWithoutTrigger(new List<AsyncRequest__c>{
                    new AsyncRequest__c(AsyncType__c = TestProcessor.class.getName(), StartDatetime__c = Datetime.now().addMinutes(-1),
                            Error__c = true, NumberOfAttempts__c = 4, RetryCount__c = 3)});

            new AsyncRequestKickstarter().execute(null);

            Assert.areEqual(0, Limits.getQueueableJobs(), 'Errored request without retries remaining should not be enqueued');
        }
    }

    @IsTest static void testRescheduleSkippedWhenKickstarterAlreadyScheduled() {
        abortExistingKickstarterJobs();
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            System.schedule('Async Request Kickstarter Dispatch - existing', CRON_EXPRESSION, new AsyncRequestKickstarterDispatch());

            Test.startTest();
            AsyncRequestKickstarter.reschedule();
            Test.stopTest();

            Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :KICKSTARTER_JOB_PREFIX],
                    'No second kickstarter job should be scheduled while one is pending');
        }
    }

    @IsTest static void testScheduledExecuteAbortsAndReschedules() {
        abortExistingKickstarterJobs();
        System.runAs(AsyncRequestTestUtil.getAsyncUser()) {
            Id triggerId = System.schedule('Kickstarter test trigger', CRON_EXPRESSION, new AsyncRequestKickstarterDispatch());

            Test.startTest();
            new AsyncRequestKickstarter().execute(new TestSchedulableContext(triggerId));
            Test.stopTest();

            Assert.areEqual(0, [SELECT COUNT() FROM CronTrigger WHERE Id = :triggerId],
                    'Triggering job should be aborted');
            Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :KICKSTARTER_JOB_PREFIX],
                    'Kickstarter should be rescheduled after the abort');
        }
    }

    // Tests see the org's real CronTriggers; aborting the scheduled kickstarter here is rolled back with the test
    private static void abortExistingKickstarterJobs() {
        for (CronTrigger job : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE :KICKSTARTER_JOB_PREFIX])
            System.abortJob(job.Id);
    }

    private class TestSchedulableContext implements SchedulableContext {
        private Id triggerId;

        TestSchedulableContext(Id triggerId) {
            this.triggerId = triggerId;
        }

        public Id getTriggerId() {
            return triggerId;
        }
    }
}
