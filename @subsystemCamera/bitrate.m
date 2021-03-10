function bitrate(obj)

ctrl     = getappdata(obj.Figure,'controls');
bitdepth = getappdata(obj.Figure,'bitdepth');
if isnan(bitdepth)
    ctrl.bitRate.String = '';
    return
end

mode = getappdata(obj.Figure,'mode'); %#ok<*PROP>
roi  = getappdata(obj.Figure,'roi');
fps  = getappdata(obj.Figure,'rate');

ctrl.bitRate.String = sprintf('%0.1f',...
    (bitdepth * prod(roi) * fps) / 1E6);
