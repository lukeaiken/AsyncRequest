public without sharing class DataRetentionPolicyMdt {
    @TestVisible
    private static DataRetentionPolicy__mdt testConfig;
    @TestVisible
    private static String testObjApiName;

    public String objectApiName;

    public DataRetentionPolicyMdt(String objectApiName) {
        this.objectApiName = objectApiName;
    }

    public DataRetentionPolicy__mdt getConfig() {
        if (testConfig != null && Test.isRunningTest()) return testConfig;

        List<DataRetentionPolicy__mdt> settings = [
                SELECT Active__c, DaysToRetain__c, Object__r.QualifiedApiName, Purge__c, WhereClause__c
                FROM DataRetentionPolicy__mdt
                WHERE Object__r.QualifiedApiName = :objectApiName
                AND Active__c = TRUE
                LIMIT 1
        ];
        DataRetentionPolicy__mdt setting = (settings.size() == 1) ? settings.get(0) : null;

        if (setting == null || Test.isRunningTest()) {
            setting = new DataRetentionPolicy__mdt(
                    DeveloperName = 'Default',
                    Label = 'Default',
                    Active__c = true
            );
        }

        return setting;
    }

    public static List<DataRetentionPolicyMdt> getAllPolicies() {
        List<DataRetentionPolicyMdt> policies = new List<DataRetentionPolicyMdt>();

        for (DataRetentionPolicy__mdt policy : [
                SELECT Active__c, DaysToRetain__c, Object__r.QualifiedApiName, Purge__c, WhereClause__c
                FROM DataRetentionPolicy__mdt
                WHERE Active__c = TRUE
        ])
            policies.add(new DataRetentionPolicyMdt(policy.Object__r.QualifiedApiName));

        return policies;
    }

    public Boolean active {
        get {
            return getConfig().Active__c;
        }
    }

    public Integer daysToRetain {
        get {
            return Integer.valueOf(getConfig().DaysToRetain__c);
        }
    }

    public Boolean purge {
        get {
            return getConfig().Purge__c;
        }
    }

    public String whereClause {
        get {
            return getConfig().WhereClause__c;
        }
    }

    public String objectName {
        get {
            if (testObjApiName != null && Test.isRunningTest())
                return testObjApiName;
            return getConfig().Object__r.QualifiedApiName;
        }
    }
}