public without sharing class SSS_Utility {

    public static Map<Integer, String> monthMap = new Map<Integer, String>{
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
        
    public static Map<Integer, String> numPrefixMap = new Map<Integer, String>{
        1 => 'st',
        2 => 'nd',
        3 => 'rd',
        4 => 'th',
        5 => 'th'
    };
        
    public static String calculateWeekendNumber(DateTime startDate){
        
        Integer year = startDate.yearGmt();
        Integer month = startDate.monthGmt();
        Datetime firstWeekendDate = getFirstWeekendDate(DateTime.newInstance(year, month, 1));
        
        Integer weekendNumber = 1;
        
        while(weekendNumber < 6 && (firstWeekendDate.addDays(-5) > startDate || firstWeekendDate.addDays(2) < startDate)){
            firstWeekendDate = firstWeekendDate.addDays(7);
            weekendNumber++;
        }
        
        String weekendSlot = '';
        if(weekendNumber == 6){
            weekendSlot = 'Weekday Trek-' + SSS_Utility.monthMap.get(startDate.month());
        }else{
           	weekendSlot = '' + weekendNumber + SSS_Utility.numPrefixMap.get(weekendNumber) + ' Weekend-' + SSS_Utility.monthMap.get(startDate.month());   
        }
        
        return weekendSlot;
         
    }
    
    public static DateTime getFirstWeekendDate(DateTime referenceDate){
        
        DateTime firstWeekendDate;
        String firstWeekendDateString = referenceDate.formatGMT('EEE, MMM d yyyy');
        
        if(String.isNotBlank(firstWeekendDateString) && firstWeekendDateString.contains('Sat')){
            firstWeekendDate = referenceDate;
        }else{
            firstWeekendDate = getFirstWeekendDate(referenceDate.addDays(1));
        }
        
        return firstWeekendDate;
        
    }
    
    public static String prepareEventKey(Trekking_Event__c trekEvent, List<Destination__c> trekDestinations){
        
		String eventKey = '';

        eventKey = trekEvent.Start_time__c.year()+''+trekEvent.Start_time__c.month()+''+trekEvent.Start_time__c.day();
        eventKey = eventKey + '~' + trekEvent.Organization__c;
        
        List<String> destLocations = new List<String>();
        for(Destination__c destination : trekDestinations){
            destLocations.add(destination.Location__c.remove(' ').toUpperCase().left(30));
        }
        
        destLocations.sort();
        for(String destLoc : destLocations){
            eventKey = eventKey + '~' + destLoc;
        }
        
		return eventKey;        
        
    }
    
}