function cbVendor(obj,~,~)

% get currently selected value from UI control
ctrl     = getappdata(obj.fig,'controls');
hCtrl    = ctrl.vendor;
vendorID = hCtrl.String{hCtrl.Value};
vendorID = obj.vendors.ID(matches(obj.vendors.FullName,vendorID)).char;

% compare with previously selected value (return if identical)
if isequal(getappdata(obj.fig,'vendorID'),vendorID)
    return
end
setappdata(obj.fig,'vendorID',vendorID);

% manage UI control for device selection
devices = obj.devices(vendorID);
if isempty(devices)
    % disable device selection
    ctrl.device.Enable = 'off';
    ctrl.device.String = {''};
    ctrl.device.Value  = 1;
else
    % enable device selection, fill device IDs and names
    ctrl.device.Enable = 'on';
    ctrl.device.String = compose('%s: %s',[devices.DeviceID devices.Model]);

    % select previously used device if vendor matches
    if strcmp(vendorID,loadVar(obj,'vendorID',''))
        ctrl.device.Value = max([find(strcmp([devices.DeviceID],...
            obj.loadVar('deviceID',NaN)),1) 1]);
    else
        ctrl.device.Value = 1;
    end
    obj.cbDevice;
end
