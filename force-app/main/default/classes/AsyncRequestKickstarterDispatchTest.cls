@IsTest
private class AsyncRequestKickstarterDispatchTest {
    @isTest static void testExecute() {
        AsyncRequestKickstarterDispatch dispatch = new AsyncRequestKickstarterDispatch();

        dispatch.execute(null);
    }
}