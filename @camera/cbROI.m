function cbROI(obj, ~, ~)

ctrl  = getappdata(obj.Figure,'controls');
hCtrl = findobj([ctrl.ROI(1) ctrl.ROI(2)])';
roi   = round(str2double({hCtrl.String}));

res = getappdata(obj.Figure,'resolution');
if isempty(res) || any(isnan(res))
    roi = [NaN NaN];
    set(hCtrl,'String','','Enable','Off')
else
    idx = isnan(roi) | (roi > res) | (roi < 0);
    roi(idx) = res(idx);
    arrayfun(@(x,y) set(x,'String',num2str(y)),hCtrl,roi)
    set(hCtrl,'Enable','On')
end
setappdata(obj.Figure,'roi',roi);

if isCallback
    obj.bitrate
end
