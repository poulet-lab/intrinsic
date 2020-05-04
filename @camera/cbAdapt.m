function cbAdapt(obj,~,~)
% Callback for adaptor UI control

% get currently selected value from UI control
c       = getappdata(obj.fig,'controls');
hCtrl   = c.adaptor;
value   = hCtrl.String{hCtrl.Value};

% compare with previously selected value (return if identical)
if isequal(hCtrl.UserData,value)
    return
end
hCtrl.UserData = value;

% skip a bunch of callback if user selects no adaptor ('none')
if strcmpi(value,'none')
    set([c.device c.mode], ...
        'Value',    1, ...
        'String',   {''}, ...
        'Enable',   'off');
    set([c.res c.binning c.ROI c.bitDepth c.bitRate],...
        'String',   '', ...
        'Enable',   'off');
    c.btnOk.Enable = 'on';
    return
end

% run imaqhwinfo (expensive), save results to appdata
[~,tmp] = evalc('imaqhwinfo(value)');
hw      = tmp.DeviceInfo;
setappdata(obj.fig,'deviceInfo',hw);

% manage UI control for device selection
if isempty(hw)
    % disable device selection
    c.device.Enable	= 'off';
    c.device.String = {''};
    c.device.Value  = 1;
else
    % enable device selection, fill device IDs and names
    c.device.Enable	= 'on';
    c.device.String = cellfun(@(x,y) ...
        {sprintf('Dev %d: %s',x,y)}, ...
        {hw.DeviceID},{hw.DeviceName});

    % select previously used device if adaptor matches
    if strcmp(value,loadVar(obj,'adaptor',''))
        c.device.Value = max([find([hw.DeviceID]==...
            loadVar(obj,'deviceID',NaN)) 1]);
    else
        c.device.Value = 1;
    end
end
c.device.UserData = 'needs to be processed by obj.cbDev';

% run dependent callbacks
if isCallback
    obj.cbDevice(c.device)
    %obj.cbOVS(h.oversmpl)
end
