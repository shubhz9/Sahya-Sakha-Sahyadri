({
	doInit : function(component, event, helper) {
		
        var slotKey = component.get("v.slotKey");
        var slotNameMap = component.get("v.slotNameMap");
        var slotName = slotNameMap[slotKey];
        
        component.set("v.slotName", slotName);
        
	},
    showSlotData : function(component, event, helper) {
		
        var slotKey = component.get("v.slotKey");
        
        var cmpEvent = component.getEvent("TabClickEvent"); 
        cmpEvent.setParams({"tabKey" : slotKey}); 
        cmpEvent.fire();
        
	}
})