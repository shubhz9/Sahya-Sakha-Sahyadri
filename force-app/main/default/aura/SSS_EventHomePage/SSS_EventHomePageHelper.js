({
	loadTabData : function(component, event, helper) {
		
        var slotKeyParent = event.getParam("tabKey"); 
        if(!slotKeyParent){
            slotKeyParent = component.get("v.slotKeys")[0];
        }
       	$A.createComponent('c:SSS_EventHomeTabData', {
            slotKey: slotKeyParent,
            slotDataMap: component.get("v.slotDataMap")
        }, function attachModal(modalCmp, status) {
            if (component.isValid() && status === 'SUCCESS') {
                var body = component.get("v.body");
                body = [];
                body.push(modalCmp);
                component.set("v.body", body);    
                
                component.set("v.selectedSlotKey", slotKeyParent);
                
            }
        });
        
	}
})