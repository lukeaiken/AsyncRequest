/**
* Common utility class for test case sample data
*/ 
@isTest
public class TestDataFactory {
    
    public static RetailStore getRetailStore(Id accountId){
        RetailStore retailStore = new RetailStore(Name='Test Store', AccountId = accountId,SAP_Customer_Number__c='2807',State ='British Columbia',Tax_Category__c='2');
        return retailStore;
    }
    
    public static RetailLocationGroup getRetailLocationGroup(){
        RetailLocationGroup retailLocationGroup = new RetailLocationGroup(Name ='Test Retail Location Group',
                                                                          Description ='Test Description',
                                                                          Key__c ='010',
                                                                          Key_Account_Nielsen__c ='IGA QUEBEC',
                                                                          Regional_Nielsen__c ='QUEBEC GB +DR +MM');
        return retailLocationGroup;
    }
    
    public static RetailStoreKpi getRetailStoreKpi(Id assessmentIndDefinitionId,Id retailStoreGroupId){
        Date startDate = Date.today().addDays(-1);
        Date endDate = Date.today().addDays(+15);
        RetailStoreKpi retailStoreKpi = new RetailStoreKpi(AssessmentIndDefinitionId = assessmentIndDefinitionId,
                                                           StartDate =startDate,
                                                           EndDate =endDate,
                                                           RetailStoreGroupId = retailStoreGroupId);
        return retailStoreKpi;
    }
    
    public static Account getAccount(){
        Account accountRecord = new Account(Name='Test Account');
        return accountRecord;
    }
    
    public static User getUser(Id profileId){
        string namePrefix ='tst';
        String orgId=UserInfo.getOrganizationId(); 
        User userRecord = new User(alias = namePrefix+'1', email=namePrefix+ '@test' + orgId + '.org', 
                                   emailencodingkey='UTF-8', firstName='First User1', lastname=namePrefix+'Last 1', languagelocalekey='en_US',
                                   localesidkey='en_US', profileid = profileId,
                                   timezonesidkey='Europe/Berlin', username=namePrefix+ '@test' + orgId + '.org' );
        return userRecord;
    }
    
    public static ActionPlanTemplate getActionPlanTemplate(){
        ActionPlanTemplate actionPlanTemplateRecord = new ActionPlanTemplate(Name = 'Standard English Template',ActionPlanType='Retail',TargetEntityType='Visit');
        return actionPlanTemplateRecord;
    }
    
    public static ActionPlanTemplateVersion getActionPlanTemplateVersion(Id actionPlanTemplateId){
        ActionPlanTemplateVersion actionPlanTemplateRecord = new ActionPlanTemplateVersion(Version=1,
                                                                                           Name = 'Standard English Template',
                                                                                           ActionPlanTemplateId=actionPlanTemplateId,Status ='Final');
        return actionPlanTemplateRecord;
    }
    
    public static Visit getVisit(Id userId, Id recordTypeId, Id retailStoreId){
        Visit visitRecord = new Visit(RecordTypeId =recordTypeId,
                                      VisitorId = userId,
                                      PlannedVisitStartTime =  Datetime.now(),
                                      PlannedVisitEndTime = DateTime.now().addHours(1),
                                      Reportable_Start_Time__c = DateTime.now(),  
                                      Reportable_End_Time__c = DateTime.now().addHours(1),
                                      PlaceId = retailStoreId,
                                      Retail_Store__c = retailStoreId);
        return visitRecord;
    }
    
    public static AssessmentIndicatorDefinition getAssessmentIndicatorDefinition(String name, String dataType){
        AssessmentIndicatorDefinition assessmentIndicatorDefinitionRecord = new AssessmentIndicatorDefinition(Name =name,
                                                                                                              DataType = dataType
                                                                                                             );
        return assessmentIndicatorDefinitionRecord;
    }
    
    public static StoreProduct getStoreProduct(Id productId, Id accountId){
        StoreProduct storeProduct = new StoreProduct(ProductId = productId,
                                                     AccountId = accountId,
                                                     StartDate = system.today());
        return storeProduct;
    }
    
    public static AssessmentTask getAssessmentTask(Id visitRecordId){
        AssessmentTask assessmentTask = new AssessmentTask(Name	 ='Shelf Sets',TaskType='InventoryCheck',
                                                           ParentId = visitRecordId);
        return assessmentTask;
    }
    
    public static Brand__c getBrand(){
        Brand__c brand = new Brand__c(Name = 'BRETON');
        return brand;
    }
    
    public static Brand__c getSubBrand(Id parentBrandId){
        Brand__c brand = new Brand__c(Name = 'BRETON SPROUTED GRAINS',Parent_Brand__c =parentBrandId);
        return brand;
    }
    
    public static Product2 getProduct(Id brandId){
        Product2 product = new Product2(Name = 'BRETON SPROUTED GRAINS',Sub_Brand__c = brandId,IsTaxable__c = true,IsActive =True);
        return product;
    }
    
    public static ProductCatalog getProductCatalog(){
        ProductCatalog catalog = new ProductCatalog(Name = 'All Products');
        return catalog;
    }
    
    public static ProductCategory getProductCategory(Id catalogId){
        ProductCategory category = new ProductCategory(Name ='Candy (C)',
                                                       IsNavigational = true,
                                                       CatalogId = catalogId,
                                                       CategoryAPIName__c = 'C');
        return category;
    }
    
    public static RetailVisitKpi getRetailVisitKpi(Id assessmentIndDefinitionId,Id assessmentTaskId,Id productId, Id retailStoreKpiId, Id productCategoryId, String value){
        RetailVisitKpi retailVisitKpi = new RetailVisitKpi(AssessmentIndDefinitionId = assessmentIndDefinitionId,
                                                           AssessmentTaskId =assessmentTaskId,
                                                           ProductId = productId,
                                                           ActualStringValue = value,
                                                           RetailStoreKpiId =retailStoreKpiId,
                                                           ProductCategoryId = productCategoryId
                                                          );
        return retailVisitKpi;
    }
    
    public static RetailVisitKpi getRetailVisitKpi(Id assessmentIndDefinitionId,Id assessmentTaskId,Id productId, Id retailStoreKpiId, Id productCategoryId, Integer value){
        RetailVisitKpi retailVisitKpi = new RetailVisitKpi(AssessmentIndDefinitionId = assessmentIndDefinitionId,
                                                           AssessmentTaskId =assessmentTaskId,
                                                           ProductId = productId,
                                                           ActualIntegerValue = value,
                                                           RetailStoreKpiId =retailStoreKpiId,
                                                           ProductCategoryId = productCategoryId
                                                          );
        return retailVisitKpi;
    }
    
    public static RetailVisitKpi getRetailVisitKpi(Id assessmentIndDefinitionId,Id assessmentTaskId,Id productId, Id retailStoreKpiId, Id productCategoryId, Boolean value){
        RetailVisitKpi retailVisitKpi = new RetailVisitKpi(AssessmentIndDefinitionId = assessmentIndDefinitionId,
                                                           AssessmentTaskId =assessmentTaskId,
                                                           ProductId = productId,
                                                           ActualBooleanValue = String.valueOf(value),
                                                           RetailStoreKpiId =retailStoreKpiId,
                                                           ProductCategoryId = productCategoryId
                                                          );
        return retailVisitKpi;
    }
    
    public static RetailVisitKpi getRetailVisitKpi(Id assessmentIndDefinitionId,Id assessmentTaskId,Id productId, Id retailStoreKpiId, Id productCategoryId, DateTime value){
        RetailVisitKpi retailVisitKpi = new RetailVisitKpi(AssessmentIndDefinitionId = assessmentIndDefinitionId,
                                                           AssessmentTaskId =assessmentTaskId,
                                                           ProductId = productId,
                                                           ActualDateTimeValue = value,
                                                           RetailStoreKpiId =retailStoreKpiId,
                                                           ProductCategoryId = productCategoryId
                                                          );
        return retailVisitKpi;
    }
    
    public static RetailVisitKpi getRetailVisitKpi(Id assessmentIndDefinitionId,Id assessmentTaskId,Id productId, Id retailStoreKpiId, Id productCategoryId, Decimal value){
        RetailVisitKpi retailVisitKpi = new RetailVisitKpi(AssessmentIndDefinitionId = assessmentIndDefinitionId,
                                                           AssessmentTaskId =assessmentTaskId,
                                                           ProductId = productId,
                                                           ActualDecimalValue = value,
                                                           RetailStoreKpiId =retailStoreKpiId,
                                                           ProductCategoryId = productCategoryId
                                                          );
        return retailVisitKpi;
    }
}