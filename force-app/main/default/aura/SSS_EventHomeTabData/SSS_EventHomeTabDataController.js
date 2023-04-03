({
	doInit : function(component, event, helper) {
		
        var slotKey = component.get("v.slotKey");
        var slotDataMap = component.get("v.slotDataMap");
        var slotData = slotDataMap[slotKey];
        
        component.set("v.slotData", slotData);
        
	}
})