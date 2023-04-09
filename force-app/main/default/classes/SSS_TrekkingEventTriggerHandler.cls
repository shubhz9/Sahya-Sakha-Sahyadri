public without sharing class SSS_TrekkingEventTriggerHandler {

    public static void runBeforeTrigger(){
        
        if(Trigger.isInsert){
            updateEventSlot(Trigger.new);
        }
        
    }
    
    public static void updateEventSlot(List<Trekking_Event__c> trekkingEvents){
        
        for(Trekking_Event__c event : trekkingEvents){
            
            event.Event_slot__c = SSS_Utility.calculateWeekendNumber(event.Start_time__c);
            
        }
        
    }
    
}