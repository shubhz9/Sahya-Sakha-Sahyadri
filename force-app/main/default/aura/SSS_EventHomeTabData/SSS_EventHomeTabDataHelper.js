({
	displayEvents : function(component, event, helper) {
        
		var selectedName = event.getParam('name');
        if(!selectedName){
            selectedName = 'ALL';
        }
        
        var slotData = component.get("v.slotData");
        var trekEvents = [];
        
        slotData.forEach(function(ele){
            if(ele['locationNameKey'] === selectedName){
                trekEvents = ele['trekEvents'];
            }
        });
        
        component.set("v.trekEvents", trekEvents);
        component.set("v.selectedItem", selectedName);
        
	}
})