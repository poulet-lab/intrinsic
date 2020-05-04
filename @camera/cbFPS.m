function cbFPS(obj, hCtrl, ~)

fps = round(str2double(hCtrl.String));
a   = getappdata(obj.fig,'adaptor');
d   = getappdata(obj.fig,'deviceName');

% limit rates for qimaing QICam B
if strcmpi([a d],'qimagingQICam B')
    res = getappdata(obj.fig,'resolution');
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
setappdata(obj.fig,'rate',fps);
obj.bitrate
