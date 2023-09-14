/**
 * @description       : 
 * @author            : Shubham Raut
 * @group             : 
 * @last modified on  : 09-13-2023
 * @last modified by  : Shubham Raut
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   09-13-2023   Shubham Raut   Initial Version
**/
global with sharing class SSS_ArchiveTrekkingEventScheduler implements Schedulable{
    global void execute(SchedulableContext SC) {
        BatchJob_DeleteOldTrekkingEvents ba = new BatchJob_DeleteOldTrekkingEvents();
        Database.executeBatch(ba, 1000);
    }
}