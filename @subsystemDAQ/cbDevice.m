function cbDevice(obj,~,~)

% get currently selected value from UI control
ctrl     = getappdata(obj.Figure,'controls');
hCtrl    = ctrl.device;
deviceID = hCtrl.String{hCtrl.Value};
deviceID = regexp(deviceID,'^([\w]*)','match','once');

% compare with previously selected value (return if identical)
if isequal(getappdata(obj.Figure,'deviceID'),deviceID)
    return
end
setappdata(obj.Figure,'deviceID',deviceID);

% get device info
vendorID   = getappdata(obj.Figure,'vendorID');
deviceInfo = obj.devices(vendorID,deviceID);
setappdata(obj.Figure,'deviceInfo',deviceInfo);

% fill UI controls for channel selection
for ii = 1:numel(ctrl.channel)
    set(ctrl.channel(ii),'String', ...
        obj.channelNames(deviceInfo,obj.ChannelProp(ii).types));
end

% select previously used channels if vendorID and deviceID match
chSaved = obj.loadVar('channelIDs',{});
if numel(chSaved)==numel(ctrl.channel) && ...
        strcmp(loadVar(obj,'vendorID',''),vendorID) && ...
        strcmp(obj.loadVar('deviceID',''),deviceID)
    channelValues = cellfun(@(x,y) {max([find(matches(x,y)) 1])},...
        {ctrl.channel.String}',chSaved(:));
else
    channelValues = {1 2 1};
end
[ctrl.channel.Value] = deal(channelValues{:});
ctrl.rate.String = num2str(obj.loadVar('rate',1000));
ctrl.amp.String  = num2str(obj.loadVar('triggerAmp',5));

% run dependent callback
obj.cbChannel()
