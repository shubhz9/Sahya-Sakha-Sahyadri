/**
 * @description       : 
 * @author            : Shubham Raut
 * @group             : 
 * @last modified on  : 04-04-2023
 * @last modified by  : Shubham Raut
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   04-04-2023   Shubham Raut   Initial Version
**/

global with sharing class SSS_NewEventController {  
    @InvocableMethod(label='Save Destinations' description='Used for saving destinations')
    global static void saveDestination(List<NewEventWrapper> destinationWrapper) {
        if(destinationWrapper != null && !destinationWrapper.isEmpty()){
            if(destinationWrapper[0].noOfDestinations != destinationWrapper[0].destinations.size()){
                List<Destination__c> finalList = new List<Destination__c>();
                for(Destination__c dest: destinationWrapper[0].destinations){
                    finalList.add(dest);
                }
                Database.insert(finalList, false);
            }else{
                List<Database.SaveResult> saveResults = Database.insert(destinationWrapper[0].destinations, false);
            }
        }        
    }

    global class NewEventWrapper {
        @InvocableVariable
        global Integer noOfDestinations;
        @InvocableVariable
        global List<Destination__c> destinations;
    }
}