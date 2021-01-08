function cbFPS(obj, ~, ~)

% get currently selected value from UI control
ctrl       = getappdata(obj.Figure,'controls');
hCtrl      = ctrl.FPS;
fps        = round(str2double(hCtrl.String));
adaptor    = getappdata(obj.Figure,'adaptor');
deviceName = getappdata(obj.Figure,'deviceName');

% limit rates for qimaging QICam B
if ismember(adaptor,{'qimaging','mwqimagingimaq'}) && strcmpi(deviceName,'QICam B')
    res = getappdata(obj.Figure,'resolution');
    switch res(2)
        case 130
            lims = [1 59];
        case 260
            lims = [1 36];
        case 520
            lims = [1 19];
        case 1040
            lims = [1 6];
    end
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
