function cbMode(obj, ~, ~)

% read value from control
ctrl  = getappdata(obj.Figure,'controls');
hCtrl = ctrl.mode;
mode  = hCtrl.String{hCtrl.Value};
setappdata(obj.Figure,'mode',mode);

% find some more variables
deviceName = getappdata(obj.Figure,'deviceName');
adaptor    = getappdata(obj.Figure,'adaptor');
deviceID   = getappdata(obj.Figure,'deviceID');

% fill video resolution
if isempty(mode)
    ctrl.res(1).String = '';
    ctrl.res(2).String = '';
    ctrl.ROI(1).String = '';
    ctrl.ROI(2).String = '';
    resolution = [NaN NaN];
    bitdepth   = NaN;
else
    % Try to get the resolution of the selected mode via regex. In case of
    % a non-standard name create a temporary video input object and get the
    % resolution from there.
    regex = regexpi(mode,'^\w*_(\d)*x(\d)*$','tokens','once');
    if ~isempty(regex)
        resolution = str2double(regex);
    else
        obj.toggleCtrls('off')
        tmp = videoinput(adaptor,deviceID,mode);
        resolution = tmp.VideoResolution;
        delete(tmp)
        obj.toggleCtrls('on')
    end
    ctrl.res(1).String = num2str(resolution(1));
    ctrl.res(2).String = num2str(resolution(2));
    if strcmp(ctrl.ROI(1).String,'NaN')
        ctrl.ROI(1).String = num2str(resolution(1));
        ctrl.ROI(2).String = num2str(resolution(2));
    end

    % try to obtain bitdepth from mode name
    if ~isempty(regexpi(mode,'^MONO(\d+)_.*'))
        bitdepth = str2double(regexpi(mode,'^MONO(\d+)_.*','tokens','once'));
    elseif ~isempty(regexpi(mode,'^YUY2_.*'))
        bitdepth = 8;
    else
        bitdepth = NaN;
    end
end
setappdata(obj.Figure,'resolution',resolution);
setappdata(obj.Figure,'bitdepth',bitdepth);

% fill binning (only on supported cameras)
if ~isempty(mode)
    if ismember(adaptor,{'qimaging','mwqimagingimaq'}) && ismember(deviceName,{'QICam B'})
        tmp = getappdata(obj.Figure,'modes');
        tmp = regexpi(tmp,'^\w*_(\d)*x\d*$','tokens','once');
        bin = max(cellfun(@str2double,[tmp{:}])) / resolution(1);
    end
else
    bin = [];
end
set([ctrl.binning(1) ctrl.binning(2)],'String',bin);

% toggle OK button
tmp = {'on','off'};
ctrl.btnOk.Enable =  tmp{isempty(mode)+1};

% run dependent callbacks
obj.cbROI()
obj.cbFPS()
obj.bitrate()
