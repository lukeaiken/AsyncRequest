public inherited sharing class DataRetentionEvalBatch implements Database.Batchable<SObject> {

    public Iterable<SObject> start(Database.BatchableContext bc) {
        List<SObject> sObjects = new List<SObject>();

        try {
            for (DataRetentionPolicyMdt policy : DataRetentionPolicyMdt.getAllPolicies()) {
                if (getRemainingQueryRows() < 1) return sObjects;

                sObjects.addAll(getSObjectsForDeletion(policy));
            }
        } catch (Exception ex) {
            Logger.error(ex.getTypeName() + ':: ' + ex.getMessage());
            Logger.saveLog();
        }

        return sObjects;
    }

    public void execute(Database.BatchableContext bc, List<SObject> sObjects) {
        try {
            String sObjectType = String.valueOf(sObjects[0].getSObjectType());
            DataRetentionPolicyMdt policy = new DataRetentionPolicyMdt(sObjectType);

            delete sObjects;

            System.debug('Deleted ' + sObjects.size() + ' SObject records.');

            if (policy.purge) Database.emptyRecycleBin(sObjects);
        } catch (Exception ex) {
            Logger.error(ex.getTypeName() + ':: ' + ex.getMessage());
            Logger.saveLog();
        }
    }

    public void finish(Database.BatchableContext bc) {
        AsyncRequest__c nextEvalRequest = new AsyncRequest__c(
                AsyncType__c = DataRetentionEvalProcessor.class.getName()
        );

        try {
            for (DataRetentionPolicyMdt policy : DataRetentionPolicyMdt.getAllPolicies()) {
                if (!getSObjectsForDeletion(policy).isEmpty()) {
                    insert nextEvalRequest;
                    return;
                }
            }

            if (noScheduledDataRetentionEvalRequests()) {
                // Tomorrow Midnight
                Date tomorrow = Date.today().addDays(1);
                nextEvalRequest.StartDatetime__c = Datetime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day(), 0, 0, 0);

                insert nextEvalRequest;
            }
        } catch (Exception ex) {
            Logger.error(ex.getTypeName() + ':: ' + ex.getMessage());
            Logger.saveLog();
        }
    }

    private Integer getRemainingQueryRows() {
        return Limits.getLimitQueryRows() - Limits.getQueryRows();
    }

    private List<SObject> getSObjectsForDeletion(DataRetentionPolicyMdt policy) {
        Datetime dt = System.now().addDays(-Integer.valueOf(policy.daysToRetain));

        String query = 'SELECT Id FROM ' + policy.objectName;
        query += ' WHERE CreatedDate <= :dt ';

        if (String.isNotBlank(policy.whereClause))
            query += ' AND ' + policy.whereClause;

        query += ' LIMIT ' + String.valueOf(getRemainingQueryRows());

        System.debug(query);

        return Database.query(query);
    }

    private Boolean noScheduledDataRetentionEvalRequests() {
        return [
                SELECT Id
                FROM AsyncRequest__c
                WHERE AsyncType__c = :DataRetentionEvalProcessor.class.getName()
                AND StartDatetime__c >= :System.now()
                AND Error__c = FALSE
                AND ParentRequest__c = NULL
        ].isEmpty();
    }
}