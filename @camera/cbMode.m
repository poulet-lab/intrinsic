function cbMode(obj, ~, ~)

% read value from control
ctrl  = getappdata(obj.fig,'controls');
hCtrl = ctrl.mode;
mode  = hCtrl.String{hCtrl.Value};
setappdata(obj.fig,'mode',mode);

% find some more variables
deviceName = getappdata(obj.fig,'deviceName');
adaptor    = getappdata(obj.fig,'adaptor');
deviceID   = getappdata(obj.fig,'deviceID');

% fill video resolution
if isempty(mode)
    ctrl.res(1).String = '';
    ctrl.res(2).String = '';
    ctrl.ROI(1).String = '';
    ctrl.ROI(2).String = '';
    resolution = [NaN NaN];
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
end
setappdata(obj.fig,'resolution',resolution);

% fill binning (only on supported cameras)
if ~isempty(mode)
    if ismember(adaptor,{'qimaging'}) && ismember(deviceName,{'QICam B'})
        tmp = getappdata(obj.fig,'modes');
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
obj.cbOVS()
obj.bitrate()