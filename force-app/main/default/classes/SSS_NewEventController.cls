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
    
    public static Integer errorScreenNumber = 1;
    public static String errorMessage = '';
    
    @InvocableMethod(label='Save Destinations' description='Used for saving destinations')
    global static List<NewEventResponseWrapper> saveDestination(List<NewEventWrapper> destinationWrapper) {
        
        List<NewEventResponseWrapper> responseList = new List<NewEventResponseWrapper>();
        
        try{
            if(destinationWrapper != null && !destinationWrapper.isEmpty() && destinationWrapper[0].trekkingEvent != null){
                
                if(destinationWrapper[0].validateEventData){
                    
                    String valErr = validateEvent(destinationWrapper[0].trekkingEvent, destinationWrapper[0].destinations);
                	
                    if(String.isBlank(valErr)){
                        responseList.add(new NewEventResponseWrapper('SUCCESS', null, errorScreenNumber));
                    }else{
                    	responseList.add(new NewEventResponseWrapper('ERROR', valErr, errorScreenNumber));
                    }
                    
                }else{
                    
                    Trekking_Event__c newTrekkingEvent = destinationWrapper[0].trekkingEvent;
                    newTrekkingEvent.Batch_Size__c = newTrekkingEvent.Batch_Size__c == null ? 20 : newTrekkingEvent.Batch_Size__c;
                    newTrekkingEvent.Grade__c = String.isBlank(newTrekkingEvent.Grade__c) ? 'Easy' : newTrekkingEvent.Grade__c;
                    newTrekkingEvent.Event_Key__c = SSS_Utility.prepareEventKey(destinationWrapper[0].trekkingEvent, destinationWrapper[0].destinations);
                    
                    Database.upsert(new List<sObject>{newTrekkingEvent});
                    
                    destinationWrapper[0].currentEventId = newTrekkingEvent.id;
                    
                    if(destinationWrapper[0].noOfDestinations != 0){
                        List<Destination__c> finalList = new List<Destination__c>();
                        for(Destination__c dest: destinationWrapper[0].destinations){
                            dest.Trekking_Event__c = newTrekkingEvent.Id;
                            finalList.add(dest);
                        }
                        Database.upsert(finalList, false);
                    }
                    
                    if(destinationWrapper[0].futureBatcheDates != null && destinationWrapper[0].currentEventId != null){
                        createFutureBatchesForEvent(destinationWrapper[0].currentEventId, destinationWrapper[0].futureBatcheDates, responseList);
                    }
                    
                }
                
            }
            
        }catch(Exception e){
            errorScreenNumber = 1;
			responseList.add(new NewEventResponseWrapper('ERROR', e.getMessage(), errorScreenNumber));    
        }    
        
        if(responseList.isEmpty()){
        	responseList.add(new NewEventResponseWrapper('SUCCESS', null, errorScreenNumber));
            errorScreenNumber = 1;
        }
        return responseList;
        
    }
    
    public static void createFutureBatchesForEvent(Id currentEventId, List<Date> futureBatcheDates, List<NewEventResponseWrapper> responseList){
        
        List<Trekking_Event__c> futureEvents = new List<Trekking_Event__c>();
        List<Destination__c> futureEventDestinations = new List<Destination__c>();
        Map<Integer, Trekking_Event__c> nextBatchEventTimeMap = new Map<Integer, Trekking_Event__c>();
                
        Trekking_Event__c mainEvent = [SELECT id, name, Event_slot__c, createdDate, Organization__r.name, Departure_From__c, 
                                           Start_time__c, End_Time__c, Grade__c, Batch_Size__c, cost__c, Event_Details_Link__c, 
                                           (SELECT id, name, Location__c, Type__c, Visiting_Date__c 
                                            FROM Destinations__r) 
                                      FROM Trekking_Event__c 
                                      WHERE id = :currentEventId
                                      LIMIT 1];
        
        validateFutureBatches(mainEvent, futureBatcheDates);
        
        if(String.isNotBlank(errorMessage)){
            responseList.add(new NewEventResponseWrapper('ERROR', errorMessage, errorScreenNumber));
            return;
        }
        
        Date mainEventStartDate = Date.newInstance(mainEvent.Start_time__c.year(), mainEvent.Start_time__c.month(), mainEvent.Start_time__c.day());
        
        for(Date futureBatchDT : futureBatcheDates){
            
            if(futureBatchDT == null){
                continue;
            }
            
           	Integer daysDiffBetwMainEvent = mainEventStartDate.daysBetween(futureBatchDT);
            
            Trekking_Event__c eventFutureBatch = mainEvent.clone();
            eventFutureBatch.id = null;
            eventFutureBatch.Start_time__c = mainEvent.Start_time__c.addDays(daysDiffBetwMainEvent);
            eventFutureBatch.End_Time__c = mainEvent.End_Time__c.addDays(daysDiffBetwMainEvent);
            eventFutureBatch.Event_Key__c = SSS_Utility.prepareEventKey(eventFutureBatch, mainEvent.Destinations__r);
            nextBatchEventTimeMap.put(daysDiffBetwMainEvent, eventFutureBatch);
            
        }
        
        Database.upsert(nextBatchEventTimeMap.values());
            
        for(Integer daysDiffBetwMainEvent : nextBatchEventTimeMap.keySet()){
            
            for(Destination__c destination : mainEvent.Destinations__r){
                
                Destination__c futureDestination = destination.clone();
                futureDestination.id = null;
                futureDestination.Visiting_Date__c = destination.Visiting_Date__c.addDays(daysDiffBetwMainEvent);
                futureDestination.Trekking_Event__c = nextBatchEventTimeMap.get(daysDiffBetwMainEvent).id;
                futureEventDestinations.add(futureDestination);
                
            }
            
        }
        
        Database.upsert(futureEventDestinations);
        
    }
    
    private static void validateFutureBatches(Trekking_Event__c trekkingEvent, List<Date> futureBatches){
        
        List<Date> futureBatchDates = new List<Date>();
        for(Date futureBatch : futureBatches){
            if(futureBatch == null){
                continue;
            }
            if(trekkingEvent.Start_Time__c > futureBatch || futureBatchDates.contains(futureBatch)){
                errorMessage = 'Invalid dates for Future batches. Dates entered must be greater than main event start date or must not be duplicate.';
				errorScreenNumber = 3;
            }else{
                futureBatchDates.add(futureBatch);
            }
        }
        
    }

    public static String validateEvent(Trekking_Event__c trekkingEvent, List<Destination__c> destinations){
        
        String validationError = '';
        
        if(trekkingEvent.Start_time__c == null || trekkingEvent.End_Time__c == null || trekkingEvent.End_Time__c <= trekkingEvent.Start_time__c){
            validationError = 'Please select valid start and end dates. Dates cannot be blank and end date must be greater than start date.';
        	errorScreenNumber = 1;
        }
        
        String eventKey = SSS_Utility.prepareEventKey(trekkingEvent, destinations);
        List<Trekking_Event__c> existingEvents = [SELECT id, name FROM Trekking_Event__c
                                                  WHERE Event_Key__c = :eventKey
                                                  	AND Organization__c = :trekkingEvent.Organization__c];
        
        if(existingEvents != null && existingEvents.size() > 0){
            validationError = 'Event \'' + trekkingEvent.name + '\' already exists for the organization for selected dates!';
        	errorScreenNumber = 1;
        }
        
        List<String> destLocations = new List<String>(); 
        for(Destination__c destination : destinations){
            
            if(destLocations.contains(destination.Location__c.trim().toUpperCase())){
                validationError = 'Duplicate destination selected - ' + destination.Location__c;
                errorScreenNumber = 2;
                break;
            }else{
                destLocations.add(destination.Location__c.trim().toUpperCase());
            }
            
            if(destination.Visiting_Date__c < trekkingEvent.Start_time__c || destination.Visiting_Date__c > trekkingEvent.End_Time__c){
                validationError = 'Location visit date should be between event start and end date - ' + destination.Location__c;
            	errorScreenNumber = 2;
            }
            
        }
        
        return validationError;
        
    }
    
    global class NewEventWrapper {
        @InvocableVariable
        global Integer noOfDestinations;
        @InvocableVariable
        global Trekking_Event__c trekkingEvent;
        @InvocableVariable
        global List<Destination__c> destinations;
        @InvocableVariable
        global List<Date> futureBatcheDates;
        @InvocableVariable
        global id currentEventId;
        @InvocableVariable
        global Boolean validateEventData;
    }
    
    global class NewEventResponseWrapper {
        @InvocableVariable
        global String status; //SUCCESS, ERROR
        @InvocableVariable
        global String errorMsg;
        @InvocableVariable
        global Integer errorScreenNumber;
        
        public NewEventResponseWrapper(String s, String e, Integer sn){
            status = s;
            errorMsg = e;
            errorScreenNumber = sn;
        }
        
        
    }
    
}