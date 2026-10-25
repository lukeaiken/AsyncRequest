@IsTest
public class AsyncRequestTestUtil {
    private static final String ASYNC_USER_LAST_NAME = 'AsyncRequestTestUser';

    public static void createAsyncUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String username = 'asyncreq' + Datetime.now().getTime() + Crypto.getRandomInteger() + '@test.conventus.com';
        User asyncUser = new User(
                Alias = 'asyncreq',
                Email = username,
                EmailEncodingKey = 'UTF-8',
                LastName = ASYNC_USER_LAST_NAME,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = standardProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                Username = username);
        insert asyncUser;

        insert new PermissionSetAssignment(
                AssigneeId = asyncUser.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'AsyncRequest_Framework'].Id);
    }

    public static User getAsyncUser() {
        // Avoids AppConfig creating org defaults, which a non-admin user cannot do
        AppConfig.testConfig = new AppConfig__c(
                AsyncRequestsEnabled__c = true,
                AsyncRequestsPurged__c = true,
                AsyncRequestKickstarterFrequency__c = 5);

        return [SELECT Id FROM User WHERE LastName = :ASYNC_USER_LAST_NAME LIMIT 1];
    }

    // Inserts without the AsyncRequest trigger so no processor job is queued as a side effect
    public static void insertWithoutTrigger(List<AsyncRequest__c> requests) {
        TriggerHandler.bypass(AsyncRequestTriggerHandler.class.getName());
        insert requests;
        TriggerHandler.clearBypass(AsyncRequestTriggerHandler.class.getName());
    }
}
