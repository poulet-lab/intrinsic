function cbTriggerCond(obj, ~, ~)

% read value from control
ctrl  = getappdata(obj.Figure,'controls');
hCtrl = ctrl.triggerCond;
value = hCtrl.String{hCtrl.Value};
setappdata(obj.Figure,'triggerCondition',value);