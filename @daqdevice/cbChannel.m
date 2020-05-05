function cbChannel(obj,~,~)

% get currently selected value from UI control
ctrl       = getappdata(obj.Fig,'controls');
hCtrl      = ctrl.channel;
channelIDs = arrayfun(@(x) x.String(x.Value),hCtrl);

% compare with previously selected value (return if identical)
if isequal(getappdata(obj.Fig,'channelIDs'),channelIDs)
    return
end
setappdata(obj.Fig,'channelIDs',channelIDs);

% check for duplicates
[~,a,~] = unique(channelIDs);
a       = ismember(channelIDs,channelIDs(setdiff(1:numel(channelIDs),a)));
if any(a)
    set(hCtrl(a),'BackgroundColor','r');
    ctrl.okay.Enable = 'off';
else
    ctrl.okay.Enable = 'on';
end
set(hCtrl(~a),'BackgroundColor','w');

% run dependent callbacks
obj.cbRate()
obj.cbTriggerAmp()
