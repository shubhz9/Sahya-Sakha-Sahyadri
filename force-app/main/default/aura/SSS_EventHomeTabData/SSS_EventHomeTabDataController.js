({
	doInit : function(component, event, helper) {
		
        var slotKey = component.get("v.slotKey");
        var slotDataMap = component.get("v.slotDataMap");
        var slotData = slotDataMap[slotKey];
        var allEvents = [];
        var totalEvents = 0;
        
        slotData.forEach(function(ele){
            
            let locationNames = ele['locationNames'];
            let locationNameKey = locationNames.join(' | ');
            ele['locationNameKey'] = locationNameKey;
            ele['locationEventCount'] = ele['trekEvents'].length;
            allEvents.push.apply(allEvents, ele['trekEvents']);
            
        });
        
        slotData.unshift({
            'locationNames' : 'ALL', 
            'locationNameKey' : 'ALL',
            'locationEventCount' : allEvents.length,
            'trekEvents' : allEvents
        });
        component.set("v.selectedItem", 'ALL');
        
        component.set("v.slotData", slotData);
        
        helper.displayEvents(component, event, helper);
        
	},
    handleSelect : function(component, event, helper){
        
        helper.displayEvents(component, event, helper);
        
    }
})