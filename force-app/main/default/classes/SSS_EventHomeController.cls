public class SSS_EventHomeController {
    
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
    public static EventHomeDTO fetchEventDetails(){
        
        EventHomeDTO eventDetails = new EventHomeDTO();
        
        List<Trekking_Event__c> trekkingEvents = [SELECT id, name, Organization__r.name, Event_slot__c, 
                                                  Start_time__c, End_Time__c, Grade__c, Batch_Size__c, 
                                                  	(SELECT id, Location__c, Type__c, Visiting_Date__c 
                                                     FROM Destinations__r) 
                                                  FROM Trekking_Event__c];
        
        eventDetails.weekendWiseTrekEvents = prepareWeekendWiseTrekEvents(trekkingEvents);
        
        return eventDetails;
        
    }
    
    private static Map<String, List<TrekEventsDTO>> prepareWeekendWiseTrekEvents(List<Trekking_Event__c> trekkingEvents){

        Map<String, List<TrekEventsDTO>> weekendWiseTrekEvents = new Map<String, List<TrekEventsDTO>>();
        
        for(Trekking_Event__c trekEvent : trekkingEvents){
            
            TrekEventsDTO trekEventDetails = new TrekEventsDTO();
            trekEventDetails.eventName = trekEvent.name;
            trekEventDetails.organizationName = trekEvent.Organization__r.Name;
            trekEventDetails.eventDate = getEventDate(trekEvent.Start_time__c, trekEvent.End_Time__c);
            trekEventDetails.batchSize = (Integer) trekEvent.Batch_Size__c;
            trekEventDetails.destinations = getEventDestinations(trekEvent.Destinations__r);
            
            String weekendSlot = trekEvent.Event_slot__c + ' ' + trekEvent.End_Time__c.year();
            if(weekendWiseTrekEvents.get(weekendSlot) != null){
                weekendWiseTrekEvents.get(weekendSlot).add(trekEventDetails);
            }else{
                weekendWiseTrekEvents.put(weekendSlot, new List<TrekEventsDTO>{trekEventDetails});
            }
            
        }
        
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
        
        String eventDate = '';
        eventDate = startTime.day() + ' - ' + endTime.day() + ' ' + monthMap.get(startTime.month()) + ', ' + endTime.year();
        
        return eventDate;
    }

    public class EventHomeDTO{
        
        @AuraEnabled
        public Map<String, List<TrekEventsDTO>> weekendWiseTrekEvents; 
        
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