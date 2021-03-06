public class AssetTriggerHandler implements ITriggerHandler {
    public static final Datetime THIRTY_SECONDS_AGO = System.now().addSeconds(-30);
    Id silverpeakSystemsId='00130000007mEjX';// production Id
    Set<Id> lstHWCPAccount {get;set;} //Provision Decommission Account
    Set<Id> lstSWCPAccount {get;set;} //Provision Decommission Account
   
    public AssetTriggerHandler() {
        /*if(!SilverPeakUtils.IsProduction())
        {
            List<Account> spAccount=[select Id from Account where Name='Silver Peak Systems'];
            System.debug('SilverPeakId'+ spAccount );
            if(spAccount!=null)
            {
                silverpeakSystemsId=spAccount[0].Id;
            }
        }*/
        System.debug('silverpeakSystemsId'+silverpeakSystemsId);
        lstHWCPAccount= new Set<Id>();
        lstSWCPAccount= new Set<Id>();
       
    }
    public Boolean IsDisabled() {
        return false;
    }
    public void BeforeInsert(List<SObject> newItems) {
        System.debug('Before Insert');
        Map<Id,Account> cloudPortalAccs= new Map<Id,Account>();
        List<Asset> lstAsset= new List<Asset>();
        List<Asset> virtualAssets = new List<Asset>();
        System.debug('Asset trigger : before insert ---------------> ' + newItems);
        
        
        if(newItems!=null && newItems.size()>0)
        {
            List<Asset> lstNewAssets=(List<Asset>)newItems;
            for(Asset newAsset:lstNewAssets)
            {
               
                if(newAsset.End_of_Maintenance__c== null && newAsset.Product_Quote_Type__c=='NX/VX' && newAsset.Product_Family__c=='Product')
                {
                    newAsset.End_of_Maintenance__c=newAsset.Ship_Date__c!=null?newAsset.Ship_Date__c.addYears(5):null;
                    //newAsset.Get_Serial__c = true;
                    lstAsset.add(newAsset);
                }
                if(newAsset.AccountId!=null && newAsset.Status!='Customer Evaluation')
                {
                    newAsset.Is_Customer_Asset__c=true;
                }
                
                
                
                //provision asset
                System.debug('silverpeakSystemsId'+silverpeakSystemsId);
                if(newAsset.AccountId!=silverpeakSystemsId && (newAsset.Product_Quote_Type__c=='EDGECONNECT'|| newAsset.Product_Quote_Type__c=='EC-SP-Term'|| newAsset.Product_Quote_Type__c=='EC-SP-Perpetual'|| newAsset.Product_Quote_Type__c=='EC-SP-Metered' || newAsset.Product_Quote_Type__c=='Service Provider') && newAsset.Product_Family__c=='Product')
                {
                    if(newAsset.status !='Owned Eval/NFR' && newAsset.status !='Silver Peak Inventory' && newAsset.status !='Write-Off'&& newAsset.status !='Obsolete RMA Unit–Supp Transferred–WO')
                    { 
                        newAsset.Cloud_Portal_Sync_Status__c='Pending';
                        newAsset.Sync_With_Cloud_Portal__c=true;
                    }
                }
            }
            //UpdateEOMDate(lstAsset);
            MakeFinalUpdateToAccount();
            //populateAssetFields(newItems);
            System.debug('Asset trigger : before insert : lstAsset ---------------> ' + lstAsset);
            //groupAssetsByOrderProduct(lstAsset);
            updateAssetStatus((List<Asset>)newItems);
            //generateVirtualSerialNumber(virtualAssets);
        }
        
        
    }
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug('BeforeUpdate');
        List<Asset> lstAsset= new List<Asset>();
        Map<Id,Account> cloudPortalAccs= new Map<Id,Account>();
        if(newItems!=null && newItems.size()>0) {
            for(Id assetId:newItems.keyset())
            {
                Asset newAsset=(Asset)newItems.get(assetId);
                Asset oldAsset=(Asset)oldItems.get(assetId);
                
                if(oldAsset.Ship_Date__c!=newAsset.Ship_Date__c && newAsset.Product_Quote_Type__c=='NX/VX' && newAsset.Product_Family__c=='Product')
                {
                    newAsset.End_of_Maintenance__c=newAsset.Ship_Date__c!=null?newAsset.Ship_Date__c.addYears(5):null;
                    //lstAsset.add(newAsset);
                }
                //decommission asset
                if(newAsset.AccountId == silverpeakSystemsId && oldAsset.AccountId != newAsset.AccountId)
                {
                    if(oldAsset.AccountId!=null)
                    {
                        if(!lstHWCPAccount.contains(oldAsset.AccountId))
                        {
                            lstHWCPAccount.add(oldAsset.AccountId);
                        }
                    }
                } 
                //Trigger Active Asset Count and calculate EC and WAN Op Customer Dates
                if(newAsset.Status!='Customer Evaluation' )
                {
                    if(oldAsset.Contract_Number__c != newAsset.Contract_Number__c || oldAsset.Status != newAsset.Status)
                    {
                        newAsset.Is_Customer_Asset__c=true;
                    }
                    if(oldAsset.AccountId!=newAsset.AccountId )
                    {
                        if( newAsset.AccountId != null)
                        {
                            newAsset.Is_Customer_Asset__c=true;
                        }
                    }
                } 
                //provision an existing asset to another account
                if(oldAsset.AccountId != newAsset.AccountId && oldAsset.AccountId == silverpeakSystemsId && oldAsset.Status =='Silver Peak Inventory')
                {
                    if(newAsset.AccountId!=null && (newAsset.Product_Quote_Type__c=='EDGECONNECT'|| newAsset.Product_Quote_Type__c=='EC-SP-Term'|| newAsset.Product_Quote_Type__c=='EC-SP-Perpetual'|| newAsset.Product_Quote_Type__c=='EC-SP-Metered' || newAsset.Product_Quote_Type__c=='Service Provider') && newAsset.Product_Family__c=='Product')
                    {
                        if(newAsset.status !='Owned Eval/NFR' && newAsset.status !='Silver Peak Inventory' && newAsset.status !='Write-Off'&& newAsset.status !='Obsolete RMA Unit–Supp Transferred–WO')
                        { 
                            newAsset.Cloud_Portal_Sync_Status__c='Pending';
                            newAsset.Sync_With_Cloud_Portal__c=true;
                        }
                    }
                }
            }
            //UpdateEOMDate(lstAsset);
            MakeFinalUpdateToAccount();
        }
    }
    public void BeforeDelete(Map<Id,SObject> oldItems) {
        
        if(oldItems.size()>0)
        {
            for(Id assetId:oldItems.keySet())
            {
                
            }
        }
    }
    public void AfterInsert(Map<Id, SObject> newItems) {
        System.debug('After Insert' + newItems);
        List<Asset> lstLicenseAssets= new List<Asset>();
        Map<Id,Asset> hardwareECAssetIds= new  Map<Id,Asset>();
        Map<Id,Asset> softwareECBaseAssetIds= new  Map<Id,Asset>();
        Set<Id> setAccIds=new Set<Id>();
        Set<Id> setECAcctIds= new Set<Id>();
        Set<Id> setWanOpAcctIds= new Set<Id>();
        List<Asset> virtualAssets = new List<Asset>();
        List<Asset> lstAsset = new List<Asset>();
        if(newItems!=null && newItems.size()>0)
        {
            for (Id assetId : newItems.keyset())
            {
                Asset newAsset= (Asset)newItems.get(assetId);
                if(newAsset.Product_Family__c=='Virtual Image') {
                    virtualAssets.add(newAsset);
                }
                if(newAsset.Product_Quote_Type__c=='NX/VX' && newAsset.Product_Family__c=='Product' && newAsset.SerialNumber == null) {
                    lstAsset.add(newAsset);
                }
               
                if(newAsset.Product_Quote_Type__c=='EDGECONNECT' && newAsset.Product_Family__c=='Product' && (newAsset.Status=='Customer Evaluation' || newAsset.Status=='Customer Owned'))
                {
                    hardwareECAssetIds.put(newAsset.Id,newAsset);
                    setAccIds.add(newAsset.AccountId);
                }
                
                
                if(newAsset.Product_Quote_Type__c=='EDGECONNECT' && newAsset.Model__c.startsWith('EC-BASE' ) && newAsset.Product_Family__c=='Virtual Image' && (newAsset.Status=='Customer Evaluation' || newAsset.Status=='Customer Subscription Active'))
                {
                    softwareECBaseAssetIds.put(newAsset.Id,newAsset);
                    setAccIds.add(newAsset.AccountId);
                }
            }
            AddActiveECBaseLicense(hardwareECAssetIds,softwareECBaseAssetIds,setAccIds);
            MakeFinalUpdateToAccount();
             
        }
        //populateAssetFields(newItems.values());
        DeleteGeneratedAsset(newItems.values());
        populatePOCIdInAsset(newItems.values());

        System.debug('updateShipmentDateOfAsset --------------> ' + newItems.values());
        updateShipmentDateOfAsset(newItems.values());
        runNonSubscriptionSerialRetrieve(newItems.values());
        mapPocBundleAssetToSubscription(newItems.values());
        generateVirtualSerialNumber(virtualAssets);
        
    }
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug('After Update');
        Map<Id,Asset> hardwareECAssetIds= new  Map<Id,Asset>();
        Map<Id,Asset> softwareECBaseAssetIds= new  Map<Id,Asset>();
        Set<Id> setAccIds=new Set<Id>();
        Set<Id> setECAcctIds= new Set<Id>();
        Set<Id> setWanOpAcctIds= new Set<Id>();
        List<Asset> lstLicenseAssets= new List<Asset>();
        List<Asset> virtualAssets = new List<Asset>();
        List<Asset> lstAsset = new List<Asset>();
        if(newItems!=null && newItems.size()>0)
        {
            for (Id assetId : newItems.keyset())
            {
                Asset newAsset=(Asset)newItems.get(assetId);
                Asset oldAsset=(Asset)oldItems.get(assetId);
                if(newAsset.Product_Quote_Type__c=='NX/VX' && newAsset.Product_Family__c=='Product' && newAsset.SerialNumber == null) {
                    if(newAsset.Get_Serial__c == true) {
                        newAsset.Get_Serial__c = false;
                        lstAsset.add(newAsset);
                    }
                }
                
                if(newAsset.Product_Family__c=='Virtual Image')
                {
                    //if(newAsset.Is_Selected_For_Renewal__c && !oldAsset.Is_Selected_For_Renewal__c) virtualAssets.add(newAsset);
                }
                    
                if(oldAsset.AccountId!=newAsset.AccountId || oldAsset.Status!=newAsset.Status)
                {
                    if(newAsset.Product_Quote_Type__c=='EDGECONNECT' && newAsset.Product_Family__c=='Product' && (newAsset.Status=='Customer Evaluation' || newAsset.Status=='Customer Owned'))
                    {
                        hardwareECAssetIds.put(newAsset.Id,newAsset);
                        setAccIds.add(newAsset.AccountId);
                    }
                    
                    if(newAsset.Product_Quote_Type__c=='EDGECONNECT' && newAsset.Model__c.startsWith('EC-BASE' )&& newAsset.Product_Family__c=='Virtual Image' && (newAsset.Status=='Customer Evaluation' || newAsset.Status=='Customer Subscription Active'))
                    {
                        softwareECBaseAssetIds.put(newAsset.Id,newAsset);
                        setAccIds.add(newAsset.AccountId);
                    }
                }
            }
            AddActiveECBaseLicense(hardwareECAssetIds,softwareECBaseAssetIds,setAccIds); //Prajakta this is not required as in CPQ there will be subscription record for EC
            MakeFinalUpdateToAccount();
            //generateVirtualSerialNumber(virtualAssets);
            //populateAssetFields(newItems.values());
        }
        
    }
    public void AfterDelete(Map<Id, SObject> oldItems) {
        Map<Id,Account> lstCPAcctIds= new Map<Id,Account>();
        for(Id assetId : oldItems.keySet())
        {
            Asset oldAsset=(Asset)oldItems.get(assetId);
            if(oldAsset.Status=='Customer Evaluation' && oldAsset.Model__c.startsWith('EC') && oldAsset.Product_Family__c=='Virtual Image')
            {
                if(!lstSWCPAccount.contains(oldAsset.AccountId))
                {
                    lstSWCPAccount.add(oldAsset.AccountId);
                }
            }  
        }
        MakeFinalUpdateToAccount();
    }
    public void AfterUndelete(Map<Id, SObject> newItems) {
        if(newItems!=null)
        {
            for(Id assetId : newItems.keySet())
            {
            }
        }
       
    }
   
    private void MakeFinalUpdateToAccount() {
        Set<Id> acctIds= new Set<Id>();
        acctIds.addAll(lstHWCPAccount);
        acctIds.addAll(lstSWCPAccount);
        List<Account> lstAccountToUpdate = new List<Account>();
        if(acctIds.size()>0)
        {
            for(Id accountId :acctIds)
            {
                Account accountInfo=new Account(Id=accountId);
                if(lstHWCPAccount!=null && lstHWCPAccount.contains(accountId))
                {
                    accountInfo.Sync_with_Cloud_Portal__c=true;
                }
                if(lstSWCPAccount!=null && lstSWCPAccount.contains(accountId))
                {
                    accountInfo.Sync_Virtual_Assets_with_CP__c=true;
                }   
                lstAccountToUpdate.add(accountInfo);
            }
        }
        if(lstAccountToUpdate.size()>0)
        {
            update lstAccountToUpdate;
        }
    }

    
    private void AddActiveECBaseLicense(Map<Id,Asset> hardwareECAssetIds,Map<Id,Asset> softwareECBaseAssetIds, Set<Id> setAccIds) {
        Map<string,Id> firstECBaseLicense= new  Map<string,Id>();
        List<Asset> lstHardwareAssetToUpdate=new List<Asset>();
        if(hardwareECAssetIds.size()>0)
        {
            List<Asset> lstBaseLicenses=[Select Id,AccountId,Status from Asset where AccountId in:setAccIds and Product2.Family='Virtual Image' and Status in('Customer Subscription Active','Customer Evaluation') and Product2.Name like 'EC-BASE-%' and Product2.Product_Type__c ='EDGECONNECT'];
            if(lstBaseLicenses!=null && lstBaseLicenses.size()>0)
            {
                for(Asset item: lstBaseLicenses)
                {
                    firstECBaseLicense.put(item.AccountId+'|'+item.Status,item.Id);
                }
            }
            for(Id assetId :hardwareECAssetIds.keySet())
            {
                Asset assetData=hardwareECAssetIds.get(assetId);
                string status=assetData.Status=='Customer Evaluation'?'Customer Evaluation':'Customer Subscription Active';
                if(firstECBaseLicense.containsKey(assetData.AccountId+'|'+status))
                {
                    Id baseLicense= firstECBaseLicense.get(assetData.AccountId+'|'+status);
                    Asset hardwareAssetToUpdate = new Asset(Id=assetId,Active_EC_Base_License__c=baseLicense);
                    lstHardwareAssetToUpdate.add(hardwareAssetToUpdate);
                }
            }
        }
        if(softwareECBaseAssetIds.size()>0)
        {
            for(Id assetId : softwareECBaseAssetIds.keySet())
            {
                Asset assetData=softwareECBaseAssetIds.get(assetId);
                string status='Customer Owned';
                if(assetData.Status=='Customer Evaluation')
                    status='Customer Evaluation';
                Set<Id> ids = (new Map<Id, Asset>([Select Id from Asset where AccountId=:assetData.AccountId and Product2.Family='Product' and Status=:status and Product2.Product_Type__c like 'EDGECONNECT' order by CreatedDate desc])).keySet();
                if(ids!=null && ids.size()>0)
                {
                    for(Id hardWareId : ids)
                    {
                        Asset hardwareAssetToUpdate = new Asset(Id=hardWareId,Active_EC_Base_License__c=assetId);
                        lstHardwareAssetToUpdate.add(hardwareAssetToUpdate);
                    }
                    
                }
            }
        }
        if(lstHardwareAssetToUpdate.size()>0)
        {
            update lstHardwareAssetToUpdate;
        }
    }
    
    
 // Author : Ronald Pascual
 // Date: March 26, 2018
 // Description : To Pull the Status, Part Number, and Serial Number from the Order Product Items to Asset. 
 // -------------------------------------------------------------------------------------------------------
 
 // START of Activation Order task -------@@ 
 // Before Insert Trigger 
    private static void populatePOCIdInAsset(List<Asset> assets){
        
        Set<Id> assetIds = new Set<Id>();
        List<Asset> assetWithPocId = new List<Asset>();
        
        for(Asset asset: assets){
            assetIds.add(asset.id);
        }
        
        List<Asset> assetToUpdate = [SELECT Id, Name, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.POC_ID__c FROM Asset WHERE Id IN: assetIds];
        
        for(Asset a: assetToUpdate){
            if(a.SBQQ__QuoteLine__r.POC_ID__c != null){
                a.POC_ID__c = a.SBQQ__QuoteLine__r.POC_ID__c;
                assetWithPocId.add(a);
            }
        }
        
        if(assetWithPocId.size()>0){
            update assetWithPocId;
        }
        
    }
    
    /*private static Map<Id, List<Asset>> groupAssetsByOrderProduct(List<Asset> assetProductEqualToPhysical){
         Map<Id, List<Asset>> orderProductToAssets = new Map<Id, List<Asset>>();
         //Map<Id, Asset> QuoteLinetoAssetMap = new Map<Id, Asset>();
         Map<Integer, Order_Product_Item__c> NumtoOrderProductItemMap = new Map<Integer, Order_Product_Item__c>();
         List<Asset> assetRelatedToOrderProducts = new List<Asset>();
         List<Order_Product_Item__c> OrderProductItemstoUpdate = new List<Order_Product_Item__c>();
         Set<Id> AssetQuoteLineIds = new Set<Id>();
         Set<Id> OrderItemIds = new Set<Id>();
         Set<Id> OrderProductItemIds = new Set<Id>();
         Set<Order_Product_Item__c> OrderProductItemstoUpdateSet = new Set<Order_Product_Item__c>();
         Integer OrderQuantity;
         Integer counter = 1;
         Integer counter2 = 1;
        
        //Loop through the Assets
        for(Asset a: assetProductEqualToPhysical){
            
            //assetRelatedToOrderProducts = new List<Asset>();
            orderProductToAssets.put(a.SBQQ__QuoteLine__c, assetRelatedToOrderProducts);
            
            //Get Quote Line Ids
            if(a.SBQQ__QuoteLine__c != NULL){
                AssetQuoteLineIds.add(a.SBQQ__QuoteLine__c);
            }
            
            //Query Order Products where Quote Line Ids
            for(OrderItem oi: [SELECT Id, SBQQ__QuoteLine__c, Quantity FROM OrderItem WHERE SBQQ__QuoteLine__c =: AssetQuoteLineIds]){
                OrderItemIds.add(oi.id);
                OrderQuantity = Integer.valueOf(oi.Quantity);
            }
            
            //Query Order Product Items, order by created by
            for(Order_Product_Item__c op: [SELECT Id, Status__c, Part_Number__c, Serial_Number__c, Asset__c FROM Order_Product_Item__c WHERE Order_Product__c =: OrderItemIds ORDER BY CreatedDate DESC ]){
                //Put in list
                //Loop through Asset again and populate
                
                //counter = 1;
                NumtoOrderProductItemMap.put(counter, op);
                counter++;
            }
            
            //System.debug('OrderProductItemstoUpdateSet values = ' + OrderProductItemstoUpdateSet);
            
            System.debug('NumtoOrderProductItemMap values = ' + NumtoOrderProductItemMap);
            
            
        }
        
        //Loop on Asset again
        for(Asset a: assetProductEqualToPhysical){
            //counter2 = 1;
            System.debug('counter2 value = ' + counter2);
            if(!NumtoOrderProductItemMap.isEmpty()){
                
                if(counter2 <= OrderQuantity){
                    a.Status = NumtoOrderProductItemMap.get(counter2).Status__c;
                    a.Part_Number__c = NumtoOrderProductItemMap.get(counter2).Part_Number__c;
                    a.SerialNumber = NumtoOrderProductItemMap.get(counter2).Serial_Number__c;
                    assetRelatedToOrderProducts.add(a);
                    counter2++;
                }
            }

            
        }
        
        if(!OrderProductItemstoUpdateSet.isEmpty()){
            update new List<Order_Product_Item__c>(OrderProductItemstoUpdateSet);
        }
        
        System.debug('assetRelatedToOrderProducts values = ' + assetRelatedToOrderProducts);
        
        return orderProductToAssets;
    }*/
    public static void handleOpisOnAssetGenerate(List<Order_Product_Item__c> opiList, Map<Id,Order_Product_Item__c> oldMap) {
        Set<Id> assetId = new Set<Id>();
        for(Order_Product_Item__c opi : opiList) {
            //evaluate changes only
            if(opi.Asset__c != null && opi.Existing_Asset__c != null && opi.Asset__c != null && oldMap.get(opi.Id).Asset__c != null) {
                assetId.add(opi.Existing_Asset__c); 
            }
        }
        List<Asset> astListDel = new List<Asset>();
        for(Id id : assetId) {
            astListDel.add(new Asset(Id=id));
        }
        Database.delete(astListDel, false);
    }
    
    private static void DeleteGeneratedAsset (List<Asset> AssetList){
        
        System.debug('DeleteGeneratedAsset List = ' + AssetList);
        
        List<Asset> ToDeleteAssets = new List<Asset>();
        Set<Id> AssetQuoteLineIds = new Set<Id>();
        Set<Id> OrderItemIds = new Set<Id>();
        
        Map<Id, Id> qlToAsset = new Map<Id, Id>();
        Map<Id, Asset> assetMap = new Map<Id, Asset>();
        
        for(Asset a : AssetList) {
            AssetQuoteLineIds.add(a.SBQQ__QuoteLine__c);
            qlToAsset.put(a.SBQQ__QuoteLine__c, a.Id);
            assetMap.put(a.Id, a);
        }
        
        for(OrderItem oi: [SELECT Id, SBQQ__QuoteLine__c, Quantity FROM OrderItem WHERE SBQQ__QuoteLine__c =: AssetQuoteLineIds]){
            OrderItemIds.add(oi.id);
        }
        List<Asset> assetToDel = new List<Asset>();
        for(Order_Product_Item__c op: [SELECT Id, Status__c, Part_Number__c, Serial_Number__c, Asset__c, Existing_Asset__c,Existing_Asset__r.Id, Existing_Asset__r.SerialNumber FROM Order_Product_Item__c WHERE Order_Product__r.SBQQ__QuoteLine__c  =: AssetQuoteLineIds]){
            if(op.Existing_Asset__c != NULL && op.Asset__c != null){
                assetToDel.add(op.Existing_Asset__r);
            }
        }
        delete assetTODel;
        
    }
    
    private static void updateShipmentDateOfAsset(List<Asset> incomingAsset){
        Map<Id, List<Asset>> quoteToAsset = new Map<Id, List<Asset>>();
        List<Asset> updateAsset = new List<Asset>();
        Set<Id> assetIds = new Set<Id>();
        
        for(Asset asset: incomingAsset){
           assetIds.add(asset.Id);
        }
        
        List<Asset> assetlst = [SELECT Id, SBQQ__QuoteLine__r.SBQQ__Quote__c FROM Asset WHERE Id IN: assetIds];
        for(Asset a: assetlst){
            if(quoteToAsset.containsKey(a.SBQQ__QuoteLine__r.SBQQ__Quote__c)){
                 List<Asset> assetToUpdateTheShipmentDate = quoteToAsset.get(a.SBQQ__QuoteLine__r.SBQQ__Quote__c);
                 assetToUpdateTheShipmentDate.add(a);
            }
     
            else{
                 quoteToAsset.put(a.SBQQ__QuoteLine__r.SBQQ__Quote__c, new List<Asset>{a});
            }
        }
        
        Set<Id> assetQuoteIds = quoteToAsset.keySet();
        System.debug('asset quote ids' + assetQuoteIds);
        
        Order orderlst = queryForOrder(assetQuoteIds);
        System.debug('order list ' + orderlst);
      
        if(orderlst != null && orderlst.EffectiveDate != null){
            for(Asset asset: assetlst){
                DateTime dt = orderlst.EffectiveDate;
                Date shipDate = dt.date();
                asset.Ship_Date__c = orderlst.EffectiveDate;
                updateAsset.add(asset);
            }
        }
        
        
        if(updateAsset.size()>0){
            update updateAsset;
        }
    }
    
    private static Order queryForOrder(Set<Id> assetQuoteIds){
        Order parentOrder = new Order();
        
        try{
            parentOrder = [SELECT Id, ActivatedDate, EffectiveDate, SBQQ__Contracted__c, SBQQ__Quote__c FROM Order WHERE SBQQ__Quote__c IN: assetQuoteIds AND SBQQ__Contracted__c =TRUE LIMIT 1];
        }
        catch(QueryException qe){
            System.debug(qe.getMessage());
        }
        
        System.debug('Assets related to Subscriptions: ' + parentOrder);
        
        return parentOrder;
    }
    
    private static void updateAssetStatus(List<Asset> assetStatusToUpdate) {
        Set<Id> quoteLineId = new Set<Id>();
        Set<Id> productId = new Set<Id>();
        
        for(Asset asset: assetStatusToUpdate){
           quoteLineId.add(asset.SBQQ__QuoteLine__c);
           productId.add(asset.Product2Id);
        }
        
        Map<Id, SBQQ__QuoteLine__c> qline = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, POC_ID__c, SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE Id IN :quoteLineId]);
        Map<Id, Product2> prodMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Id IN :productId]);
        
        for(Asset a: assetStatusToUpdate){
            SBQQ__QuoteLine__c ql = qline.get(a.SBQQ__QuoteLine__c);
            Product2 p2 = prodMap.get(a.Product2Id);
            
            
            if(ql != null && ql.POC_ID__c != null && ql.POC_ID__c != 0){
                a.Status = 'Customer Evaluation';
            }
            if(p2 != null && p2.Name.contains('Asset') && p2.Name != null){
                a.Status = 'Customer Subscription Active';  
            }
            if(a.Status == null && a.Product_Category__c == 'Appliance') {
                a.Status = 'Customer Owned'; 
            }
            if(a.Status == null) {
                a.Status = 'Customer Subscription Active'; 
            }
            //updateAsset.add(a);
        }
    }

    public static void retrieveAssetSerials(List<Asset> newAssets) {

        Set<Id> qLineCollect = new Set<Id>();
        Set<Id> orderCollect = new Set<Id>();
        for(Asset a : newAssets) {
            qLineCollect.add(a.SBQQ__QuoteLine__c);
            orderCollect.add(a.SBQQ__OrderProduct__r.OrderId);
        }
        qLineCollect.remove(null);

        Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE Id IN :qLineCollect]);
        Set<Id> quoteIdCollect = new Set<Id>();
        
        for(SBQQ__QuoteLine__c ql : quoteLineMap.values()) {
            quoteIdCollect.add(ql.SBQQ__Quote__c);
        }
        
        Map<Id, Map<Id, Order_Product_Item__c>> opiToQuote = new Map<Id, Map<Id, Order_Product_Item__c>>();
        List<Order_Product_Item__c> opiQuery = 
            [SELECT Id, Existing_Asset__c, Serial_Number__c, Part_Number__c, Order_Product__r.OrderId, 
                Order_Product__r.SBQQ__QuoteLine__c, Order_Product__r.SBQQ__QuoteLine__r.SBQQ__Quote__c, 
                Status__c, Order__c, Order__r.TemporaryStartDateHolder__c, Order__r.SBCF_Shipping_Address__c
                FROM Order_Product_Item__c 
                WHERE Order__c IN :orderCollect AND (Asset__c = NULL OR Asset__c IN :newAssets)];
        
        
        for(Order_Product_Item__c opi : opiQuery) {
            if(!opiToQuote.containsKey(opi.Order__c)) {
                opiToQuote.put(opi.Order__c, new Map<Id, Order_Product_Item__c>());
            }
            opiToQuote.get(opi.Order__c).put(opi.Id, opi);
        }
        
        List<Order_Product_Item__c> opiIdDone = new List<Order_Product_Item__c>();
        List<Asset> updateAssets = [SELECT Id, Name, SerialNumber, Part_Number__c, SBQQ__QuoteLine__c, SBQQ__OrderProduct__c, 
        SBQQ__OrderProduct__r.Order.SBCF_Shipping_Address__c, SBQQ__OrderProduct__r.OrderId, SBQQ__OrderProduct__r.Order.Tracking_Information__c
             FROM Asset WHERE Id IN :newAssets]; 
        

        
        for(Asset a : updateAssets) {
            Map<Id, Order_Product_Item__c> opitemMap = opiToQuote.get(a.SBQQ__OrderProduct__r.OrderId);
            
            if(opitemMap!=null && opitemMap.size() > 0) {
                Order_Product_Item__c opiUp = opitemMap.get(opitemMap.values()[0].Id);
                opiUp.Asset__c = a.Id;
                
                a.Name = opiUp.Serial_Number__c;
                a.SerialNumber = opiUp.Serial_Number__c;
                a.Part_Number__c = opiUp.Part_Number__c;
                a.Status = opiUp.Status__c;
                a.Tracking_Information__c = a.SBQQ__OrderProduct__r.Order.Tracking_Information__c;
                a.Ship_To_Location__c = a.SBQQ__OrderProduct__r.Order.SBCF_Shipping_Address__c;
                if(a.Status == null) a.Status = 'Customer Owned';
                
                if(a.Ship_Date__c != opiUp.Order__r.TemporaryStartDateHolder__c) {
                    a.Ship_Date__c = opiUp.Order__r.TemporaryStartDateHolder__c;
                    a.Warranty_Start_Date__c = opiUp.Order__r.TemporaryStartDateHolder__c;
                }
                
                opiIdDone.add(opiUp);
                opiToQuote.get(a.SBQQ__OrderProduct__r.OrderId).remove(opitemMap.values()[0].Id);
            }
        }
        
        update opiIdDone;
        update updateAssets;
        
    }
    
    private static void generateVirtualSerialNumber(List<Asset> newAssets) {
        List<Asset_Mac__c> macList = new List<Asset_Mac__c>();
        
        for(Asset a : newAssets) {
            macList.add(new Asset_Mac__c(
                AssetId__c = a.Id,
                Used__c = true
            ));
        }        
        Map<Id, Id> macToAsset = new Map<Id, Id>();
        if(!macList.isEmpty()) insert macList;

        for(Asset_Mac__c am : macList) {
            macToAsset.put(am.AssetId__c, am.Id);
        }
        
        List<Asset> assetReUpdate = [SELECT Id, SerialNumber FROM Asset WHERE Id IN :macToAsset.keySet()];
        Map<Id, Asset_Mac__c> macMap = new Map<Id, Asset_Mac__c>();
        for(Asset_Mac__c am : [SELECT Id, AssetId__c, Name FROM Asset_Mac__c WHERE Id IN :macToAsset.values()]) {
            macMap.put(am.AssetId__c, am);
        }
        
        for(Asset a : assetReUpdate) {
            if(macMap.containsKey(a.Id)) {
                a.SerialNumber = '001BBC' + VirtualAssetManager.toHex(Integer.valueOf(macMap.get(a.Id).Name));
                a.Name = '001BBC' + VirtualAssetManager.toHex(Integer.valueOf(macMap.get(a.Id).Name));
            }
        }
        if(!assetReUpdate.isEmpty()) update assetReUpdate;
    }

    private void mapPocBundleAssetToSubscription(List<Asset> newList) {
        Set<Id> quoteLineId = new Set<Id>();
        for(Asset a : newList) {
            quoteLineId.add(a.SBQQ__QuoteLine__c);
        }

        Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>(
            [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.SBCF_Evaluation_Quote__c, SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__c 
            FROM SBQQ__QuoteLine__c 
            WHERE Id IN :quoteLineId AND SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Name LIKE '%POC Bundle%']
        );
        
        Set<Id> assetIdToUpdate = new Set<Id>();
        for(Asset a : newList) {
            if(quoteLineMap.containsKey(a.SBQQ__QuoteLine__c)) {
                assetIdToUpdate.add(a.Id);
            }
        }   
        if(!assetIdToUpdate.isEmpty()) runMapPocBundleAsset(assetIdToUpdate);
    }
    
    private void runNonSubscriptionSerialRetrieve(List<Asset> newList) {
        Set<Id> productMap = new Set<Id>();
        for(Asset a : newList) {
            productMap.add(a.Product2Id);
        }

        Map<Id, Product2> productAssetMap= new Map<Id, Product2>(
            [SELECT Id
            FROM Product2
            WHERE Id IN :productMap AND SBQQ__SubscriptionTerm__c = NULL AND (Family = 'Physical' OR Family = 'Product')]
        );
        
        Set<Id> assetIdToUpdate = new Set<Id>();
        for(Asset a : newList) {
            if(productAssetMap.containsKey(a.Product2Id)) {
                assetIdToUpdate.add(a.Id);
            }
        }
        if(!assetIdToUpdate.isEmpty()) nonSubscriptionSerialRetrieve(assetIdToUpdate);
    }

    @future
    private static void nonSubscriptionSerialRetrieve(Set<Id> assetId) {
        SubscribedAssetTriggerHandler.isFuture = true;
        retrieveAssetSerials( [SELECT Id, SBQQ__QuoteLine__c, SBQQ__OrderProduct__c, SBQQ__OrderProduct__r.OrderId FROM Asset WHERE Product_Family__c = 'Product' AND SerialNumber = NULL AND ID IN :assetId]);
    }
    
    @future
    private static void runMapPocBundleAsset(Set<Id> assetId) {
        SubscribedAssetTriggerHandler.isFuture = true;
        List<Asset> newAssets = [SELECT Id, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__RequiredBy__c, SBQQ__QuoteLine__r.SBQQ__Quote__c, SBQQ__OrderProduct__c, SBQQ__OrderProduct__r.OrderId FROM Asset WHERE Id IN :assetId];

        Set<Id> orderId = new Set<Id>();

        for(Asset a : newAssets) {
            orderId.add(a.SBQQ__OrderProduct__r.OrderId);
        }

        Map<String, SBQQ__Subscription__c> comboToSubMapping = new Map<String, SBQQ__Subscription__c>();
        for(SBQQ__Subscription__c sub : [SELECT Id, SBQQ__QuoteLine__r.SBQQ__RequiredBy__c, SBQQ__Contract__r.SBQQ__Order__c FROM SBQQ__Subscription__c WHERE SBQQ__Contract__r.SBQQ__Order__c IN :orderId]) {
            //concat required by quote and order Id
            comboToSubMapping.put(sub.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c + '/' + sub.SBQQ__Contract__r.SBQQ__Order__c, sub);
        }

        List<SBQQ__SubscribedAsset__c> subAssetToInsert = new List<SBQQ__SubscribedAsset__c>();
        for(Asset a : newAssets) {
            subAssetToInsert.add(
                new SBQQ__SubscribedAsset__c(
                    SBQQ__Asset__c=a.Id, 
                    SBQQ__Subscription__c=comboToSubMapping.get(a.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c+'/'+a.SBQQ__OrderProduct__r.OrderId).Id
                )
            );
        }
        insert subAssetToInsert;

    }
    
}