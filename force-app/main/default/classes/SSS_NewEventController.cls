/**
 * @description       : 
 * @author            : Shubham Raut
 * @group             : 
 * @last modified on  : 04-06-2023
 * @last modified by  : Shubham Raut
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   04-04-2023   Shubham Raut   Initial Version
**/

global without sharing class SSS_NewEventController {  
    @InvocableMethod(label='Save Destinations' description='Used for saving destinations')
    global static void saveDestination(List<NewEventWrapper> destinationWrapper) {
        if(destinationWrapper != null && !destinationWrapper.isEmpty()){
            if(destinationWrapper[0].noOfDestinations != 0 && destinationWrapper[0].noOfDestinations != destinationWrapper[0].destinations.size()){
                List<Destination__c> finalList = new List<Destination__c>();
                for(Destination__c dest: destinationWrapper[0].destinations){
                    finalList.add(dest);
                }
                Database.insert(finalList, false);
            }else if(destinationWrapper[0].noOfDestinations != 0){
                List<Database.SaveResult> saveResults = Database.insert(destinationWrapper[0].destinations, false);
            
            }
            
            if(destinationWrapper[0].futureBatcheDates != null && destinationWrapper[0].currentEventId != null){
                createFutureBatchesForEvent(destinationWrapper[0].currentEventId, destinationWrapper[0].futureBatcheDates);
            }
            
        }        
        
    }
    
    public static void createFutureBatchesForEvent(Id currentEventId, List<DateTime> futureBatcheDates){
        
        List<Trekking_Event__c> futureEvents = new List<Trekking_Event__c>();
        List<Destination__c> futureEventDestinations = new List<Destination__c>();
        Map<Integer, Trekking_Event__c> nextBatchEventTimeMap = new Map<Integer, Trekking_Event__c>();
        
        Trekking_Event__c mainEvent = [SELECT id, name, Event_slot__c, createdDate, Organization__r.name, 
                                           Start_time__c, End_Time__c, Grade__c, Batch_Size__c, cost__c, 
                                           (SELECT id, name, Location__c, Type__c, Visiting_Date__c 
                                            FROM Destinations__r) 
                                      FROM Trekking_Event__c 
                                      WHERE id = :currentEventId
                                      LIMIT 1];
        
        Date mainEventStartDate = Date.newInstance(mainEvent.Start_time__c.yearGmt(), mainEvent.Start_time__c.monthGmt(), mainEvent.Start_time__c.dayGmt());
        
        for(DateTime futureBatchDT : futureBatcheDates){
            
            Date futureBatchDate = Date.newInstance(futureBatchDT.year(), futureBatchDT.month(), futureBatchDT.day());
           	Integer daysDiffBetwMainEvent = mainEventStartDate.daysBetween(futureBatchDate);
            
            Trekking_Event__c eventFutureBatch = mainEvent.clone();
            eventFutureBatch.id = null;
            eventFutureBatch.Start_time__c = mainEvent.Start_time__c.addDays(daysDiffBetwMainEvent);
            eventFutureBatch.End_Time__c = mainEvent.End_Time__c.addDays(daysDiffBetwMainEvent);
            nextBatchEventTimeMap.put(daysDiffBetwMainEvent, eventFutureBatch);
            
        }
        
        Database.insert(nextBatchEventTimeMap.values());
            
        for(Integer daysDiffBetwMainEvent : nextBatchEventTimeMap.keySet()){
            
            for(Destination__c destination : mainEvent.Destinations__r){
                
                Destination__c futureDestination = destination.clone();
                futureDestination.id = null;
                futureDestination.Visiting_Date__c = destination.Visiting_Date__c.addDays(daysDiffBetwMainEvent);
                futureDestination.Trekking_Event__c = nextBatchEventTimeMap.get(daysDiffBetwMainEvent).id;
                futureEventDestinations.add(futureDestination);
                
            }
            
        }
        
        Database.insert(futureEventDestinations);
        
    }

    global class NewEventWrapper {
        @InvocableVariable
        global Integer noOfDestinations;
        @InvocableVariable
        global List<Destination__c> destinations;
        @InvocableVariable
        global List<DateTime> futureBatcheDates;
        @InvocableVariable
        global id currentEventId;
    }
}