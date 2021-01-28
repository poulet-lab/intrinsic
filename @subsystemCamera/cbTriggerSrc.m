function cbTriggerSrc(obj, ~, ~)

% read value from control
ctrl  = getappdata(obj.Figure,'controls');
hCtrl = ctrl.triggerSrc;
value = hCtrl.String{hCtrl.Value};
setappdata(obj.Figure,'triggerSource',value);

% manage UI control for trigger configuration
if isempty(value)
    ctrl.triggerCond.Enable = 'off';
    ctrl.triggerCond.String = {''};
    ctrl.triggerCond.Value  = 1;
else
    % get trigger info
    triggerInfo = getappdata(obj.Figure,'triggerInfo');
    
    % enable & fill triggerCond ctrl
    ctrl.triggerCond.Enable = 'on';
    tmp = strcmp({triggerInfo.TriggerSource},value);
    ctrl.triggerCond.String = unique({triggerInfo(tmp).TriggerCondition});
    
    % select previously used settings
    ctrl.triggerCond.Value = ...
        max([find(strcmp(ctrl.triggerCond.String,...
        obj.loadVar('triggerCondition',''))) 1]);
end

% run dependent callbacks
obj.cbTriggerCond()