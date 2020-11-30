function createSession(obj)

vendorID   = obj.loadVar('vendorID','');
deviceID   = obj.loadVar('deviceID','');
channelIDs = obj.loadVar('channelIDs',{});
rate       = obj.loadVar('rate',1000);
props      = obj.ChannelProp;

% check if device is configured
if isempty(vendorID) || isempty(deviceID)
    uiwait(obj.setup)
    return
end

% check if device is present
device = obj.devices(vendorID,deviceID);
if isempty(device)
    warning('Can''t find configured DAQ device (%s/%s)',vendorID,deviceID)
    return
end

% check if parameters have changed
if isa(obj.Session,'daq.Session')
    if  strcmp(obj.Session.Vendor.ID,vendorID) && all(arrayfun(@(x) ...
            strcmp(x.Device.ID,deviceID),[obj.Session.Channels])) && ...
            isequal({obj.Session.Channels.ID}',channelIDs) && ...
            obj.Session.Rate == rate
        return
    end
end

% create session
intrinsic.message('Creating DAQ session: %s',obj.devices(vendorID,deviceID).Description)
deviceInfo = obj.devices(vendorID,deviceID);
subSys     = obj.subsystems(deviceInfo);
session    = daq.createSession(vendorID);
for ii = 1:numel(props)
    subIdx  = cellfun(@(x) ismember(channelIDs{ii},x),{subSys.ChannelNames});
    subType = subSys(subIdx).SubsystemType;
    switch subType
        case 'AnalogOutput'
            session.addAnalogOutputChannel(deviceID,channelIDs{ii},'Voltage');
        case 'AnalogInput'
            session.addAnalogInputChannel(deviceID,channelIDs{ii},'Voltage');
        case 'DigitalIO'
            if strcmp(props(ii).flow,'out')
                session.addDigitalChannel(deviceID,channelIDs{ii},'OutputOnly')
            else
                session.addDigitalChannel(deviceID,channelIDs{ii},'InputOnly')
            end
    end
    session.Channels(ii).Name = props(ii).label;
end

% set sampling rate & save session to obj
session.Rate = rate;
obj.Session = session;

% queue output data
obj.queueData();