@IsTest
public class AsyncRequestKickstarterDispatchTest {
    // Inner classes cannot declare statics, so the dispatch target records its run here
    private static Boolean throwingDispatchExecuted = false;

    @isTest static void testExecute() {
        AsyncRequestKickstarterDispatch dispatch = new AsyncRequestKickstarterDispatch();

        dispatch.execute(null);
    }

    @IsTest static void testExecuteHandlesDispatchException() {
        AsyncRequestKickstarterDispatch.dispatchTypeName = ThrowingDispatch.class.getName();

        Test.startTest();
        new AsyncRequestKickstarterDispatch().execute(null);
        Test.stopTest();

        Assert.isTrue(throwingDispatchExecuted, 'Dispatch target should run and its exception should be handled');
    }

    public class ThrowingDispatch implements AsyncRequestKickstarterDispatch.IScheduledDispatch {
        public void execute(SchedulableContext sc) {
            throwingDispatchExecuted = true;
            throw new DmlException('Simulated dispatch failure');
        }
    }
}
