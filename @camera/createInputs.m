function createInputs(obj)

% load variables from disk
adaptor          = obj.loadVar('adaptor','');
deviceID         = obj.loadVar('deviceID',NaN);

% check for adaptor
if strcmp(adaptor,'none') || ~obj.toolbox
    obj.adaptor  = 'none';
    return
elseif isempty(adaptor) && ~isempty(obj.adaptors)
    uiwait(obj.setup)
    return
elseif ismember(adaptor,obj.adaptors) && ~isnan(deviceID)
    tmp = [imaqhwinfo(adaptor).DeviceInfo];
    while ~any(deviceID==[tmp.DeviceID])
        answer = questdlg(['Can''t find the camera. ' ...
            'Did you forget to switch it on?'],'Camera not found',...
            'Retry','Cancel','Retry');
        if strcmp(answer,'Retry')
            fprintf('\nResetting IMAQ toolbox ... ')
            imaqreset
            pause(1)
            fprintf('done.\n')
            tmp = [imaqhwinfo(adaptor).DeviceInfo];
        else
            obj.adaptor  = 'none';
            return
        end
    end
end

% load some more variables from disk
mode             = obj.loadVar('mode','');
resolution       = obj.loadVar('resolution',[NaN NaN]);
ROI              = obj.loadVar('ROI',[NaN NaN]);
ROI              = [floor((resolution-ROI)/2) ROI];
obj.deviceName   = obj.loadVar('deviceName','');
obj.rate         = obj.loadVar('rate',NaN);
obj.oversampling = obj.loadVar('oversampling',1);

% create videoinput objects
if ~isequal({adaptor,deviceID,mode,ROI(3:4)},{obj.adaptor,obj.deviceID, ...
        obj.mode,obj.ROI}) && ~strcmp(adaptor,'none')
    fprintf('Creating video input: %s %s (%s) ...',adaptor,obj.deviceName,mode)
    obj.input.green = videoinput(adaptor,deviceID,mode,'ROIPosition',ROI);
    obj.input.red   = videoinput(adaptor,deviceID,mode,'ROIPosition',ROI);
    obj.adaptor     = adaptor;
    obj.deviceID    = deviceID;
    obj.mode        = mode;
    fprintf(' done.\n')
end