function bitrate(obj)

% try to obtain bitdepth from mode name
ctrl = getappdata(obj.Figure,'controls');
mode = getappdata(obj.Figure,'mode'); %#ok<*PROP>
if ~isempty(regexpi(mode,'^MONO(\d+)_.*'))
    bitdepth = str2double(regexpi(mode,'^MONO(\d+)_.*','tokens','once'));
elseif ~isempty(regexpi(mode,'^YUY2_.*'))
    bitdepth = 8;
else
    ctrl.bitRate.String = '';
    return
end

roi = getappdata(obj.Figure,'roi');
fps = getappdata(obj.Figure,'rate');

ctrl.bitRate.String = sprintf('%0.1f',...
    (bitdepth * prod(roi) * fps) / 1E6);
