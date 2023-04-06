public class SSS_Utility {

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
        
        Datetime firstWeekendDate = getFirstWeekendDate(DateTime.newInstance(startDate.year(), startDate.month(), 1));
        
        Integer weekendNumber = 1;
        
        while(weekendNumber < 6 && (firstWeekendDate.addDays(-5) > startDate || firstWeekendDate.addDays(1) < startDate)){
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
    
}