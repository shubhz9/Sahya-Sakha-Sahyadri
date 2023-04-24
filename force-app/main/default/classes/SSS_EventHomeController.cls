global without sharing class SSS_EventHomeController {
    
    @AuraEnabled
    public static EventHomeDTO fetchEventDetailsAura(){
        
        EventHomeDTO eventDetails = new EventHomeDTO();
        
        List<Trekking_Event__c> trekkingEvents = [SELECT id, name, Organization__r.Group_Name__c, Organization__r.Instagram__c , Event_slot__c, Departure_From__c, 
                                                  Start_time__c, End_Time__c, Grade__c, Batch_Size__c, Cost__c, Event_Details_Link__c, 
                                                  	(SELECT id, Location__c, Type__c, Visiting_Date__c 
                                                     FROM Destinations__r
                                                     ORDER BY Visiting_Date__c ) 
                                                  FROM Trekking_Event__c 
                                                  WHERE End_Time__c >= TODAY 
                                                  ORDER BY Start_time__c];
        
        eventDetails.slotDataMap = prepareWeekendWiseTrekEvents(trekkingEvents, eventDetails);
        
        return eventDetails;
        
    }
    
    private static Map<String, List<LocationWiseTrekEventsDTO>> prepareWeekendWiseTrekEvents(List<Trekking_Event__c> trekkingEvents, EventHomeDTO eventDetails){

        Map<String, List<TrekEventsDTO>> weekendWiseTrekEvents = new Map<String, List<TrekEventsDTO>>();
        Map<String, List<LocationWiseTrekEventsDTO>> weekendAndLocWiseTrekEvents = new Map<String, List<LocationWiseTrekEventsDTO>>();
        
        Set<String> slotKeysSet = new Set<String>();
        Map<String, String> slotNameMap = new Map<String, String>();
        
        for(Trekking_Event__c trekEvent : trekkingEvents){
            
            TrekEventsDTO trekEventDetails = new TrekEventsDTO();
            trekEventDetails.eventName = trekEvent.name;
            trekEventDetails.organizationName = trekEvent.Organization__r.Group_Name__c;
            trekEventDetails.organizationSocialProfile = 'https://www.instagram.com/' + trekEvent.Organization__r.Instagram__c;
            trekEventDetails.eventDate = getEventDate(trekEvent.Start_time__c, trekEvent.End_Time__c);
            trekEventDetails.batchSize = (Integer) trekEvent.Batch_Size__c;
            trekEventDetails.eventCost = (Integer) trekEvent.Cost__c;
            trekEventDetails.departureFrom = trekEvent.Departure_From__c;
            trekEventDetails.eventDetailsLink = trekEvent.Event_Details_Link__c;
            trekEventDetails.destinations = getEventDestinations(trekEvent.Destinations__r);
            
            String weekendSlot = trekEvent.Event_slot__c.split('-')[0] + '\n' + trekEvent.Event_slot__c.split('-')[1] + ' ' + trekEvent.End_Time__c.year();
            String slotKey = weekendSlot.remove('-').trim();
            slotKey = 'SL'+slotKey.trim().remove(' ');
            slotKeysSet.add(slotKey);
            slotNameMap.put(slotKey, weekendSlot);
            
            List<LocationWiseTrekEventsDTO> locWiseTrekEvents;
            if(weekendAndLocWiseTrekEvents.get(slotKey) != null){
                locWiseTrekEvents = weekendAndLocWiseTrekEvents.get(slotKey);
            }else{
                locWiseTrekEvents = new List<LocationWiseTrekEventsDTO>();
                weekendAndLocWiseTrekEvents.put(slotKey, locWiseTrekEvents);
            }
            
            prepareLocationWiseData(locWiseTrekEvents, trekEventDetails);
            
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
        
        return weekendAndLocWiseTrekEvents;
    
    }
    
    private static List<LocationWiseTrekEventsDTO> prepareLocationWiseData(List<LocationWiseTrekEventsDTO> locWiseTrekEvents, TrekEventsDTO trekEventDetails){
        
        Set<String> locationNameKeys = new Set<String>();
        LocationWiseTrekEventsDTO matchingLocationEvent;
        
        for(DestinationDTO destination : trekEventDetails.destinations){
            
            locationNameKeys.add(destination.name);
            
            if(matchingLocationEvent != null){
                continue;
            }
            
            for(LocationWiseTrekEventsDTO locWiseTrekRec : locWiseTrekEvents){
                if(locWiseTrekRec.locationNames != null
                   && locWiseTrekRec.locationNames.contains(destination.name)){

					matchingLocationEvent = locWiseTrekRec;
                    locationNameKeys.addAll(locWiseTrekRec.locationNames);
                    break;
               
            	}
            }
        }
        
        if(matchingLocationEvent == null){
            matchingLocationEvent = new LocationWiseTrekEventsDTO();
            matchingLocationEvent.trekEvents = new List<TrekEventsDTO>{trekEventDetails};
            locWiseTrekEvents.add(matchingLocationEvent);
        }else{
            matchingLocationEvent.trekEvents.add(trekEventDetails);        
        }
        
        matchingLocationEvent.locationNames = new List<String>(locationNameKeys);
        
        return locWiseTrekEvents;
        
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
            endMonth = ' ' + SSS_Utility.monthMap.get(endTime.month());
        }else{
            startMonth = ' ' + SSS_Utility.monthMap.get(startTime.month());
            endMonth = ' ' + SSS_Utility.monthMap.get(endTime.month());
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
        public Map<String, List<LocationWiseTrekEventsDTO>> slotDataMap; 
        
    }
    
    public class LocationWiseTrekEventsDTO{
        @AuraEnabled
        public List<String> locationNames;
        @AuraEnabled
        public List<TrekEventsDTO> trekEvents;
    }
    
    public class TrekEventsDTO{
        
        @AuraEnabled
        public String eventName;
        
        @AuraEnabled
        public String organizationName;
        
        @AuraEnabled
        public String organizationSocialProfile;
        
        @AuraEnabled
        public String eventDate;
        
        @AuraEnabled
        public Integer eventCost;
        
        @AuraEnabled
        public Integer batchSize;
        
        @AuraEnabled
        public String departureFrom;
        
        @AuraEnabled
        public String eventDetailsLink;
        
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