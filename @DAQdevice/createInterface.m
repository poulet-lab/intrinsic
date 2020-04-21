function createInterface(obj)

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

% create interface
fprintf('Creating DAQ interface using %s ...\n\n',...
    obj.devices(vendorID,deviceID).Description)
deviceInfo   = obj.devices(vendorID,deviceID).DeviceInfo;
subSys       = obj.subsystems(deviceInfo);
DAQinterface = daq(vendorID);
for ii = 1:numel(props)
    subIdx  = cellfun(@(x) ismember(channelIDs{ii},x),{subSys.ChannelNames});
    subType = subSys(subIdx).SubsystemType;
    switch subType
        case 'AnalogOutput'
            DAQinterface.addoutput(deviceID,channelIDs{ii},'Voltage')
        case 'AnalogInput'
            DAQinterface.addinput(deviceID,channelIDs{ii},'Voltage')
        case 'DigitalIO'
            if strcmp(props(ii).flow,'out')
                DAQinterface.addoutput(deviceID,channelIDs{ii},'Digital')
            else
                DAQinterface.addinput(deviceID,channelIDs{ii},'Digital')
            end
    end
    DAQinterface.Channels(ii).Name = props(ii).label;
end

% set sampling rate & save interface to object
DAQinterface.Rate = rate;
obj.interface = DAQinterface;