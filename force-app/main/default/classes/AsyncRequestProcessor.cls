public abstract class AsyncRequestProcessor implements Queueable, Database.AllowsCallouts, Finalizer {

    private static final String developerEditionErrMsg = 'DEVELOPER_EDITION_STACK_DEPTH_LIMIT';

    @TestVisible private static Boolean testChildContext = false;
    @TestVisible private static Boolean testExpectException = false;

    protected AsyncRequest__c currentRequest;
    protected AppConfig appSettings = new AppConfig();

    private Boolean skipQueryMoreRequests = false;
    private String currentAsyncType;
    private Id parentRequestId;

    public AsyncRequestProcessor setAsyncType(String asyncType) {
        this.currentAsyncType = asyncType;
        return this;
    }

    public AsyncRequestProcessor setParentRequestId(Id parentRequestId) {
        this.parentRequestId = parentRequestId;
        return this;
    }

    public AsyncRequestProcessor setAsyncRequest(AsyncRequest__c asyncRequest) {
        this.currentRequest = asyncRequest;
        return this;
    }

    public void execute(QueueableContext qc) {
        if (!appSettings.asyncRequestsEnabled || isQueued(qc.getJobId(), currentAsyncType)) return;

        List<AsyncRequest__c> openRequests = getOpenRequests();

        if (openRequests.isEmpty()) return;

        currentRequest = openRequests.get(0);

        Type targetType = Type.forName(currentAsyncType);
        AsyncRequestProcessor finalizer = ((AsyncRequestProcessor) targetType.newInstance());
        finalizer.setAsyncRequest(currentRequest);

        System.attachFinalizer(finalizer);

        try {
            currentRequest.NumberOfAttempts__c++;
            currentRequest.LastExecutedBy__c = UserInfo.getUserId();

            processRequest(currentRequest);

            currentRequest.Error__c = false;
            currentRequest.ErrorMessage__c = null;

            List<AsyncRequest__c> childRequests = [
                    SELECT AsyncType__c
                    FROM AsyncRequest__c
                    WHERE ParentRequest__c = :currentRequest.Id
            ];

            if (currentRequest.isDependent__c || testingChildContext()) {
                List<AsyncRequest__c> completedRequests = setNextAsyncType(currentRequest);
                cleanUp(completedRequests);
            } else {
                if (!childRequests.isEmpty()) {
                    parentRequestId = currentRequest.Id;
                    currentAsyncType = childRequests.get(0).AsyncType__c;
                    deactivate(currentRequest);
                } else {
                    cleanUp(currentRequest);
                }
            }
        } catch (Exception ex) {
            currentRequest.ErrorMessage__c = ex.getMessage();
            currentRequest.Error__c = true;
            Logger.error(ex.getTypeName() + ':: ' + ex.getMessage(), currentRequest);
            Logger.saveLog();

            update currentRequest;

            if (currentRequest.isDependent__c || testingChildContext()) setNextAsyncType(currentRequest);

            if (!testExpectException && Test.isRunningTest()) throw ex;
        }

        if (!skipQueryMoreRequests && getMoreRequests().isEmpty()) return;

        try {
            if (!Test.isRunningTest()) enqueueJob(qc.getJobId(), parentRequestId, currentAsyncType);
        } catch (Exception ex) {
            if (ex.getMessage() == developerEditionErrMsg) {
                throw ex;
            } else {
                tryToQueue(qc.getJobId(), parentRequestId, currentAsyncType);
            }
        }
    }

    public virtual void execute(FinalizerContext ctx) {
        System.ParentJobResult result = ctx.getResult();
        if (result == ParentJobResult.UNHANDLED_EXCEPTION) {
            Exception ex = ctx.getException();
            Logger.error(ex.getMessage(), currentRequest);
            Logger.saveLog();
        }
    }

    abstract void processRequest(AsyncRequest__c request);

    public static void enqueueJob(Id currentJobId, Id parentRequestId, String asyncType) {
        if (isQueued(currentJobId, asyncType)) return;   // Already have one queued that isn't this one.

        try {
            Type targetType = Type.forName(asyncType);
            AsyncRequestProcessor processor = ((AsyncRequestProcessor) targetType.newInstance());
            processor.setAsyncType(asyncType);
            processor.setParentRequestId(parentRequestId);

            if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                System.enqueueJob(processor);
            } else {
                tryToQueue(currentJobId, parentRequestId, asyncType); // Future
            }
        } catch (Exception ex) {
            Logger.error(ex.getMessage());
            Logger.saveLog();

            if (ex.getMessage().toLowerCase().contains('maximum stack depth')) { // Developer Edition org
                throw new AsyncRequestProcessorException(developerEditionErrMsg);
            }
        }
    }

    protected List<AsyncRequest__c> getOpenRequests() {
        if (this.parentRequestId != null) return getOpenRequestsByParentId();

        return [
                SELECT AsyncType__c, Params__c, StartDatetime__c, NumberOfAttempts__c,
                        ParentRequest__c, ParentRequest__r.AsyncType__c, IsDependent__c
                FROM AsyncRequest__c
                WHERE Error__c = FALSE
                AND (ParentRequest__c = NULL OR ParentRequest__r.StartDatetime__c = NULL)
                AND StartDatetime__c <= :Datetime.now()
                AND AsyncType__c = :currentAsyncType
                LIMIT 1
                FOR UPDATE
        ];
    }

    protected List<AsyncRequest__c> getOpenRequestsByParentId() {
        return [
                SELECT AsyncType__c, Params__c, StartDatetime__c, NumberOfAttempts__c,
                        ParentRequest__c, ParentRequest__r.AsyncType__c, IsDependent__c
                FROM AsyncRequest__c
                WHERE Error__c = FALSE
                AND AsyncType__c = :currentAsyncType
                AND StartDatetime__c <= :Datetime.now()
                AND ParentRequest__c = :parentRequestId
                LIMIT 1
                FOR UPDATE
        ];
    }

    @TestVisible
    private static Boolean isQueued(Id currentJobId, String asyncType) {
        if (currentJobId == null) return isQueuedOrProcessing(asyncType);

        List<AsyncApexJob> jobs = [
                SELECT Id
                FROM AsyncApexJob
                WHERE JobType = 'Queueable'
                AND (Status = 'Holding' OR Status = 'Queued' OR Status = 'Processing')
                AND ApexClass.Name = :asyncType
                AND Id <> :currentJobId
                LIMIT 1
        ];

        return !jobs.isEmpty();
    }

    private static Boolean isQueuedOrProcessing(String asyncType) {
        List<AsyncApexJob> jobs = [
                SELECT Id
                FROM AsyncApexJob
                WHERE JobType = 'Queueable'
                AND (Status = 'Holding' OR Status = 'Queued' OR Status = 'Processing')
                AND ApexClass.Name = :asyncType
                LIMIT 1
        ];

        return !jobs.isEmpty();
    }

    protected List<AsyncRequest__c> getMoreRequests() {
        if (currentRequest.isDependent__c || testingChildContext()) return getMoreRequestsByParentId();

        return [
                SELECT Id
                FROM AsyncRequest__c
                WHERE Error__c = FALSE
                AND (ParentRequest__c = NULL OR ParentRequest__r.StartDatetime__c = NULL)
                AND AsyncType__c = :currentAsyncType
                AND StartDatetime__c <= :Datetime.now()
                LIMIT 1
        ];
    }

    protected List<AsyncRequest__c> getMoreRequestsByParentId() {
        return [
                SELECT Id
                FROM AsyncRequest__c
                WHERE Error__c = FALSE
                AND StartDatetime__c <= :Datetime.now()
                AND AsyncType__c = :currentAsyncType
                AND ParentRequest__c = :parentRequestId
                LIMIT 1
        ];
    }

    protected void cleanUp(AsyncRequest__c request) {
        cleanUp(new List<AsyncRequest__c>{request});
    }

    protected void cleanUp(List<AsyncRequest__c> requests) {
        if (appSettings.asyncRequestsPurged) {
            incinerate(requests);
        } else {
            deactivate(requests);
        }
    }

    protected void deactivate(AsyncRequest__c request) {
        deactivate(new List<AsyncRequest__c>{request});
    }

    protected void deactivate(List<AsyncRequest__c> requests) {
        for (AsyncRequest__c request : requests)
            request.StartDatetime__c = null;

        update requests;
    }

    protected void incinerate(List<AsyncRequest__c> requests) {
        delete requests;
        Database.emptyRecycleBin(requests);
    }

    @Future
    public static void tryToQueue(Id currentJobId, Id parentRequestId, String asyncType) {
        try {
            if (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
                if (!Test.isRunningTest()) enqueueJob(currentJobId, parentRequestId, asyncType);
            }
        } catch (Exception ex) {
            Logger.error(ex.getMessage());
            Logger.saveLog();
        }
    }

    private List<AsyncRequest__c> setNextAsyncType(AsyncRequest__c currentRequest) {
        AsyncRequest__c parentRequest = [
                SELECT AsyncType__c, (
                        SELECT AsyncType__c
                        FROM ChildRequests__r
                        WHERE StartDatetime__c <> NULL AND Id <> :currentRequest.Id
                )
                FROM AsyncRequest__c
                WHERE Id = :currentRequest.ParentRequest__c
        ];

        if (parentRequest.ChildRequests__r.size() > 0) {
            parentRequestId = currentRequest.ParentRequest__c;
            currentAsyncType = parentRequest.ChildRequests__r.get(0).AsyncType__c;
            skipQueryMoreRequests = true;

            return new List<AsyncRequest__c>{currentRequest};
        } else {
            if (getMoreRequests().size() > 1) skipQueryMoreRequests = true;
            else currentAsyncType = currentRequest.ParentRequest__r.AsyncType__c;

            return new List<AsyncRequest__c>{currentRequest, parentRequest};
        }
    }

    private Boolean testingChildContext() {
        return Test.isRunningTest() && testChildContext && currentRequest.isDependent__c;
    }

    private class AsyncRequestProcessorException extends Exception {

    }
}