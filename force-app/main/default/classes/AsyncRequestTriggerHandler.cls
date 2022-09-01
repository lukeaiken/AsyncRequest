public inherited sharing class AsyncRequestTriggerHandler extends TriggerHandler {
    private static AppConfig appSettings = new AppConfig();
    public static Map<String, List<Id>> parentIdsByDependentTypes = new Map<String, List<Id>>();
    public static Set<String> asyncTypesToEnqueue = new Set<String>();

    public override void afterInsert() {
        enqueueRequests(Trigger.new);
    }

    public override void afterUpdate() {
        retryAsyncRequests((Map<Id, AsyncRequest__c>)Trigger.oldMap, Trigger.new);
    }

    private static void enqueueRequests(List<AsyncRequest__c> asyncRequests) {
        for (AsyncRequest__c request : asyncRequests) {
            if (request.ParentRequest__c == null) {
                asyncTypesToEnqueue.add(request.AsyncType__c);
            }
        }

        for (String asyncType : asyncTypesToEnqueue) {
            AsyncRequestProcessor.enqueueJob(null, null, asyncType);
        }
    }

    private static void retryAsyncRequests(Map<Id, AsyncRequest__c> oldAsyncRequestsByIds, List<AsyncRequest__c> newAsyncRequests) {
        for (AsyncRequest__c newAsyncRequest : newAsyncRequests) {
            AsyncRequest__c oldAsyncRequest = oldAsyncRequestsByIds.get(newAsyncRequest.Id);

            if (oldAsyncRequest.Error__c && !newAsyncRequest.Error__c) {
                if (newAsyncRequest.ParentRequest__c != null) {
                    if (!parentIdsByDependentTypes.containsKey(newAsyncRequest.AsyncType__c))
                        parentIdsByDependentTypes.put(newAsyncRequest.AsyncType__c, new List<Id>());
                    parentIdsByDependentTypes.get(newAsyncRequest.AsyncType__c).add(newAsyncRequest.ParentRequest__c);
                } else {
                    asyncTypesToEnqueue.add(newAsyncRequest.AsyncType__c);
                }
            }
        }

        for (String asyncType : asyncTypesToEnqueue)
            AsyncRequestProcessor.enqueueJob(null, null, asyncType);

        for (String asyncType : parentIdsByDependentTypes.keySet()) {
            for (Id parentRequestId : parentIdsByDependentTypes.get(asyncType)) {
                AsyncRequestProcessor.enqueueJob(null, parentRequestId, asyncType);
            }
        }
    }
}