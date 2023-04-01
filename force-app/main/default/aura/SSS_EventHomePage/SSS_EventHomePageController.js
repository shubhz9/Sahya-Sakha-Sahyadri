({
	launchAddEventFlow : function(component, event, helper) {
        component.set("v.isModalOpen", true);
		var flow = component.find("flowData");
    	flow.startFlow("New_Event");
	},
    closeModel : function(component, event, helper) {
		component.set("v.isModalOpen", false);
	},
    submitDetails : function(component, event, helper) {
		var flow = component.find("flowData");
    	flow.startFlow("New_Event");
	},
    fetchEventDetails : function(component, event, helper) {
		var action = component.get("c.fetchEventDetailsAura");
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state: ',state);
            if (state === "SUCCESS") {
                component.set("v.eventsData", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	}
})