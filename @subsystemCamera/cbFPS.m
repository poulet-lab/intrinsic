function cbFPS(obj, ~, ~)

% get currently selected value from UI control
ctrl       = getappdata(obj.Figure,'controls');
hCtrl      = ctrl.FPS;
fps        = round(str2double(hCtrl.String));
adaptor    = getappdata(obj.Figure,'adaptor');
deviceName = getappdata(obj.Figure,'deviceName');

% limit rates for qimaging QICam B
if ismember(adaptor,{'qimaging','mwqimagingimaq'}) && strcmpi(deviceName,'QICam B')
    roi      = getappdata(obj.Figure,'roi');
    bitdepth = getappdata(obj.Figure,'bitdepth');
    lims     = [1 min([110 floor(100/(bitdepth * prod(roi) / 1E6))])];
else
    lims = [1 60];
end

fps = max([fps min(lims)]);
fps = min([fps max(lims)]);

hCtrl.String = num2str(fps);
setappdata(obj.Figure,'rate',fps);

if isCallback
    obj.bitrate()
end
