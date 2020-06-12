function cbRate(obj,~,~)

% get currently selected value from UI control
ctrl    = getappdata(obj.Figure,'controls');
hCtrl   = ctrl.rate;
rate    = real(str2double(hCtrl.String));

% compare with previously selected value (return if identical)
if isequal(getappdata(obj.Figure,'rate'),rate)
    return
end

% get available range of values
chIDs   = getappdata(obj.Figure,'channelIDs');
devInfo = getappdata(obj.Figure,'deviceInfo');
sub     = obj.subsystems(devInfo);
idx     = cellfun(@(x) ~isempty(intersect(chIDs,x)),{sub.ChannelNames});
ranges  = vertcat(sub(idx).RateLimit);

% round value & force into range
rate = round(abs(rate));
rate = max([rate max([1 min(ranges(:,1))])]);
rate = min([rate min(ranges(:,2))]);

hCtrl.String = num2str(rate);
setappdata(obj.Figure,'rate',rate);
