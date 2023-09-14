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
public with sharing class BatchJob_DeleteOldTrekkingEvents implements Database.Batchable<sObject>{
    String query = 'SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastViewedDate, LastReferencedDate, Cost__c, Event_slot__c, Grade__c, Organization__c, Start_time__c, End_Time__c, Batch_Size__c, Event_Key__c, Departure_From__c, Event_Details_Link__c, Active__c FROM Trekking_Event__c WHERE End_Time__c < TODAY';
    public BatchJob_DeleteOldTrekkingEvents(String query) {
        this.query = query;
    }

    public BatchJob_DeleteOldTrekkingEvents() {
        
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope){
        String generatedCSVFile ='Id, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastViewedDate, LastReferencedDate, Cost__c, Event_slot__c, Grade__c, Organization__c, Start_time__c, End_Time__c, Batch_Size__c, Event_Key__c, Departure_From__c, Event_Details_Link__c, Active__c \n';
        String fileRow = '';
        for(Trekking_Event__c singleEvent: (List<Trekking_Event__c>) scope){
            fileRow = '';
            fileRow = fileRow +','+ singleEvent.Id;
            fileRow = fileRow +','+ singleEvent.Name;
            fileRow = fileRow +','+ singleEvent.CreatedDate;
            fileRow = fileRow +','+ singleEvent.CreatedById;
            fileRow = fileRow +','+ singleEvent.LastModifiedDate;
            fileRow = fileRow +','+ singleEvent.LastModifiedById;
            fileRow = fileRow +','+ singleEvent.SystemModstamp;
            fileRow = fileRow +','+ singleEvent.LastViewedDate;
            fileRow = fileRow +','+ singleEvent.LastReferencedDate;
            fileRow = fileRow +','+ singleEvent.Cost__c;
            fileRow = fileRow +','+ singleEvent.Event_slot__c;
            fileRow = fileRow +','+ singleEvent.Grade__c;
            fileRow = fileRow +','+ singleEvent.Organization__c;
            fileRow = fileRow +','+ singleEvent.Start_time__c;
            fileRow = fileRow +','+ singleEvent.End_Time__c;
            fileRow = fileRow +','+ singleEvent.Batch_Size__c;
            fileRow = fileRow +','+ singleEvent.Event_Key__c;
            fileRow = fileRow +','+ singleEvent.Departure_From__c.replaceAll(',',' ');
            fileRow = fileRow +','+ singleEvent.Event_Details_Link__c;
            fileRow = fileRow +','+ singleEvent.Active__c;
            fileRow = fileRow.replaceFirst(',','');
            generatedCSVFile = generatedCSVFile + fileRow + '\n';
        }

        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        Blob csvBlob = blob.valueOf(generatedCSVFile);
        String csvName = 'Trekking Event Data Till ' + String.valueOf(System.TODAY()) + '.csv';
        csvAttachment.setFileName(csvName);
        csvAttachment.setBody(csvBlob);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{'durg.bhatakanti.official@gmail.com', 'sahya-sakha-sahyadri@googlegroups.com'};
        String subject = 'Archive Data from Trekking Events till Date - ' + String.valueOf(System.TODAY());
        email.setSubject(subject);
        email.setToAddresses(toAddresses);
        email.setPlainTextBody('Data Dump');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
        Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
    }

    public void finish(Database.BatchableContext bc){}

}