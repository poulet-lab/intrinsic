function cbROI(obj, ~, ~)

h   = getappdata(obj.fig,'controls');
h   = findobj([h.ROI(1) h.ROI(2)])';
roi = round(str2double({h.String}));
if isequal(getappdata(obj.fig,'roi'),roi)
    return
end

res = getappdata(obj.fig,'resolution');
if isempty(res) || any(isnan(res))
    roi = [NaN NaN];
    set(h,'String','','Enable','Off')
else
    idx = isnan(roi) | (roi > res) | (roi < 0);
    roi(idx) = res(idx);
    arrayfun(@(x,y) set(x,'String',num2str(y)),h,roi)
    set(h,'Enable','On')
end
setappdata(obj.fig,'roi',roi);
obj.bitrate