function cbMode(obj, hCtrl, ~)

% read value from control
m   = hCtrl.String{hCtrl.Value};
setappdata(obj.fig,'mode',m);

% find some more variables
d   = getappdata(obj.fig,'deviceName');
a 	= getappdata(obj.fig,'adaptor');
id  = getappdata(obj.fig,'deviceID');

% fill video resolution and ROI
h   = getappdata(obj.fig,'controls');
if isempty(m)
    h.res(1).String = '';
    h.res(2).String = '';
    h.ROI(1).String = '';
    h.ROI(2).String = '';
    res = [NaN NaN];
else
    % Try to get the resolution of the selected mode via regex. In case of
    % a non-standard name create a temporary video input object and get the
    % resolution from there.
    regex = regexpi(m,'^\w*_(\d)*x(\d)*$','tokens','once');
    if ~isempty(regex)
        res = str2double(regex);
    else
        obj.toggleCtrls('off')
        tmp = videoinput(a,id,m);
        res = tmp.VideoResolution;
        delete(tmp)
        obj.toggleCtrls('on')
    end
    h.res(1).String = num2str(res(1));
    h.res(2).String = num2str(res(2));
    h.ROI(1).String = num2str(res(1));
    h.ROI(2).String = num2str(res(2));
end
setappdata(obj.fig,'resolution',res);
obj.cbROI()

% fill binning (only on supported cameras)
if ~isempty(m)
    if ismember(a,{'qimaging'}) && ismember(d,{'QICam B'})
        tmp = getappdata(obj.fig,'modes');
        tmp = regexpi(tmp,'^\w*_(\d)*x\d*$','tokens','once');
        bin = max(cellfun(@str2double,[tmp{:}])) / res(1);
    end
else
    bin = [];
end
set([h.binning(1) h.binning(2)],'String',bin);

% toggle OK button
tmp = {'on','off'};
h.btnOk.Enable =  tmp{isempty(m)+1};

% check framerate
obj.cbFPS(h.FPS)
end