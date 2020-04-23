function cbDevice(obj,~,~)

% get currently selected value from UI control
h       = getappdata(obj.fig,'controls');
hCtrl   = h.device;
value   = hCtrl.String{hCtrl.Value};

% compare with previously selected value (return if identical)
if isequal(hCtrl.UserData,value)
    return
end
hCtrl.UserData = value;

% manage UI control for mode selection
if isempty(hCtrl.UserData)
    % disable mode selection
    h.mode.Enable = 'off';
    h.mode.String = {''};
    h.mode.Value  = 1;
else
    % enable mode selection
    h.mode.Enable = 'on';
    
    % get some variables
    hw      = getappdata(obj.fig,'deviceInfo');
    hw      = hw(hCtrl.Value);
    devID   = hw.DeviceID;
    devName = hw.DeviceName;
    modes   = hw.SupportedFormats(:);
    adapt   = h.adaptor.UserData;
    
    % restrict modes to 16bit MONO (supported devices only)
    if ~isempty(regexpi(devName,'^QICam'))
        modes(cellfun(@isempty,regexpi(modes,'^MONO16'))) = [];
    end
    
    % sort modes by resolution (if obtainable through regexp)
    tmp = regexpi(modes,'^(\w*)_(\d)*x(\d)*$','tokens','once');
    if all(cellfun(@numel,tmp)==3)
        tmp = cat(1,tmp{:});
        tmp(:,2:3) = cellfun(@(x) {str2double(x)},tmp(:,2:3));
        [~,idx] = sortrows(tmp);
        modes = modes(idx);
    end
    
    % fill modes, save to appdata for later use
    setappdata(obj.fig,'modes',modes);
    h.mode.String = modes;
    
    % select previously used mode if adaptor & device ID match
    if strcmp(adapt,obj.adaptor) && devID==obj.deviceID
        h.mode.Value = max([find(strcmp(modes,...
            obj.loadVar('videoMode',''))) 1]);
    elseif ~isempty(devID)
        h.mode.Value = find(strcmp(modes,hw.DefaultFormat));
    else
        h.mode.Value = 1;
    end
end
h.mode.UserData = 'needs to be processed by obj.cbMode';

%obj.cbMode(h.mode)
end