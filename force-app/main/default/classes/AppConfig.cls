public without sharing class AppConfig {

    public static Set<String> asyncTypesToEnqueue = new Set<String>();
    public static Map<String, List<Id>> parentIdsByDependentTypes = new Map<String, List<Id>>();

    public Boolean asyncRequestsEnabled {
        get {
            return GetSettings().AsyncRequestsEnabled__c;
        }
    }

    public Boolean asyncRequestsPurged {
        get {
            return GetSettings().AsyncRequestsPurged__c;
        }
    }

    public Boolean dataRetentionEvalEnabled {
        get {
            return GetSettings().DataRetentionEvalEnabled__c;
        }
    }
    
    public Integer asyncRequestKickstarterFrequency {
        get {
            return Integer.valueOf(GetSettings().AsyncRequestKickstarterFrequency__c);
        }
    }

    @TestVisible
    private static AppConfig__c testConfig = null;

    @TestVisible
    private static AppConfig__c GetSettings() {
        if (Test.isRunningTest() && testConfig != null) return testConfig;

        AppConfig__c settings = AppConfig__c.getOrgDefaults();
        if (settings.SetupOwnerId == null) // No custom settings record yet
        {
            settings = new AppConfig__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                AsyncRequestsEnabled__c = true,
                AsyncRequestsPurged__c = true,
                DataRetentionEvalEnabled__c = true,
                AsyncRequestKickstarterFrequency__c = 5
            );

            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{settings}, true);

            if (!Test.isRunningTest()) insert decision.getRecords()[0];
            else testConfig = settings;
        }

        return settings;
    }

    public void updateAsyncRequestsEnabled(Boolean enabled) {
        AppConfig__c settings = GetSettings();
        settings.AsyncRequestsEnabled__c = enabled;

        if (!Test.isRunningTest()) update settings;
    }

    public void updateAsyncRequestsPurged(Boolean purged) {
        AppConfig__c settings = GetSettings();
        settings.AsyncRequestsPurged__c = purged;

        if (!Test.isRunningTest()) update settings;
    }

}