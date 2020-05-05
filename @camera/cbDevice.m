function cbDevice(obj,~,~)

% get currently selected value from UI control
ctrl  = getappdata(obj.fig,'controls');
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
    adaptor    = getappdata(obj.fig,'adaptor');
    deviceInfo = getappdata(obj.fig,'deviceInfo');
    deviceInfo = deviceInfo(hCtrl.Value);
    deviceID   = deviceInfo.DeviceID;
    deviceName = deviceInfo.DeviceName;
    modes      = deviceInfo.SupportedFormats(:);

    % restrict modes to 16bit MONO (supported devices only)
    if contains(deviceName,'QICam')
        modes  = modes(contains(modes,'MONO16'));
    end

    % sort modes by resolution (if obtainable through regexp) and fill ctrl
    tmp = regexpi(modes,'^(\w*)_(\d)*x(\d)*$','tokens','once');
    if all(cellfun(@numel,tmp)==3)
        tmp = cat(1,tmp{:});
        tmp(:,2:3) = cellfun(@(x) {str2double(x)},tmp(:,2:3));
        [~,idx] = sortrows(tmp);
        modes = modes(idx);
    end
    ctrl.mode.String = modes;

    % save variables to appdata for later use
    setappdata(obj.fig,'deviceID',deviceID)
    setappdata(obj.fig,'deviceName',deviceName)
    setappdata(obj.fig,'modes',modes);

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
