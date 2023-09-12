public class SSS_EventAnalyticsController {

    public List<Trekking_Event__c> trekEvents{get;set;}
    public List<EventUpdateWrapper> eventUpdateWrapper{get;set;}
    public SSS_EventHomeController.EventHomeDTO allEventData{get;set;}
    private String OVER_CROWDED_COLOR = '#ff7b7b';
    private String CROWDED_COLOR = '#f9bd4f';
    private String NORMAL_COLOR = '#ecffdd';
    
    public SSS_EventAnalyticsController(){
        
        allEventData = SSS_EventHomeController.fetchEventDetailsAura();
        
        eventUpdateWrapper = new List<EventUpdateWrapper>();
        for(String slotKey : allEventData.slotDataMap.keySet()){
            
            EventUpdateWrapper eventUpdate = new EventUpdateWrapper();
            eventUpdate.weekendName = allEventData.slotNameMap.get(slotKey);
            
            List<EventDestData> eventDests = new List<EventDestData>();
            for(SSS_EventHomeController.LocationWiseTrekEventsDTO locWiseData : allEventData.slotDataMap.get(slotKey)){
                
                EventDestData eventDest = new EventDestData();
                eventDest.destinationName = String.join(locWiseData.locationNames, ' | ');
                eventDest.eventsCount = locWiseData.trekEvents?.size();

                String orgNames = '';
                for(SSS_EventHomeController.TrekEventsDTO events : locWiseData.trekEvents){
                    orgNames = orgNames + '\"' + events.organizationName + '\"' + ', ';
                }
                eventDest.organizationName = orgNames.removeEnd(', ');
                eventDests.add(eventDest);
                
            }
            eventUpdate.destData = eventDests;
            
            eventUpdateWrapper.add(eventUpdate);
            
        }
        
    }
    
    public void sendEmail(){
        
        List<EmailTemplate> template = [select id, HtmlValue from EmailTemplate where developerName = 'Daily_Event_Updates'];

        OrgWideEmailAddress owea = new OrgWideEmailAddress();
        owea = [SELECT Id, Address, DisplayName FROM 
                OrgWideEmailAddress WHERE DisplayName='Sahya Sakha Sahyadri'];
        
		String htmlBody = template[0].HtmlValue;
        
        DateTime myDateTime = DateTime.newInstance(System.today(), Time.newInstance(3, 3, 3, 0));
		String formatted = myDateTime.format('EEE, MMM d yyyy');
        
        htmlBody = htmlBody.replace('{{0}}', formatted);
        htmlBody = htmlBody.replace('{{1}}', prepareEventUpdatesSummary());
        htmlBody = htmlBody.replace('{{2}}', prepareOverCrowdingAnalysis());
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setUseSignature(false); 
        message.setBccSender(false); 
        message.setSaveAsActivity(false); 
        message.setHtmlBody(htmlBody);
        message.setSubject('Events in Sahyadri - Daily updates');
        message.setOrgWideEmailAddressId(owea.id);
        
        message.toAddresses = new String[] { 'mangeshp214@gmail.com'};
            
        PageReference pageRef = null;
        String pageUrl = '/apex/SSS_DailyUpdates';
        pageRef = new PageReference(pageUrl);
        Blob b = pageRef.getContentAsPDF();
        
        Messaging.EmailFileAttachment efa1 = new Messaging.EmailFileAttachment();
        efa1.setFileName(System.today() +'DailyUpdateReport.pdf');
        efa1.setBody(b);
        efa1.setContentType('application/pdf');
            
        message.setFileAttachments(new Messaging.EmailFileAttachment[] {efa1});
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
    }
    
    public String prepareEventUpdatesSummary(){
        
        String eventUpdateSummary = 'No events added or cancelled.';
        
        List<Trekking_Event__c> todaysEventList = [select id, name, (select id, name, Location__c from destinations__r) from Trekking_Event__c where createdDate = today];
        
        Map<String, Integer> destToNewEventCountMap = new Map<String, Integer>();
        String mostPlanned = '';
        Integer grtCount = 0;
        Integer totalCount = 0;
        if(todaysEventList != null){
            
            totalCount = todaysEventList.size();
            for(Trekking_Event__c event : todaysEventList){
                
                if(event.destinations__r == null){
                    continue;
                }
                for(Destination__c dest : event.destinations__r){
                    Integer count = destToNewEventCountMap.get(dest.Location__c.toLowerCase());
                    if(count != null){
                        destToNewEventCountMap.put(dest.Location__c.toLowerCase(), ++count);
                    }else{
                        destToNewEventCountMap.put(dest.Location__c.toLowerCase(), 1);
                    }
                    if(count > grtCount){
                        grtCount = count;
                        mostPlanned = dest.Location__c;
                    }
                }
                
            }
            
        }
        
        if(totalCount != null && totalCount > 0){
            eventUpdateSummary = '<p><b>' + totalCount + ' New events</b> created today</p>';
        }
        
        if(grtCount > 3){
            eventUpdateSummary = eventUpdateSummary + '<p><b>Most new events for :</b> \"' + mostPlanned + '\" <b>+'+ grtCount +'</b></p>';
        }else{
            mostPlanned = '';
        }
        
        String otherDest = '';
        for(String dest : destToNewEventCountMap.keySet()){
            if(!dest.equalsIgnoreCase(mostPlanned)){
                otherDest = otherDest + '\"' + dest + ' <b>+' + destToNewEventCountMap.get(dest) + '</b>\", ';
            }
        }
        
        if(String.isNotBlank(otherDest)){
        	eventUpdateSummary = eventUpdateSummary + '<p><b>All destinations updated today :</b> ' + otherDest.removeEnd(',') + '</p>';
        }
        
        return eventUpdateSummary;
        
    }
    
    public String prepareOverCrowdingAnalysis(){
        
        String overCrowdingAnalysis = '';
        
        Integer count = 0;
        for(EventUpdateWrapper evUpdate : eventUpdateWrapper){
            
            if(count >= 10){
                break;
            }
            String destPills = '';
            
            for(EventDestData eventDest : evUpdate.destData){
                String destColor = NORMAL_COLOR;
                if(eventDest.eventsCount > 3){
                    destColor = CROWDED_COLOR;
                }else if(eventDest.eventsCount > 6){
                    destColor = OVER_CROWDED_COLOR;
                }
                destPills = destPills + addDestinationPill(eventDest.destinationName, destColor, eventDest.eventsCount);
            }
            
            overCrowdingAnalysis = overCrowdingAnalysis + addWeekendTemplate(evUpdate.weekendName, destPills);
            
            count ++;
            
        }
        
        return overCrowdingAnalysis;
        
    }
    
    private String addDestinationPill(String destName, String destColor, Integer eventCount){
        
        String destinationPillTemplate = 
            '<div style="border: 1px solid;border-radius: 8px;padding: 1%;margin: 1%;display: inline-flex;align-items: center;background-color: ' + destColor + ';">' + 
                destName + '-' +  
            '    <div style="border: 1px solid;border-radius: 50px;padding: 2px;margin-left: 5px;background-color: #dafdd1;">' + 
                    eventCount + 
            '    </div>'+ 
            '</div>';
        
        return destinationPillTemplate;
        
    }
    
    private String addWeekendTemplate(String weekendName, String destinationPills){
        
        String weekendTemplate = 
            '<b>' + weekendName + '</b>' + 
            '<div style="width: 100%;">' +
                destinationPills + 
            '</div>' +
            '<br><br>';
        
        return weekendTemplate;
        
    }
    
    public class EventUpdateWrapper{
        
        public String weekendName{get;set;}
        public List<EventDestData> destData{get;set;}
        
    }
    
    public class EventDestData{
        
        public String destinationName{get;set;}
        public Integer eventsCount{get;set;}
        public String organizationName{get;set;} 
        
    }
    
}