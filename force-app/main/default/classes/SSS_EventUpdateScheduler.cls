global class SSS_EventUpdateScheduler implements Schedulable  {

    global void execute(SchedulableContext SC) {
       	SSS_EventAnalyticsController inst = new SSS_EventAnalyticsController();
		inst.sendEmail();
   }
    
}