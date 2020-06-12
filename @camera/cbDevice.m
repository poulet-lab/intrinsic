function cbDevice(obj,~,~)

% get currently selected value from UI control
ctrl  = getappdata(obj.Figure,'controls');
hCtrl = ctrl.device;
value = hCtrl.String{hCtrl.Value};

% compare with previously selected value (return if identical)
if isequal(hCtrl.UserData,value)
    return
end
hCtrl.UserData = value;

% manage UI control for mode selection
if isempty(value)
    % disable mode selection
    ctrl.mode.Enable = 'off';
    ctrl.mode.String = {''};
    ctrl.mode.Value  = 1;
else
    % enable mode selection
    ctrl.mode.Enable = 'on';

    % get some variables
    adaptor    = getappdata(obj.Figure,'adaptor');
    deviceInfo = getappdata(obj.Figure,'deviceInfo');
    deviceInfo = deviceInfo(hCtrl.Value);
    deviceID   = deviceInfo.DeviceID;
    deviceName = deviceInfo.DeviceName;
    modes      = obj.modes(adaptor,deviceID);

    % fill modes ctrl
    ctrl.mode.String = modes;

    % save variables to appdata for later use
    setappdata(obj.Figure,'deviceID',deviceID)
    setappdata(obj.Figure,'deviceName',deviceName)
    setappdata(obj.Figure,'modes',modes);

    % select previously used settings if adaptor & device ID match
    if strcmp(loadVar(obj,'adaptor',[]),adaptor) && ...
            (loadVar(obj,'deviceID',NaN) == deviceID)
        ctrl.mode.Value = ...
            max([find(strcmp(modes,obj.loadVar('mode',''))) 1]);
        ROI = obj.loadVar('ROI',[NaN NaN]);
        ctrl.ROI(1).String   = ROI(1);
        ctrl.ROI(2).String   = ROI(2);
        ctrl.FPS.String      = obj.loadVar('rate',1);
        ctrl.oversmpl.String = obj.loadVar('downsample',1);
    elseif ~isempty(deviceID)
        ctrl.mode.Value = find(strcmp(modes,deviceInfo.DefaultFormat));
    else
        ctrl.mode.Value = 1;
    end
end

obj.cbMode(ctrl.mode)
