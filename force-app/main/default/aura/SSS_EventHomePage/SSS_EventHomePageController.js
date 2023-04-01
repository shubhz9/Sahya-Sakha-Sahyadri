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
	}
})