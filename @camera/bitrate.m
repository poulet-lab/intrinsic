function bitrate(obj)

% try to obtain bitdepth from mode name
ctrl = getappdata(obj.fig,'controls');
mode = getappdata(obj.fig,'mode'); %#ok<*PROP>
if ~isempty(regexpi(mode,'^MONO(\d+)_.*'))
    bitdepth = str2double(regexpi(mode,'^MONO(\d+)_.*','tokens','once'));
elseif ~isempty(regexpi(mode,'^YUY2_.*'))
    bitdepth = 8;
else
    ctrl.bitRate.String = '';
    return
end

roi = getappdata(obj.fig,'roi');
fps = getappdata(obj.fig,'rate');
ovs = getappdata(obj.fig,'downsample');

ctrl.bitRate.String = sprintf('%0.1f',...
    (bitdepth * prod(roi) * fps) / (ovs * 1E6));
