global without sharing class SSS_EventHomeController {
    
    private static Map<Integer, String> monthMap = new Map<Integer, String>{
    	1 => 'Jan',  
        2 => 'Feb',  
        3 => 'Mar',  
        4 => 'Apr',  
        5 => 'May',  
        6 => 'June',  
        7 => 'July',  
        8 => 'Aug',  
        9 => 'Sept',  
        10 => 'Oct',  
        11 => 'Nov',  
        12 => 'Dec'    
    };
    
    @AuraEnabled
    public static EventHomeDTO fetchEventDetailsAura(){
        
        EventHomeDTO eventDetails = new EventHomeDTO();
        
        List<Trekking_Event__c> trekkingEvents = [SELECT id, name, Organization__r.name, Event_slot__c, 
                                                  Start_time__c, End_Time__c, Grade__c, Batch_Size__c, 
                                                  	(SELECT id, Location__c, Type__c, Visiting_Date__c 
                                                     FROM Destinations__r) 
                                                  FROM Trekking_Event__c 
                                                  WHERE End_Time__c >= TODAY 
                                                  ORDER BY Start_time__c];
        
        eventDetails.slotDataMap = prepareWeekendWiseTrekEvents(trekkingEvents, eventDetails);
        
        return eventDetails;
        
    }
    
    private static Map<String, List<TrekEventsDTO>> prepareWeekendWiseTrekEvents(List<Trekking_Event__c> trekkingEvents, EventHomeDTO eventDetails){

        Map<String, List<TrekEventsDTO>> weekendWiseTrekEvents = new Map<String, List<TrekEventsDTO>>();
        Set<String> slotKeysSet = new Set<String>();
        Map<String, String> slotNameMap = new Map<String, String>();
        
        for(Trekking_Event__c trekEvent : trekkingEvents){
            
            TrekEventsDTO trekEventDetails = new TrekEventsDTO();
            trekEventDetails.eventName = trekEvent.name;
            trekEventDetails.organizationName = trekEvent.Organization__r.Name;
            trekEventDetails.eventDate = getEventDate(trekEvent.Start_time__c, trekEvent.End_Time__c);
            trekEventDetails.batchSize = (Integer) trekEvent.Batch_Size__c;
            trekEventDetails.destinations = getEventDestinations(trekEvent.Destinations__r);
            
            String weekendSlot = trekEvent.Event_slot__c.split('-')[0] + '\n' + trekEvent.Event_slot__c.split('-')[1] + ' ' + trekEvent.End_Time__c.year();
            String slotKey = weekendSlot.remove('-').trim();
            slotKey = 'SL'+slotKey.trim().remove(' ');
            slotKeysSet.add(slotKey);
            slotNameMap.put(slotKey, weekendSlot);
            
            if(weekendWiseTrekEvents.get(slotKey) != null){
                weekendWiseTrekEvents.get(slotKey).add(trekEventDetails);
            }else{
                weekendWiseTrekEvents.put(slotKey, new List<TrekEventsDTO>{trekEventDetails});
            }
            
        }
        
        List<String> slotKeys = new List<String>();
		slotKeys.addAll(slotKeysSet);
        eventDetails.slotKeys = slotKeys;
        eventDetails.slotNameMap = slotNameMap;
        
        return weekendWiseTrekEvents;
    
    }
    
    private static List<DestinationDTO> getEventDestinations(List<Destination__c> destinationRecs){
        
        List<DestinationDTO> destinations = new List<DestinationDTO>();
        for(Destination__c destinationRec : destinationRecs){
            
            DestinationDTO destination = new DestinationDTO();
            destination.name = destinationRec.Location__c;
            destination.visitDate = destinationRec.Visiting_Date__c.format('EEE, MMM d yyyy');
            destination.destinationType = destinationRec.Type__c;
            
            destinations.add(destination);
            
        }
        
        return destinations;
        
    }
    
    private static String getEventDate(DateTime startTime, DateTime endTime){
        
        String eventDate, startDay, startMonth, startYear, endDay, endMonth, endYear;
        
        endDay = '' + endTime.day();
        endMonth = '' + endTime.month();
        endYear = String.valueOf(endTime.year());
        
        if(String.isNotBlank(endDay) && String.valueOf(startTime.day()) == endDay){
            startDay = '';
        }else{
            startDay = String.valueOf(startTime.day());
            endDay = ' - ' + endDay;
        }
        
        if(String.isNotBlank(endMonth) && String.valueOf(startTime.month()) == endMonth){
            startMonth = '';
            endMonth = ' ' + monthMap.get(endTime.month());
        }else{
            startMonth = ' ' + monthMap.get(startTime.month());
            endMonth = ' ' + monthMap.get(endTime.month());
        }
        
        if(String.isNotBlank(endYear) && String.valueOf(startTime.year()) == endYear){
            startYear = '';
            endYear = ', ' + endYear;
        }else{
            startYear = ', ' + startTime.year();
            endYear = ', ' + endYear;
        }        
                
        eventDate = startDay + startMonth + startYear + endDay + endMonth + endYear; 
        
        return eventDate;
    }

    public class EventHomeDTO{
        
        @AuraEnabled
        public List<String> slotKeys;
        @AuraEnabled
        public Map<String, String> slotNameMap; 
        @AuraEnabled
        public Map<String, List<TrekEventsDTO>> slotDataMap; 
        
    }
    
    public class TrekEventsDTO{
        
        @AuraEnabled
        public String eventName;
        
        @AuraEnabled
        public String organizationName;
        
        @AuraEnabled
        public String eventDate;
        
        @AuraEnabled
        public Integer batchSize;
        
        @AuraEnabled
        public List<DestinationDTO> destinations;
        
    }
    
    public class DestinationDTO{
        
        @AuraEnabled
        public String name;
        
        @AuraEnabled
        public String visitDate;
        
        @AuraEnabled
        public String destinationType;
        
    }
    
}