function cbTriggerAmp(obj,~,~)

% get currently selected value from UI control
ctrl  = getappdata(obj.Fig,'controls');
hCtrl = ctrl.amp;
amp   = real(str2double(hCtrl.String));

% identify trigger channel / subsystem
chTrig  = getappdata(obj.Fig,'channelIDs');
chTrig  = chTrig{strcmp('Camera Trigger',{obj.ChannelProp.label})};
devInfo = getappdata(obj.Fig,'deviceInfo');
subSys  = obj.subsystems(devInfo);
subSys  = subSys(cellfun(@(x) matches(chTrig,x),{subSys.ChannelNames}));

% skip for digital channels
if matches('DigitalIO',subSys.SubsystemType)
    hCtrl.Enable = 'off';
    hCtrl.String = '(digital)';
    setappdata(obj.Fig,'triggerAmp',1);
    return
else
    hCtrl.Enable = 'on';
end

% force value into range
if isnan(amp)
    amp = 5;
end
range = [min(subSys.RangesAvailable.Min) max(subSys.RangesAvailable.Max)];
amp   = max([amp range(1)]);
amp   = min([amp range(2)]);

% save value
hCtrl.String = sprintf('%.1f',amp);
setappdata(obj.Fig,'triggerAmp',str2double(hCtrl.String));
