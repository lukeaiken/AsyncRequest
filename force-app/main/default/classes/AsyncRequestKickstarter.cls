public inherited sharing class AsyncRequestKickstarter implements AsyncRequestKickstarterDispatch.IScheduledDispatch {
    private static final Datetime NOW = System.now();
    private static final String JOB_NAME = 'Async Request Kickstarter Dispatch';

    private static AppConfig appSettings = new AppConfig();

    private Set<String> asyncTypesReadyForEnqueue = new Set<String>();

    public void execute(SchedulableContext sc) {
        try {
            for (AsyncRequest__c request : [
                    SELECT AsyncType__c
                    FROM AsyncRequest__c
                    WHERE Error__c = FALSE
                    AND ParentRequest__c = NULL
                    AND StartDatetime__c <= :NOW
            ]) {
                asyncTypesReadyForEnqueue.add(request.AsyncType__c);
            }

            for (String asyncType : asyncTypesReadyForEnqueue)
                AsyncRequestProcessor.enqueueJob(null, null, asyncType);

            if (sc != null) {
                System.enqueueJob(new AbortAndReschedule(50, sc.getTriggerId()));
            } else {
                reschedule();
            }
        } catch (Exception ex) {
            Logger.error(ex.getTypeName() + ' : ' + ex.getMessage());
            Logger.saveLog();
        }
    }

    public static void reschedule() {
        Set<String> completedStates = new Set<String>{ 'COMPLETED', 'ERROR', 'DELETED'};

        for (CronTrigger job : [
                SELECT State
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE :JOB_NAME + '%'
        ]) {
            if (!completedStates.contains(job.State))
                return;
        }


        if (appSettings.asyncRequestKickstarterFrequency > 0) {
            Datetime sysTime = NOW.addMinutes(appSettings.asyncRequestKickstarterFrequency);

            String chronExpression =
                    sysTime.second() + ' ' +
                            sysTime.minute() + ' ' +
                            sysTime.hour() + ' ' +
                            sysTime.day() + ' ' +
                            sysTime.month() + ' ' +
                            '?' + ' ' +  // unspecified Day_of_Month
                            sysTime.year();

            System.schedule(JOB_NAME + ' - ' + String.valueOf(+Crypto.getRandomLong()),
                    chronExpression, new AsyncRequestKickstarterDispatch());
        }
    }

    private class AbortAndReschedule implements Queueable {
        Integer attempts;
        Id jobId;

        public AbortAndReschedule(Integer thisAttempt, Id jid) {
            attempts = thisAttempt - 1;
            jobId = jid;
        }

        public void execute(QueueableContext context) {
            List<CronTrigger> jobs = [
                    SELECT Id, State
                    FROM CronTrigger
                    WHERE Id = :jobId
            ];

            if (!jobs.isEmpty() && jobs[0].State == 'EXECUTING') {
                if (attempts < 0) {
                    Logger.error('Unable to restart the job. JobId: ' + jobs[0].Id);
                    Logger.saveLog();
                    return;
                }
                System.enqueueJob(new AbortAndReschedule(attempts, jobId));
                return;
            }
            if (!jobs.isEmpty()) System.abortJob(jobId);
            reschedule();
        }
    }
}