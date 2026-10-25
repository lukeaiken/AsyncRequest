@IsTest
private class AsyncRequestKickstarterTest {
    private static final String KICKSTARTER_JOB_PREFIX = 'Async Request Kickstarter Dispatch%';
    private static final String CRON_EXPRESSION = '0 0 0 1 1 ? ' + (Date.today().year() + 1);

    @TestSetup static void setup() {
        AsyncRequestTestUtil.createAsyncUser();
    }

    @IsTest static void testExecuteEnqueuesReadyRequestsAndReschedules() {
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

    @IsTest static void testRescheduleSkippedWhenKickstarterAlreadyScheduled() {
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
