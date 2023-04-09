trigger SSS_TrekkingEventTrigger on Trekking_Event__c (before insert) {

    if(Trigger.isBefore){
        SSS_TrekkingEventTriggerHandler.runBeforeTrigger();
    }
    
}