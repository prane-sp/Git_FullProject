public with sharing class HardwareShipmentController {

    public static final Integer CSV_COLUMN_SIZE = 26;

    public static final String STATUS_CUSTOMER_EVALUATION = 'Customer Evaluation';
    public static final String STATUS_CUSTOMER_OWNED = 'Customer Owned';
    public static final String DEFAULT_ORDER_PRODUCT_STATUS = STATUS_CUSTOMER_OWNED;
    public static final String ACTIVATED_ORDER_STATUS = 'Activated';
    public static final String SAVE_ORDER_SHIPPING_STATUS = 'Shipping - Complete';
    public static final String SAVE_PRICE_CALCULATION_STATUS = 'Completed';

    public static final String WARNING_MESSAGE_EXISTING_ASSET = 'Existing assets found. If you don’t change the serial number, the existing asset will be overridden with new data. Data includes: Account, Product, etc';
    public static final String SUCCESS_MESSAGE_NO_EXISTING_ASSETS = 'No existing assets were found matching the provided serial numbers.';
    public static final String ERROR_EXISTING_ASSET_WITH_STATUS_NOT_CUSTOMER_OWNED = 'A product exists on the order with a serial number matching an existing asset. Products matching existing assets must have a status of Customer Owned.';
    public static final String WARNING_USE_CHECK_SERIAL_NUMBERS_BEFORE_SUBMIT = 'Please Check Serial Numbers Status before Saving.';

    public static final String RECORD_TYPE_STANDARD = 'Sandard';
    public static final String RECORD_TYPE_EVAL = 'POC';

    public static final String RETURN_CHARACTER = '\r\n';
    public static final Integer DOUBLE_QUOTE_CHAR_VALUE = 34;

	public Order order {get;set;}

    public List<OrderShipmentHelper.OrderProductWrapper> orderProductWrappers {get;set;}
    public Document csvFile {get;set;}
    transient private List<CSVFileRow> fileRowWrappers {get;set;}

    public String copySerialNumberOrderProductId {get;set;}
    public OrderShipmentHelper.OrderProductWrapper copySerialNumberOrderProductWrapper {get;set;}
    public String copySerialNumbers {get;set;}

    public Boolean uploadedFile {get;set;}
    public Boolean existingAssetsExist {get;set;}
    public Boolean orderIsActivated {get;set;}
    public Boolean hasCheckedSerialNumbers {get;set;}

    public HardwareShipmentController(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()){
            stdController.addFields(OrderShipmentHelper.getAllOrderFieldsAPINames());
        }

        this.order = (Order)stdController.getRecord();

        this.orderIsActivated = OrderShipmentHelper.determineIsOrderActivated(this.order);

        if(this.orderIsActivated){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'Serial Numbers Cannot be applied to active orders.');
            ApexPages.addMessage(myMsg);
            return;
        }

        List<OrderItem> orderProducts = OrderShipmentHelper.queryForOrderProducts(order.Id, OrderShipmentHelper.PRODUCT_CATEGORY_HARDWARE);
        System.debug('Order Products: ' + orderProducts);

        List<Order_Product_Item__c> relatedOrderProductItems = OrderShipmentHelper.queryForOrderProductItems(orderProducts);
        System.debug('Related Order Product Items: ' + relatedOrderProductItems);

        List<OrderShipmentHelper.OrderProductItemWrapper> orderProductItemWrappers = OrderShipmentHelper.buildOrderProductItemWrappers(relatedOrderProductItems, orderProducts);
        System.debug('Order product item wrappers: ' + orderProductItemWrappers);

        this.orderProductWrappers = OrderShipmentHelper.buildOrderProductWrappers(orderProducts, orderProductItemWrappers);
        this.csvFile = new Document();
        this.fileRowWrappers = new List<CSVFileRow>();

        defaultOrderItemStatus();

        this.uploadedFile = false;
        this.existingAssetsExist = false;
        this.hasCheckedSerialNumbers = false;
    }

    /**
    *  Public Methods
    **/

    public PageReference checkSerialNumberStatus(){
        //this.hasCheckedSerialNumbers = true;

        //this.existingAssetsExist = false;
        //resetExistingAssets();

        //Set<String> serialNumbers = getSerialNumbersFromWrappers();

        //System.debug('Serial numbers from wrappers: ' + serialNumbers);

        //List<Asset> existingAssets = queryAssetsMatchingSerialNumbers(serialNumbers);
        //Map<String, Asset> serialNumberToAssetMap = buildSerialNumberToAssetMap(existingAssets);

        //Boolean assetsExistMatchingSerialNumbers = updateOrderProductWrappersExistingAssets(serialNumberToAssetMap);

        //if(assetsExistMatchingSerialNumbers){
        //    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,WARNING_MESSAGE_EXISTING_ASSET);
        //    ApexPages.addMessage(myMsg);
        //    this.existingAssetsExist = true;
        //}
        //else{
        //    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,SUCCESS_MESSAGE_NO_EXISTING_ASSETS);
        //    ApexPages.addMessage(myMsg);
        //}

        return null;
    }

    public PageReference rerenderForm(){
        return null;
    }

    public PageReference save(){
        //String errorValidating = validate();

        //if(!hasCheckedSerialNumbers){
        //    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, WARNING_USE_CHECK_SERIAL_NUMBERS_BEFORE_SUBMIT);
        //    ApexPages.addMessage(myMsg);
        //    return null;
        //}

        //if(errorValidating != null){
        //    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errorValidating);
        //    ApexPages.addMessage(myMsg);
        //    return null;
        //}

        //Savepoint sp = Database.setSavepoint();

        //String errorUpdating;

        //errorUpdating = updateOrderProducts();
        
        //if(errorUpdating != null){
        //    Database.rollback(sp);
        //    //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error updating order products. Error Details: ' + errorUpdating);
        //    //ApexPages.addMessage(myMsg);
        //    return null;
        //}

        //errorUpdating = updateOrder();

        //if(errorUpdating != null){
        //    Database.rollback(sp);
        //    //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error updating order. Error Details: ' + errorUpdating);
        //    //ApexPages.addMessage(myMsg);
        //    return null;
        //}

        //printAssetsCreatedInTheLast30Seconds();

        //PageReference page = new PageReference('/' + order.Id);
        //page.setRedirect(true);
        //return page;

        return null;
    }

    public PageReference returnToOrder(){
        PageReference page = new PageReference('/' + order.Id);
        page.setRedirect(true);
        return page;
    }

    public PageReference applyCSVFile(){
        System.debug('Applying CSV File.');

        if(csvFile.Body == null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: No CSV file uploaded.');
            ApexPages.addMessage(myMsg);
            return null;
        }

        try{
            List<String> csvElements = buildCSVElements();
            //this.fileRowWrappers = buildFileRowWrappers(csvElements);

            //System.debug('File rows before filter: ' + this.fileRowWrappers);

            //this.fileRowWrappers = filterFileRows(this.fileRowWrappers);

            //System.debug('File rows after filter: ' + this.fileRowWrappers);

            //Map<String, CSVFileRow> productCodeToCSVRow = buildProductCodeToCSVFileRow();
            //populateOrderProductWrappersWithFileInfo(productCodeToCSVRow);

            //uploadedFile = true;
        }
        catch(Exception e){
            System.debug('Exception occurred process file.');
            System.debug('Exception Message: ' + e.getMessage());
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'An error occurred processing the file. Please check ensure the file is in the correct format.');
            ApexPages.addMessage(myMsg);
        }

        return null;
    }

    public PageReference updateCopySerialNumberView(){
        System.debug('Update Copy Serial Number View.');
        System.debug('Copy Serial Number Order Product Id: ' + this.copySerialNumberOrderProductId);

        setCopySerialNumbersOrderProductWrapper();
        setCopySerialNumbers();

        return null;
    }

    /**
    * updateCopySerialNumberView helper methods
    **/

    private void setCopySerialNumbers(){
        copySerialNumbers = '';

        for(OrderShipmentHelper.OrderProductItemWrapper orderProductItemWrapper: this.copySerialNumberOrderProductWrapper.orderProductItems){
            if(orderProductItemWrapper.orderProductItem.Serial_Number__c != null){
                copySerialNumbers += orderProductItemWrapper.orderProductItem.Serial_Number__c + RETURN_CHARACTER;
            }
        }
    }

    private void setCopySerialNumbersOrderProductWrapper(){
        for(OrderShipmentHelper.OrderProductWrapper orderProductWrapper: this.orderProductWrappers){
            if(orderProductWrapper.orderProduct.Id == this.copySerialNumberOrderProductId){
                 this.copySerialNumberOrderProductWrapper = orderProductWrapper;
                 break;
            }
        }
    }

    /**
    *  Save and Ship Helper Methods
    */ 

    //private void printAssetsCreatedInTheLast30Seconds(){
    //    Datetime thirtySecondsAgo = System.now().addSeconds(-30);
    //    List<Asset> assetsCreatedInLast30Seconds = new List<Asset>();


    //    try{
    //        assetsCreatedInLast30Seconds = [SELECT Id, Name FROM Asset WHERE CreatedDate >= :thirtySecondsAgo];
    //    }
    //    catch(QueryException qe){
    //        System.debug(qe.getMessage());
    //    }

    //    System.debug('Assets Created In the Last 30 Seconds: ' + assetsCreatedInLast30Seconds);
    //}

    //private String validate(){
    //    String errorValidating;

    //    errorValidating = ensureCustomerOwnedStatusIfSNMatchesExistingAsset();

    //    return errorValidating;
    //}

    //private String ensureCustomerOwnedStatusIfSNMatchesExistingAsset(){
    //    String errorValidating;

    //    for(OrderShipmentHelper.OrderProductWrapper orderProductWrapper: this.orderProductWrappers){
    //        if(orderProductWrapper.existingAssetWrappers.size() > 0 && !STATUS_CUSTOMER_OWNED.equalsIgnoreCase(orderProductWrapper.orderProduct.SBCF_Status__c)){
    //            return ERROR_EXISTING_ASSET_WITH_STATUS_NOT_CUSTOMER_OWNED;
    //        }
    //    }

    //    return errorValidating;
    //}

    //private String updateOrderProducts(){
    //    try{
    //        List<OrderItem> orderProductsRelatedToWrappers = getOrderProductsOnWrappers();
    //        update orderProductsRelatedToWrappers;
    //    }
    //    catch(DMlException e){
    //        System.debug(e.getMessage());
    //        return e.getMessage();
    //    }

    //    return null;
    //}

    //private String updateOrder(){
    //    try{
    //        this.order.Status = ACTIVATED_ORDER_STATUS;
    //        this.order.Shipping_Status__c = SAVE_ORDER_SHIPPING_STATUS;
    //        this.order.SBQQ__Contracted__c = true;
    //        this.order.SBQQ__PriceCalcStatus__c = SAVE_PRICE_CALCULATION_STATUS;
    //        update order;
    //    }
    //    catch(DMLException e){
    //        System.debug(e.getMessage());
    //        return e.getMessage();
    //    }

    //    return null;
    //}

    //private List<OrderItem> getOrderProductsOnWrappers(){
    //    List<OrderItem> orderProductsRelatedToWrappers = new List<OrderItem>();

    //    for(OrderShipmentHelper.OrderProductWrapper orderProductWrapper: this.orderProductWrappers){
    //        orderProductsRelatedToWrappers.add(orderProductWrapper.orderProduct);
    //    }

    //    return orderProductsRelatedToWrappers;
    //}

    /**
    *  checkSericalNumberStatus Helper Methods
    */

    //private void resetExistingAssets(){
    //    for(OrderShipmentHelper.OrderProductWrapper orderProductWrapper: this.orderProductWrappers){
    //        orderProductWrapper.existingAssetWrappers = new List<OrderShipmentHelper.ExistingAssetWrapper>();
    //    }      
    //}

    //private Boolean updateOrderProductWrappersExistingAssets(Map<String, Asset> serialNumberToAssetMap){
    //    Boolean assetsExistMatchingSerialNumbers = false;

    //    for(OrderShipmentHelper.OrderProductWrapper orderProductWrapper: this.orderProductWrappers){
    //        if(orderProductWrapper.orderProduct.Serial_Number__c == null){
    //            continue;
    //        }

    //        List<String> parsedSerialNumbers = orderProductWrapper.orderProduct.Serial_Number__c.split(';');

    //        for(String serialNumber:parsedSerialNumbers){
    //            Asset existingAsset = serialNumberToAssetMap.get(serialNumber);

    //            if(existingAsset == null){
    //                continue;
    //            }

    //            System.debug('Existing asset found!');

    //            //orderProductWrapper.existingAssetIds.add(existingAsset.Id);
    //            orderProductWrapper.existingAssetWrappers.add(new OrderShipmentHelper.ExistingAssetWrapper(existingAsset.Id, SerialNumber, existingAsset));
    //            assetsExistMatchingSerialNumbers = true;                
    //        }
    //    }

    //    return assetsExistMatchingSerialNumbers;
    //}

    //private Map<String, Asset> buildSerialNumberToAssetMap(List<Asset> existingAssets){
    //    Map<String, Asset> serialNumberToAssetMap = new Map<String, Asset>();

    //    for(Asset existingAsset: existingAssets){
    //        serialNumberToAssetMap.put(existingAsset.SerialNumber, existingAsset);
    //    }

    //    System.debug('Serial Number to Asset Map: ' + serialNumberToAssetMap);

    //    return serialNumberToAssetMap;
    //}

    //private List<Asset> queryAssetsMatchingSerialNumbers(Set<String> serialNumbers){
    //    List<Asset> existingAssets = new List<Asset>();

    //    try{
    //        existingAssets = [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber != null AND SerialNumber in :serialNumbers];
    //    }
    //    catch(QueryException qe){
    //        System.debug(qe.getMessage());
    //    }

    //    System.debug('Existing Assets: ' + existingAssets);

    //    return existingAssets;
    //}

    //private Set<String> getSerialNumbersFromWrappers(){
    //    Set<String> serialNumbersFromWrappers = new Set<String>();

    //    for(OrderShipmentHelper.OrderProductWrapper orderProductWrapper: this.orderProductWrappers){
    //        if(orderProductWrapper.orderProduct.Serial_Number__c == null){
    //            // May want to stop here and display message to user. 
    //            continue;
    //        }

    //        List<String> parsedSerialNumbers = orderProductWrapper.orderProduct.Serial_Number__c.split(';');

    //        if(parsedSerialNumbers != null){
    //            for(String serialNumber: parsedSerialNumbers){
    //                serialNumbersFromWrappers.add(SerialNumber);
    //            }
    //        }            
    //    }

    //    return serialNumbersFromWrappers;
    //}


    /**
    *  defaultOrderItemStatus Helper Methods 
    */

    private void defaultOrderItemStatus(){
        String defaultOrderProductStatus = getDefaultOrderProductStatus();

        for(OrderShipmentHelper.OrderProductWrapper orderProductWrapper: this.orderProductWrappers){
            orderProductWrapper.orderProduct.SBCF_Status__c = defaultOrderProductStatus;
        }
    }   

    private String getDefaultOrderProductStatus(){
        String quoteRecordTypeName = getRecordTypeNameOnQuote();
        System.debug('Quote Record Type Name: ' + quoteRecordTypeName);

        if(quoteRecordTypeName == null){
            return DEFAULT_ORDER_PRODUCT_STATUS;
        }
        else if(quoteRecordTypeName.contains(RECORD_TYPE_STANDARD)){
            return STATUS_CUSTOMER_OWNED;
        }
        else if(quoteRecordTypeName.contains(RECORD_TYPE_EVAL)){
            return STATUS_CUSTOMER_EVALUATION;
        }
        else{
            return DEFAULT_ORDER_PRODUCT_STATUS;
        }
    }

    private String getRecordTypeNameOnQuote(){
        System.debug('Get Record Type Name On Quote');

        String quoteRecordTypeName;

        if(this.order.SBQQ__Quote__c == null){
            // Return null
            System.debug('SBQQ__Quote__c lookup field null');
            return quoteRecordTypeName;
        }

        try{    
            SBQQ__Quote__c relatedQuote = [SELECT RecordType.Name FROM SBQQ__Quote__c WHERE Id = :order.SBQQ__Quote__c LIMIT 1];

            // Should go into catch if null but just in case
            if(relatedQuote != null){
                System.debug('Related Quote Not Null. Assigning relatedQuote record type of: ' + relatedQuote.RecordType.Name);
                quoteRecordTypeName = relatedQuote.RecordType.Name;
            }
            else{
                System.debug('Related Quote is null.');
            }
        }
        catch(QueryException qe){
            System.debug('No quote returned from query');
            system.debug(qe.getMessage());
        }   

        return quoteRecordTypeName;
    }

    private void populateOrderProductWrappersWithFileInfo(Map<String, CSVFileRow> productCodeToCSVRow){
        for(OrderShipmentHelper.OrderProductWrapper orderProductWrapper: this.orderProductWrappers){
            CSVFileRow csvRow = productCodeToCSVRow.get(orderProductWrapper.orderProduct.Product2.ProductCode);

            if(csvRow == null){
                continue;
            }

            orderProductWrapper.orderProduct.Quantity = Decimal.valueOf(csvRow.column2);
            orderProductWrapper.orderProduct.Part_Number__c = csvRow.column3;
            orderProductWrapper.orderProduct.Serial_Number__c = csvRow.column4;
        }
    }
    
    private Map<String, CSVFileRow> buildProductCodeToCSVFileRow(){
        Map<String, CSVFileRow> productCodeToCSVRow = new Map<String, CSVFileRow>();

        for(CSVFileRow row: this.fileRowWrappers){
            productCodeToCSVRow.put(row.column1, row);
        }

        return productCodeToCSVRow;
    }

    private List<CSVFileRow> buildFileRowWrappers(List<String> csvElements){
        List<CSVFileRow> fileRowWrappers = new List<CSVFileRow>();

        for(Integer i = 0; i < csvElements.size(); i = i+CSV_COLUMN_SIZE){
            List<String> rowElements = new List<String>();

            for(Integer j = i; j < i + CSV_COLUMN_SIZE; j++){
                rowElements.add(csvElements[j]);
            }   

            fileRowWrappers.add(new CSVFileRow(rowElements));
        }

        return fileRowWrappers;
    }

    private List<String> buildCSVElements(){
        String csvBody = csvFile.Body.toString();
         
        System.debug('CSV File Body: ' + csvBody);
        csvBody = csvBody.replaceAll('(\\r|\\n)+', ',');
        System.debug('CSV File Body After removing linebreaks');

        Integer index = 0;
        Integer nextIndex = 0;

        //do{
            index = csvBody.indexOfChar(DOUBLE_QUOTE_CHAR_VALUE, index);

            System.debug('Index of ": ' + index);

            if(index != -1){
                System.debug('Index not equal to -1');

                nextIndex = csvBody.indexOfChar(DOUBLE_QUOTE_CHAR_VALUE, index+1);

                System.debug('Next index: ' + nextIndex);

                if(nextIndex != null){
                    String subString = csvBody.substring(index, nextIndex+1);

                    System.debug('Substring: ' + subString);

                    if(subString != null){
                        String updatedSubString = subString.replaceAll(',', ';');
                        updatedSubString = updatedSubString.replaceAll('"', '');
                        csvBody = csvBody.replaceAll(subString, updatedSubString);
                    }
                }
            }
            
        //}while(index != -1 || nextIndex != -1);


        //// Here everything should be truly column delimited.  

        //List<String> csvElements = csvBody.split(',');

        List<String> csvRows = csvBody.split('(\\r|\\n)+');

        System.debug('CSV Rows: ' + csvRows);
        System.debug('CSV Rows Size: ' + csvRows.size());

        index = csvBody.indexOfChar(DOUBLE_QUOTE_CHAR_VALUE, index);
        System.debug('Index still exist?: ' + index);

        //for(String csvRow: csvRows){
        //    Integer indexOfChar = csvRow.indexOfChar(DOUBLE_QUOTE_CHAR_VALUE);
        //    System.debug('indexOfChar: ' + indexOfChar);
        //}

        //System.debug('CSV File Elements: ' + csvElements);
        //System.debug('CSV File Elements Size: ' + csvElements.size());

        //return csvElements;

        return csvRows;
    }

    /*
    * Filter file rows that 
    *   - do not mate order Sales Order Number (col4) 
    *   - do not have a value for the SN. (col8)
    *   - do not have a value for the Product Code (col7)
    *   - do not have a quantity of 1 (col11)
    */
    private List<CSVFileRow> filterFileRows(List<CSVFileRow> unfilteredFileRows){
        List<CSVFileRow> filteredFileRows = new List<CSVFileRow>();

        for(CSVFileRow unfilteredRow: unfilteredFileRows){
            if(
                (unfilteredRow.column4 != null && unfilteredRow.column4.equalsIgnoreCase(this.order.Sales_Order_Number__c)) &&
                 unfilteredRow.column8 != null &&
                 unfilteredRow.column7 != null &&
                (unfilteredRow.column11 != null && unfilteredRow.column11.equalsIgnoreCase('1'))
                                                                                                                             ){
                filteredFileRows.add(unfilteredRow);
            }
        }

        return filteredFileRows;
    }

    /**
    *  applyCSVFile Helper Methods - End
    **/

    public class CSVFileRow{

        public String column1 {get;set;}
        public String column2 {get;set;}
        public String column3 {get;set;}
        public String column4 {get;set;} // Req# - Sales Order Number
        public String column5 {get;set;}
        public String column6 {get;set;}
        public String column7 {get;set;} // Item# - Product Code
        public String column8 {get;set;} // S/N - Serial Number
        public String column9 {get;set;}
        public String column10 {get;set;}
        public String column11 {get;set;} // Qty - Quantity
        public String column12 {get;set;}
        public String column13 {get;set;}
        public String column14 {get;set;}
        public String column15 {get;set;}
        public String column16 {get;set;}
        public String column17 {get;set;}
        public String column18 {get;set;}
        public String column19 {get;set;}
        public String column20 {get;set;}
        public String column21 {get;set;}
        public String column22 {get;set;}
        public String column23 {get;set;}
        public String column24 {get;set;}
        public String column25 {get;set;}
        public String column26 {get;set;}

        public CSVFileRow(List<String> rowElements){
            this.column1 = rowElements[0];
            this.column2 = rowElements[1];
            this.column3 = rowElements[2];
            this.column4 = rowElements[3];
            this.column5 = rowElements[4];
            this.column6 = rowElements[5];
            this.column7 = rowElements[6];
            this.column8 = rowElements[7];
            this.column9 = rowElements[8];
            this.column10 = rowElements[9];
            this.column11 = rowElements[10];
            this.column12 = rowElements[11];
            this.column13 = rowElements[12];
            this.column14 = rowElements[13];
            this.column15 = rowElements[14];
            this.column16 = rowElements[15];
            this.column17 = rowElements[16];
            this.column18 = rowElements[17];
            this.column19 = rowElements[18];
            this.column20 = rowElements[19];
            this.column21 = rowElements[20];
            this.column22 = rowElements[21];
            this.column23 = rowElements[22];
            this.column24 = rowElements[23];
            this.column25 = rowElements[24];
            this.column26 = rowElements[25];
        }   
    }

}