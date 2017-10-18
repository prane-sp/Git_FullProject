public class SPQuoteTriggerHandler implements ITriggerHandler {
    Map<Id,ID> mapQuoteOpp= null;
    public SPQuoteTriggerHandler()
    {
        
    }
    
    public Boolean IsDisabled()
    {
        return false;
    }
    public void BeforeInsert(List<SObject> newItems) 
    {
       
        if(newItems!=null && newItems.size()>0)
        {
        }
        
    }
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) 
    {
        if(newItems!=null && newItems.size()>0)
        {
            
            
        }
    }
    public void BeforeDelete(Map<Id,SObject> oldItems) 
    {
        
    }
    public void AfterInsert(Map<Id, SObject> newItems) 
    {
         mapQuoteOpp= new Map<Id,Id>();
        if(newItems!=null && newItems.size()>0)
        {
            for(Id quoteId:newItems.keyset())
            {
                Quote__c quoteInfo=(Quote__c)newItems.get(quoteId);
                if(quoteInfo.Primary__c && quoteInfo.Opportunity__c!=null)
                {
                    mapQuoteOpp.put(quoteInfo.Id,quoteInfo.Opportunity__c);
                }
            }
            
            CheckPrimaryFlag();
        }
    }
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) 
    {     
        List<Quote__c> lstPrimaryQuotes= new List<Quote__c>();
        List<Quote__c> lstNotPrimaryQuotes= new List<Quote__c>();
        mapQuoteOpp= new Map<Id,Id>();
        if(newItems!=null && newItems.size()>0)
        {
            for (Id quoteId : newItems.keyset())
            {
                Quote__c newQuote= (Quote__c)newItems.get(quoteId);
                Quote__c oldQuote= (Quote__c)oldItems.get(quoteId);
                
                if(newQuote.Primary__c!=oldQuote.Primary__c)
                {
                    if(newQuote.Primary__c)
                    {
                        lstPrimaryQuotes.add(newQuote);
                        if(newQuote.Opportunity__c!=null)
                            mapQuoteOpp.put(newQuote.Id,newQuote.Opportunity__c);                        
                    }
                    else
                    {
                        lstNotPrimaryQuotes.add(newQuote);
                    }
                }
                else
                {
                    if(newQuote.Primary__c)
                    {
                        if(newQuote.Number_of_Quote_Lines__c != oldQuote.Number_of_Quote_Lines__c)
                        {
                            lstPrimaryQuotes.add(newQuote);
                        }
                        
                    }
                }
                
            }
            CheckPrimaryFlag();
            SetProductType(lstPrimaryQuotes,lstNotPrimaryQuotes);
        }
        
    }
    public void AfterDelete(Map<Id, SObject> oldItems) 
    {
        
    }
    public void AfterUndelete(Map<Id, SObject> newItems) 
    {
        
    }
    
    private void CheckPrimaryFlag()
    {
        if(mapQuoteOpp!=null && mapQuoteOpp.size()>0)
        {
            List<Quote__c> existingPrimaryQuotes = [Select Id from Quote__c where Opportunity__c in :mapQuoteOpp.values() and Id not in:mapQuoteOpp.keySet() and Primary__c=true];
            if(existingPrimaryQuotes!=null && existingPrimaryQuotes.size()>0)
            {
                for(Quote__c existingPrimaryQuote : existingPrimaryQuotes)
                {
                    existingPrimaryQuote.Primary__c = false;
                }
                try
                {
                    update existingPrimaryQuotes;
                }
                catch(Exception ex)
                {
                    Trigger.new[0].addError(ex.getMessage());
                }
            }
        }
    }
    private void SetProductType(List<Quote__c> lstPrimaryQuotes, List<Quote__c> lstNotPrimaryQuotes)
    {
        if(lstPrimaryQuotes.size()>0)   
        {
            List<Opportunity> lstOpp= new List<Opportunity>();
            for(Quote__c primaryQuote: lstPrimaryQuotes)
            { 
                Opportunity opp= QuoteHelper.SetOpportunityProductType(primaryQuote);
                if(opp!=null)
                {
                    lstOpp.add(opp);
                }
            }
            if(lstOpp.size()>0)
            {
                update lstOpp;
            }
        }
        
        if(lstNotPrimaryQuotes.size()>0)   
        {
            List<Opportunity> lstOpp= new List<Opportunity>();
            for(Quote__c notPrimaryQuote: lstNotPrimaryQuotes)
            {
                List<Quote__c> quoteList= new List<Quote__c>();
                quoteList= QuoteHelper.GetPrimaryQuote(notPrimaryQuote.Opportunity__c);
                if(quoteList!=null && quoteList.size()==0)
                {
                    
                    Opportunity opp=  QuoteHelper.SetOpportunityProductTypeToNone(notPrimaryQuote);
                    if(opp!=null)
                    {
                        lstOpp.add(opp);
                    }
                }
            }
            if(lstOpp.size()>0)
            {
                update lstOpp;
            }
        }   
    }
}