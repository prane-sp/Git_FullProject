public class OppoQuoteController
{
    public Enum CopyStage{CopyAndEdit, CopyOnly, DoNotCopy}
    public Opportunity oppo{get;set;}
    public Quote__c quote{get;set;}
    public Integer stage{get;set;}
    public boolean IsDistributor{get;set;}
    public OppoQuoteController(ApexPages.StandardController controller)
    {
        String oppoId = ((Opportunity)controller.getRecord()).Id;
        IsDistributor=SilverPeakUtils.IsDistributorCommunityUser();
        if(oppoId instanceOf Id)
        {
            oppo = [select name, account.name, Pricebook2Id,Registering_Partner__c, HasOpportunityLineItem, Owner.ManagerId,
                       (Select Id From OpportunityLineItems)
                    from opportunity where id = :oppoId];
            //oppo = new Opportunity();
            quote = new Quote__c(Opportunity__r = oppo,Tier_1_Partner__c=oppo.Registering_Partner__c,Opp_Owner_Manager__c=oppo.Owner.ManagerId,  Opportunity__c = oppoId, Quote_Date__c = Date.today(), PaymentTerm__c = 'Net 30', Quote_Valid_Until__c = Date.today().addDays(30));
            if(IsDistributor)
            {
                User userData=[select Id,ContactId,Contact.AccountId from User where Id=:UserInfo.getUserId()];
                quote.Tier_2_Partner__c=userData.Contact.AccountId;
                quote.PreparedFor__c=userdata.ContactId;
            }
        }
        else
        {
            quote = new Quote__c();
        }
    }
    
    public List<SelectOption> getPriceBooks()
    {
        List<SelectOption> options = new List<SelectOption>();
        for(Pricebook2 book : [select Id, Name from Pricebook2])
        {
            options.add(new SelectOption(book.Id, book.Name));
        }
        return options;
    }
    
    public void copyItemsToQuote()
    {
        OpportunityLineItem[] olist;
        
        olist = [select Id, OpportunityId, SortOrder, PricebookEntryId, Quantity, 
                    TotalPrice, UnitPrice, ListPrice, DiscountPercent__c, ServiceDate, Description, CreatedDate, 
                    CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, 
                    IsDeleted , PricebookEntry.Name, PricebookEntry.Product2id
                    From OpportunityLineItem 
                    where OpportunityId = :quote.Opportunity__c ];
        
        // create new quote lines
        Quote_Line__c[] qlines = new list<Quote_Line__c>(); 
        for ( OpportunityLineItem oitem : olist) 
        {
            Quote_Line__c ql = new Quote_Line__c(
                                                    Quote__c = quote.id,
                                                    Discount_Percent__c = oitem.DiscountPercent__c,
                                                    Quantity__c = oitem.Quantity,
                                                    Unit_Price__c = oitem.UnitPrice,
                                                    //Description__c = oitem.Description,
                                                    //ServiceDate__c = oitem.ServiceDate,
                                                    Product__c = oitem.PricebookEntry.Product2id
                                                ); 
            qlines.add(ql);     
        }
        if ( qlines.size() > 0 ) 
        {
            delete [select Id from Quote_Line__c where Quote__c = :quote.id];
            insert qlines;
        }
    }
    
    public PageReference cancel()
    {
        return new PageReference('/' + oppo.Id);
    }
    
    public PageReference save()
    {
        SavePoint sp = Database.setSavePoint();
        try
        {
            PageReference returnPage;
           
            if(!oppo.HasOpportunityLineItem)
            {
                update oppo;
                upsert quote;
                returnPage = new PageReference('/apex/Quote?Id=' + quote.Id); 
            }
            else
            {
                upsert quote;
                if(stage == CopyStage.CopyAndEdit.ordinal())
                {
                    copyItemsToQuote(); 
                    returnPage = new PageReference('/apex/Quote?Id=' + quote.Id);                   
                }
                else
                {
                    returnPage = new PageReference('/' + quote.Id);
                    if(stage == CopyStage.CopyOnly.ordinal())
                    {
                        copyItemsToQuote();                         
                    }
                    else
                    if(stage == CopyStage.DoNotCopy.ordinal())
                    {
                        //do noting right now
                    } 
                }             
            }
            
            // Check if the quote is the only one on the opp. If yes, then make it Primary
            List<Quote__c> lstQuotes=[Select Id from Quote__c where Opportunity__c=:oppo.Id and Id!=:quote.id];
            if(lstQuotes!=null && lstQuotes.size()==0)
            {
                
                quote.Primary__c=true;
                update quote;
            }
            return returnPage;           
        }
        catch(exception ex)
        {
            Database.rollback(sp);
            ApexPages.addMessages(ex);
            return null;
        }
    }
    
    
}