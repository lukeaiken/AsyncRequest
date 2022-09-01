@IsTest
private class AppConfigTest {
    @IsTest static void testSetting() {
        AppConfig settings = new AppConfig();

        Boolean asyncRequestsAreEnabled = settings.asyncRequestsEnabled;
        settings.updateAsyncRequestsEnabled(asyncRequestsAreEnabled);

        Boolean asyncRequestsArePurged = settings.asyncRequestsPurged;
        settings.updateAsyncRequestsPurged(asyncRequestsArePurged);
    }

    @IsTest static void testTestConfig() {
      AppConfig.testConfig = new AppConfig__c();
      AppConfig settings = new AppConfig();
    }
}