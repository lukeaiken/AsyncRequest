public inherited sharing class DataRetentionEvalProcessor extends AsyncRequestProcessor {

    @TestVisible
    private void processRequest(AsyncRequest__c request) {
        if (appSettings.dataRetentionEvalEnabled || Test.isRunningTest()) {
            Database.executeBatch(new DataRetentionEvalBatch(), 5000);
        } else {
            throw new DataRetentionEvalProcessorException('Data Retention Eval Disabled');
        }
    }

    private class DataRetentionEvalProcessorException extends Exception {

    }
}