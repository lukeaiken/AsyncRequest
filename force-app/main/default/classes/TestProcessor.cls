public class TestProcessor extends AsyncRequestProcessor {
    public static Id currentAsyncRequestId;

    private void processRequest(AsyncRequest__c asyncRequest) {
        if (asyncRequest.Params__c == 'TestProcessorException')
            throw new TestProcessorException('TestProcessorException');
    }

    private class TestProcessorException extends Exception {}
}