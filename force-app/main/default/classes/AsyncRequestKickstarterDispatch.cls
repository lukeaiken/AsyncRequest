public inherited sharing class AsyncRequestKickstarterDispatch implements Schedulable {
    public Interface IScheduledDispatch {
        void execute(SchedulableContext sc);
    }

    @TestVisible
    private static String dispatchTypeName = 'AsyncRequestKickstarter';

    public void execute(SchedulableContext sc) {
        Type targetType = Type.forName(dispatchTypeName);
        if (targetType != null) {
            IScheduledDispatch obj = (IScheduledDispatch)targetType.newInstance();
            try {
                obj.execute(sc);
            } catch(Exception ex) {
                Logger.error(ex.getTypeName() + ':: ' + ex.getMessage());
                Logger.saveLog();
            }
        }
    }
}