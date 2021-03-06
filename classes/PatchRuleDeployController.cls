/*
 * Controller of page PatchRuleDeploy
 */
public class PatchRuleDeployController 
{
    private List<Id> updatedPatchIds;
    private String tempBody;
    
    public PatchRuleDeployController()
    {
        isValidate = (ApexPages.currentPage().getParameters().get('validate') == '1');
        isConfirmed = isValidate ? true : false;
        bodyGenerated = false;
        realign = false;
        if(isConfirmed)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Generating deployment package...'));
        }
    }
    public Boolean isValidate { get; set; }
    public Boolean isConfirmed { get; set; }
    public Boolean bodyGenerated { get; set; }
    public Boolean realign { get; set; }
    public Boolean IsAdmin
    {
        get
        {
            User currentUser = [select Id, Profile.PermissionsAuthorApex from User where Id=:UserInfo.getUserId() limit 1];
            return currentUser.Profile.PermissionsAuthorApex;
        }
    }
    
    public String ZipData { get; set; } 

    public MetadataService.AsyncResult AsyncResult {get; private set;}

    public String getPackageXml()
    {
        return '<?xml version="1.0" encoding="UTF-8"?>' + 
            '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' + 
                '<types>' + 
                    '<members>PatchRuleEngine</members>' +
                    '<name>ApexClass</name>' + 
                '</types>' + 
                '<version>30.0</version>' + 
            '</Package>';       
    }

    public String getClassMetadata()
    {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
            '<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">' +
                '<apiVersion>30.0</apiVersion>' + 
                '<status>Active</status>' +
            '</ApexClass>';     
    }
    
    public String getClassBody()   
    {
        String result = null;
        try
        {
            PatchRuleEngineBuilder builder = new PatchRuleEngineBuilder();
            result = builder.build();
            tempBody = result;
            bodyGenerated = true;
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            bodyGenerated = false;
        }
        return result;
    }
    
    public PageReference startDeploy()
    {
        isConfirmed = true;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Generating deployment package...'));
        updatedPatchIds = new List<Id>();
        for(Patch__c patch : [select Id from Patch__c where Timestamp__c > :DateTime.newInstance(PatchRuleHelper.LastDeploymentDate)])
        {
            updatedPatchIds.add(patch.Id);
        }
        return null;
    }
    
    public PageReference deployZip()
    {
        if(bodyGenerated)
        {
            if(IsAdmin)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, (isValidate ? 'Validating...' : 'Deploying...')));
                MetadataService.MetadataPort service = createService();
                MetadataService.DeployOptions deployOptions = new MetadataService.DeployOptions();
                deployOptions.allowMissingFiles = false;
                deployOptions.autoUpdatePackage = false;
                deployOptions.checkOnly = isValidate;
                deployOptions.ignoreWarnings = false;
                deployOptions.performRetrieve = false;
                deployOptions.purgeOnDelete = false;
                deployOptions.rollbackOnError = true;
                deployOptions.runAllTests = false;
                deployOptions.runTests = new List<String> { 'PatchRuleEngineTest' }; //null;
                deployOptions.singlePackage = true;
                deployOptions.testLevel = 'RunSpecifiedTests';
                AsyncResult = service.deploy(ZipData, DeployOptions);
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, (isValidate ? 'Validation succeeded' : 'Validation succeeded, however you don\'t have permission to do deployment. Please contact system administrator.')));
            }
        }
        return null;
    }   

    public PageReference checkAsyncRequest()
    {   
        // Check the status of the retrieve request
        MetadataService.MetadataPort service = createService();
        MetadataService.DeployResult deployResult = service.checkDeployStatus(AsyncResult.Id, true);
        if(deployResult != null)
        {
            if(deployResult.done)
            {
                if(deployResult.success == true)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, (isValidate ? 'Validation succeeded' : 'Deployment complete')));
                    if(Realign)
                    {
                        return new PageReference('/apex/PatchRealign?start=1');
                    }
                }
                else if(deployResult.status == 'Failed')
                {
                    String error = 'Failled to validate/deploy the patches';
                    if(String.isNotBlank(getDeployResultMessage(deployResult)))
                    {
                        error += ', error message is: ' + getDeployResultMessage(deployResult);
                    }
                    //sendNotification('Silver Peak failed to deploy patches', tempBody);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, error));
                    AsyncResult = null;
                }
                else if(deployResult.status == 'Canceled')
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Validation/Deployment is canceled by administrator'));
                    AsyncResult = null;
                }
            }
            else
            {
                if(deployResult.status == 'Canceling')
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Validation/Deployment is cancelling by administrator.'));
                }
                else if(deployResult.status == 'InProgress')
                {
                    Decimal numberTestsCompleted = (deployResult.numberTestsCompleted == null) ? 0 : deployResult.numberTestsCompleted;
                    Decimal numberTestsTotal = (deployResult.numberTestsTotal == null) ? 0 : deployResult.numberTestsTotal;
                    Integer percentageComplete = numberTestsTotal == 0 ? 0 : ((numberTestsCompleted / numberTestsTotal) * 100).intValue();
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, (isValidate ? 'Validation in progress: ' + percentageComplete + '%' : 'Deployment in progress: ' + percentageComplete + '%')));
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, (isValidate ? 'Validating...' : 'Deploying...')));
                }
            } 
        } 
        return null;
    }
    
    private String getDeployResultMessage(MetadataService.DeployResult deployResult)
    {
        String message = '';
        if(deployResult.details != null && deployResult.details.componentFailures != null)
        {
            for(MetadataService.DeployMessage dm : deployResult.details.componentFailures)
            {
                if(String.isNotBlank(dm.problem))
                {
                    message += dm.problem + '; ';
                }
            }
        }
        if(deployResult.details != null && deployResult.details.runTestResult != null)
        {
            if(deployResult.details.runTestResult.failures != null)
            {
                message += 'Failed to execute existing test methods. ';
                for(MetadataService.RunTestFailure failure : deployResult.details.runTestResult.failures)
                {
                    message += failure.message + '[' + failure.name + '.' + failure.methodName + ']; ';
                }
            }
            if(deployResult.details.runTestResult.codeCoverage != null)
            {
            }
        }
        return message;
    }

    /*private void sendNotification(String subject, String body)
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String> { 'zhong@snapbi.com' });
        email.setSubject(subject);
        email.setPlainTextBody(body);
        email.setSaveAsActivity(false);
        Messaging.sendEmail(new List<Messaging.Email> { email });
    }*/
    
    private static MetadataService.MetadataPort createService()
    { 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;     
    } 
}