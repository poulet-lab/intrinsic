function cbDevice(obj,~,~)

% get currently selected value from UI control
ctrl    = getappdata(obj.fig,'controls');
hCtrl   = ctrl.device;
device  = hCtrl.String{hCtrl.Value};
device  = regexp(device,'^([\w]*)','match','once');

% compare with previously selected value (return if identical)
if isequal(hCtrl.UserData,device)
    return
end
hCtrl.UserData = device;

% find channels
vendor     = ctrl.vendor.UserData;
chNamesOut = obj.channels(vendor,device,{'AnalogOutput','DigitalIO'});
chNamesIn   = obj.channels(vendor,device,{'AnalogInput','DigitalIO'});

% manage UI control for output channel selection
if isempty(chNamesOut)
    set([ctrl.outStim ctrl.outCam], ...
    	'String',   {''}, ...
        'Enable',   'off', ...
        'Value',    1);
else
    set([ctrl.outStim ctrl.outCam], ...
    	'String',   chNamesOut, ...
        'Enable',   'on');
end

% manage UI control for input channel selection
if isempty(chNamesIn)
    set(ctrl.inCam, ...
    	'String',   {''}, ...
        'Enable',   'off', ...
        'Value',    1);
else
    set(ctrl.inCam, ...
    	'String',   chNamesIn, ...
        'Enable',   'on');
end

% % select devices matching current vendor
% devices = obj.devices;
% if ~isempty(devices)
%     hw = devices(matches(devices.VendorID,value),:);
% else
%     hw = {};
% end
% 
% % manage UI control for device selection
% if isempty(hw)
%     % disable device selection
%     ctrl.device.Enable	= 'off';
%     ctrl.device.String  = {''};
%     ctrl.device.Value   = 1;
% else
%     % enable device selection, fill device IDs and names
%     ctrl.device.Enable	= 'on';
%     ctrl.device.String  = compose('%s: %s',[hw.DeviceID hw.Model]);
% 
% %     % select previously used device if adaptor matches
% %     if strcmp(value,loadvar(obj,'adaptor',''))
% %         c.device.Value = max([find([hw.DeviceID]==...
% %             loadvar(obj,'deviceID',NaN)) 1]);
% %     else
% %         c.device.Value = 1;
% %     end
% 
%     obj.interface = daq(value);
end
