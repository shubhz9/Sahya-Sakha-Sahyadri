({
	launchAddEventFlow : function(component, event, helper) {
        component.set("v.isModalOpen", true);
		var flow = component.find("flowData");
    	flow.startFlow("Create_Trekking_Event");
	},
    closeModel : function(component, event, helper) {
		component.set("v.isModalOpen", false);
	},
    submitDetails : function(component, event, helper) {
		var flow = component.find("flowData");
    	flow.startFlow("New_Event");
	},
    fetchEventDetails : function(component, event, helper) {
        
        var url = $A.get('$Resource.SSS_Logo');
        component.set('v.backgroundImageURL', url);
        
		var action = component.get("c.fetchEventDetailsAura");
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state: ',state);
            if (state === "SUCCESS") {
                
                var resWrapper = response.getReturnValue();
                component.set("v.slotKeys", resWrapper.slotKeys);
                component.set("v.slotNameMap", resWrapper.slotNameMap);
                component.set("v.slotDataMap", resWrapper.slotDataMap);
            	component.set("v.isLoading", false);
                
                helper.loadTabData(component, event, helper);

            }
        });
        $A.enqueueAction(action);
	},
    getSlotName : function(component, event, helper) {
		var slotKey = '';
        return slotKey;
	},
    handleTabClickEvent : function(component, event, helper) {
        
        helper.loadTabData(component, event, helper);
        
	}
})