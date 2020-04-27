function obj = cbRate(obj,~,~)

% get currently selected value from UI control
ctrl    = getappdata(obj.fig,'controls');
hCtrl   = ctrl.rate;
rate    = real(str2double(hCtrl.String));

% compare with previously selected value (return if identical)
if isequal(getappdata(obj.fig,'rate'),rate)
    return
end

% get available range of values
chIDs   = getappdata(obj.fig,'channelIDs');
devInfo = getappdata(obj.fig,'deviceInfo');
sub     = obj.subsystems(devInfo);
idx     = cellfun(@(x) ~isempty(intersect(chIDs,x)),{sub.ChannelNames});
ranges  = vertcat(sub(idx).RateLimit);

% round value & force into range
rate = round(abs(rate));
rate = max([rate max([1 min(ranges(:,1))])]);
rate = min([rate max(ranges(:,2))]);

hCtrl.String = num2str(rate);
setappdata(obj.fig,'rate',rate);
