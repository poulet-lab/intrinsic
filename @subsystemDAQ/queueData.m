function queueData(obj)

% Generate stimulus
tsc = tscollection([],'Name','Output Data');
tsc.Stimulus = obj.Parent.Stimulus.generate([],obj.Session.Rate);

% Prepare camera trigger
fs   = obj.Session.Rate;
rate = obj.Parent.Camera.FrameRate;
tsc.Trigger = tsc.Stimulus;
tsc.Trigger.Data = zeros(size(tsc.Trigger.Data));

% Make sure that t=0 is included as a trigger
triggerIdx   = 1:round(fs/rate):length(tsc.Trigger.Data);
[~,zeroIdx1] = min(abs(tsc.Trigger.Time(triggerIdx)));
[~,zeroIdx2] = min(abs(tsc.Trigger.Time));
zeroShift    = triggerIdx(zeroIdx1) - zeroIdx2;
triggerIdx   = triggerIdx - zeroShift;
triggerIdx(triggerIdx<1 | triggerIdx > numel(tsc.Trigger.Data)) = [];
tsc.Trigger.Data(triggerIdx) = obj.TriggerAmplitude;

% Check if we actually need to carry on
if isequal(obj.OutputData,tsc)
    return
end

% Save tscollection to object
obj.OutputData = tsc;

% Combine output data to matrix
outputData = zeros(obj.OutputData.Stimulus.Length,obj.NChannelsOut);
outputData(:,1) = squeeze(obj.OutputData.Stimulus.Data);
outputData(:,2) = squeeze(obj.OutputData.Trigger.Data);

% Queue output data
tmp = 'daq:Session:queuedDataHasBeenDeleted';
warning('off',tmp)
obj.Session.release;
obj.Session.queueOutputData(outputData)
warning('on',tmp)

% Print message & fire notifier
intrinsic.message('Queuing output data: %d samples at %d Hz (%g seconds)',...
    obj.Session.NumberOfScans,obj.Session.Rate,obj.Session.DurationInSeconds)

% notify listeners of updated settings
notify(obj,'Update')