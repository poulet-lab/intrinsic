function cbVendor(obj,~,~)

% get currently selected value from UI control
ctrl    = getappdata(obj.fig,'controls');
hCtrl   = ctrl.vendor;
value   = hCtrl.String{hCtrl.Value};
value   = obj.vendors.ID(matches(obj.vendors.FullName,value));

% compare with previously selected value (return if identical)
if isequal(hCtrl.UserData,value)
    return
end
hCtrl.UserData = value;

% select devices matching current vendor
devices = obj.devices;
if ~isempty(devices)
    hw = devices(matches(devices.VendorID,value),:);
else
    hw = {};
end

% manage UI control for device selection
if isempty(hw)
    % disable device selection
    ctrl.device.Enable	= 'off';
    ctrl.device.String  = {''};
    ctrl.device.Value   = 1;
else
    % enable device selection, fill device IDs and names
    ctrl.device.Enable	= 'on';
    ctrl.device.String  = compose('%s: %s',[hw.DeviceID hw.Model]);

    % select previously used device if vendor matches
    if strcmp(value,loadvar(obj,'vendor',''))
        ctrl.device.Value = max([find([hw.DeviceID]==...
            loadvar(obj,'deviceID',NaN)) 1]);
    else
        ctrl.device.Value = 1;
    end

    % run dependent callback
    obj.cbDevice()
end
