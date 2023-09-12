public class SSS_NewEventDelegateTriggerHandler {

    public static void processNewEventCreation(List<Trekking_Event_Delegate__c> teDelegates){

        try{
            
            Map<String, List<Trekking_Event__c>> orgNameToEventMap = new Map<String, List<Trekking_Event__c>>(); 
            List<SSS_NewEventController.NewEventWrapper> newEventWrapperList = new List<SSS_NewEventController.NewEventWrapper>();
            
            for(Trekking_Event_Delegate__c teDelegate : teDelegates){
                
                SSS_NewEventController.NewEventWrapper newEventWrapper = new SSS_NewEventController.NewEventWrapper();
                
                Trekking_Event__c teObj = new Trekking_Event__c();
                teObj.Name = teDelegate.Name;
                teObj.Start_time__c = DateTime.newInstance(
                    teDelegate.Event_Start_Date__c, 
                    convertToTime(teDelegate.Departure_Time_Slot__c));
                teObj.End_Time__c = teDelegate.Event_End_Date__c;
                teObj.Event_Details_Link__c = teDelegate.More_Details_Link__c;
                teObj.Batch_Size__c = teDelegate.Number_of_Seats__c;
                teObj.Cost__c = teDelegate.Event_Cost__c;
                teObj.Departure_From__c = teDelegate.Departure_From__c;
                
                if(orgNameToEventMap.get(teDelegate.Organization_Name__c) != null){
                    orgNameToEventMap.get(teDelegate.Organization_Name__c).add(teObj);
                }else{
                    orgNameToEventMap.put(teDelegate.Organization_Name__c, new List<Trekking_Event__c>{teObj});
                }
                
                newEventWrapper.trekkingEvent = teObj;
                newEventWrapper.destinations = populateDestinations(teDelegate);
                newEventWrapper.noOfDestinations = newEventWrapper.destinations?.size();
                newEventWrapper.futureBatcheDates = populateFutureDates(teDelegate);
                newEventWrapper.validateEventData = false;
                newEventWrapper.trekDelegateId = teDelegate.id;
                
                newEventWrapperList.add(newEventWrapper);
                
            }
            
            if(orgNameToEventMap != null && !orgNameToEventMap.isEmpty()){
                
            	List<Account> organizations = [SELECT id, name FROM Account WHERE name IN: orgNameToEventMap.keySet()];
                for(Account org : organizations){
                    for(Trekking_Event__c teObj : orgNameToEventMap.get(org.name)){
                        teObj.Organization__c = org.Id;	
                    }
                }
                
            }
            
            List<SSS_NewEventController.NewEventWrapper> processedEvents = SSS_NewEventController.createEvents(newEventWrapperList);
            
            List<Trekking_Event_Delegate__c> failureTrekDelegates = new List<Trekking_Event_Delegate__c>();
            List<Id> failedIds = new List<Id>();
            for(SSS_NewEventController.NewEventWrapper event : processedEvents){
                if(String.isNotBlank(event.errorMsg)){
                    if(!failedIds.contains(event.trekDelegateId)){
                        Trekking_Event_Delegate__c teDelegate = new Trekking_Event_Delegate__c();
                        teDelegate.id = event.trekDelegateId;
                        teDelegate.Sync_Failure_Reason__c = event.errorMsg;
                        failureTrekDelegates.add(teDelegate);
                        failedIds.add(event.trekDelegateId);
                    }
                }
            }
            
            if(failureTrekDelegates != null && !failureTrekDelegates.isEmpty()){
                Database.update(failureTrekDelegates, false);
            }
            
        }catch(Exception e){
            
            List<Trekking_Event_Delegate__c> failureTrekDelegates = new List<Trekking_Event_Delegate__c>();
            
            for(Trekking_Event_Delegate__c teDelegate : teDelegates){
                Trekking_Event_Delegate__c teDelegateF = new Trekking_Event_Delegate__c();
                teDelegateF.id = teDelegate.id;
                teDelegateF.Sync_Failure_Reason__c = e.getMessage();
                failureTrekDelegates.add(teDelegateF);
            }
            
            if(failureTrekDelegates != null && !failureTrekDelegates.isEmpty()){
                Database.update(failureTrekDelegates, false);
            }
            
        }
		
    }
    
    public static List<String> destinationNames = new List<String>{
        'Destination_1__c',
        'Destination_2__c',
        'Destination_3__c',
        'Destination_4__c',
        'Destination_5__c'
    };
    public static List<String> destinationDates = new List<String>{
        'Visit_Date_D1__c',
        'Visit_Date_D2__c',
        'Visit_Date_D3__c',
        'Visit_Date_D4__c',
        'Visit_Date_D5__c'
    };
    public static List<String> destinationTimes = new List<String>{
        'Visit_Slot_D1__c',
        'Visit_Slot_D2__c',
        'Visit_Slot_D3__c',
        'Visit_Slot_D4__c',
        'Visit_Slot_D5__c'
    };
    private static List<Destination__c> populateDestinations(Trekking_Event_Delegate__c teDelegate){
        
        List<Destination__c> destinations = new List<Destination__c>();
        List<String> locations = new List<String>();
        for(Integer i=0; i<5; i++){
            
            if(teDelegate.get(destinationNames[i]) != null 
               && teDelegate.get(destinationDates[i]) != null 
               && teDelegate.get(destinationTimes[i]) != null 
               && !locations.contains((String) teDelegate.get(destinationNames[i]))){
                   
                Destination__c dest = new Destination__c();
                dest.Location__c = (String) teDelegate.get(destinationNames[i]);
                dest.Visiting_Date__c = (Date) teDelegate.get(destinationDates[i]);
                dest.Visiting_Time_Slot__c = (String) teDelegate.get(destinationTimes[i]);
                destinations.add(dest);
                locations.add((String) teDelegate.get(destinationNames[i]));
                   
            }else if(i == 0){
                teDelegate.Sync_Failure_Reason__c = 'Atleast one destination should be provided';
            }
            
        }
        
        return destinations;
        
    }
    
    public static List<String> futureDateAPIs = new List<String>{
        'Future_Date_1__c',
        'Future_Date_2__c',
        'Future_Date_3__c',
        'Future_Date_4__c',
        'Future_Date_5__c'
    };
    private static List<Date> populateFutureDates(Trekking_Event_Delegate__c teDelegate){
       
        Set<Date> futureDates = new Set<Date>();
        
        for(String futureDateAPI : futureDateAPIs){
            if(teDelegate.get(futureDateAPI) != null){
                futureDates.add((Date) teDelegate.get(futureDateAPI));
            }
        }
        
        return new List<Date>(futureDates);
        
    }
    
    public static Time convertToTime(String timeString){
        
        Time convertedVal;
        
        convertedVal = Time.newInstance(
            Integer.valueOf(timeString.split(':')[0]), 
            Integer.valueOf(timeString.split(':')[1].split(' ')[0]), 0, 0
        );
        
        System.debug('convertedVal 1' + convertedVal);
        if(timeString.split(':')[1].split(' ')[1] == 'PM'){
            convertedVal = convertedVal.addHours(12);
        	System.debug('convertedVal 2' + convertedVal);
        }
        
        return convertedVal;
        
    }
    
}