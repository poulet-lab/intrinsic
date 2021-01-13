function cbAdapt(obj,~,~)
% Callback for adaptor UI control

% get currently selected value from UI control
ctrl    = getappdata(obj.Figure,'controls');
hCtrl   = ctrl.adaptor;
adaptor = hCtrl.String{hCtrl.Value};

% compare with previously selected value (return if identical)
if isequal(getappdata(obj.Figure,'adaptor'),adaptor)
    return
end
setappdata(obj.Figure,'adaptor',adaptor);

% skip a bunch of callback if user selects no adaptor ('none')
if strcmpi(adaptor,'none')
    set([ctrl.device ctrl.mode], ...
        'Value',    1, ...
        'String',   {''}, ...
        'Enable',   'off');
    set([ctrl.binning ctrl.ROI ctrl.FPS ctrl.bitRate],...
        'String',   '', ...
        'Enable',   'off');
    ctrl.device.UserData = '';
    ctrl.btnOk.Enable = 'on';
    return
else
    set(ctrl.FPS,'Enable','On')
end

% run imaqhwinfo (expensive), save results to appdata
[~,tmp]    = evalc('imaqhwinfo(adaptor)');
deviceInfo = tmp.DeviceInfo;
setappdata(obj.Figure,'deviceInfo',deviceInfo);

% manage UI control for device selection
if isempty(deviceInfo)
    % disable device selection
    ctrl.device.Enable	 = 'off';
    ctrl.device.String   = {''};
    ctrl.device.Value    = 1;
    ctrl.device.UserData = '';
else
    % enable device selection, fill device IDs and names
    ctrl.device.Enable	= 'on';
    ctrl.device.String = cellfun(@(x,y) ...
        {sprintf('Dev %d: %s',x,y)}, ...
        {deviceInfo.DeviceID},{deviceInfo.DeviceName});

    % select previously used device if adaptor matches
    if strcmp(adaptor,loadVar(obj,'adaptor',''))
        ctrl.device.Value = max([find([deviceInfo.DeviceID]==...
            loadVar(obj,'deviceID',NaN)) 1]);
    else
        ctrl.device.Value = 1;
    end
end

% run dependent callbacks
obj.cbDevice(ctrl.device)
