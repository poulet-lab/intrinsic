function createInputs(obj)

% load variables from disk
adaptor          = obj.loadVar('adaptor','');
deviceID         = obj.loadVar('deviceID',NaN);

% return if adaptor is set to 'none' or IMAQ is unavailable
if strcmp(adaptor,'none') || ~obj.toolbox
    obj.Adaptor  = 'none';
    return
end

% check adaptor / presence of camera
[~,hwinfo] = evalc('imaqhwinfo');
if isempty(adaptor) && ~isempty(hwinfo.InstalledAdaptors)
    uiwait(obj.setup)
    return
elseif ismember(adaptor,hwinfo.InstalledAdaptors) && ~isnan(deviceID)
    tmp = [imaqhwinfo(adaptor).DeviceInfo];
    while ~any(deviceID==[tmp.DeviceID])
        answer = questdlg(['Can''t find the camera. ' ...
            'Did you forget to switch it on?'],'Camera not found',...
            'Retry','Cancel','Retry');
        if strcmp(answer,'Retry')
            obj.reset();
            tmp = [imaqhwinfo(adaptor).DeviceInfo];
        else
            obj.Adaptor  = 'none';
            return
        end
    end
end

% load some more variables from disk
mode           = obj.loadVar('mode','');
resolution     = obj.loadVar('resolution',[NaN NaN]);
ROI            = obj.loadVar('ROI',[NaN NaN]);
ROI            = [floor((resolution-ROI)/2) ROI];
obj.DeviceName = obj.loadVar('deviceName','');
obj.FrameRate  = obj.loadVar('framerate',NaN);
obj.Downsample = obj.loadVar('downsample',1);

% create videoinput objects
if ~isequal({adaptor,deviceID,mode,ROI(3:4)},{obj.Adaptor,obj.DeviceID, ...
        obj.Mode,obj.ROI}) && ~strcmp(adaptor,'none')
    fprintf('Creating video input: %s %s (%s) ...', ...
        adaptor,obj.DeviceName,mode)
    
    obj.Adaptor     = adaptor;
    obj.DeviceID    = deviceID;
    obj.Mode        = mode;
    
    % handle mode/ROI for green channel (supported cameras only)
    if contains(obj.DeviceName,'QICam')
        modes = imaqhwinfo(adaptor,deviceID).SupportedFormats;
        modes = modes(contains(modes,'MONO16'));
        [r,i] = sort(cellfun(@(x) sscanf(x,'MONO16_%dx%*d'),modes));
        obj.Input.Green = videoinput(adaptor,deviceID,modes{i(end)}, ...
            'ROIPosition',ROI * r(end)/resolution(1));
    else
        obj.Input.Green = videoinput(adaptor,deviceID,mode, ...
            'ROIPosition',ROI);
    end
    
    obj.Input.Red   = videoinput(adaptor,deviceID,mode,'ROIPosition',ROI);
    obj.Adaptor     = adaptor;
    obj.DeviceID    = deviceID;
    obj.Mode        = mode;
    fprintf(' done.\n')
end
