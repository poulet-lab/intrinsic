function createSession(obj)

vendorID   = obj.loadVar('vendorID','');
deviceID   = obj.loadVar('deviceID','');
channelIDs = obj.loadVar('channelIDs',{});
rate       = obj.loadVar('rate',1000);
props      = obj.channelProp;

% check if device is configured
if isempty(vendorID) || isempty(deviceID)
    obj.setup
    return
end

% check if device is present
device     = obj.devices(vendorID,deviceID);
if isempty(device)
    warning('Can''t find configured DAQ device (%s/%s)',vendorID,deviceID)
    return
end

% create session
fprintf('Creating DAQ session using %s ...\n',...
    obj.devices(vendorID,deviceID).Description)
deviceInfo = obj.devices(vendorID,deviceID);
subSys     = obj.subsystems(deviceInfo);
s          = daq.createSession(vendorID);
for ii = 1:numel(props)
    subIdx  = cellfun(@(x) ismember(channelIDs{ii},x),{subSys.ChannelNames});
    subType = subSys(subIdx).SubsystemType;
    switch subType
        case 'AnalogOutput'
            s.addAnalogOutputChannel(deviceID,channelIDs{ii},'Voltage');
        case 'AnalogInput'
            s.addAnalogInputChannel(deviceID,channelIDs{ii},'Voltage');
        case 'DigitalIO'
            if strcmp(props(ii).flow,'out')
                s.addDigitalChannel(deviceID,channelIDs{ii},'OutputOnly')
            else
                s.addDigitalChannel(deviceID,channelIDs{ii},'InputOnly')
            end
    end
    s.Channels(ii).Name = props(ii).label;
end

% set sampling rate & save session to obj
s.Rate = rate;
obj.session = s;
