function queueData(obj)

% Generate stimulus
tsc = tscollection([],'Name','Output Data');
tsc.Stimulus = obj.Parent.Stimulus.generate([],obj.SamplingRate);

% Prepare camera trigger
fs   = obj.SamplingRate;
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
tsc.Trigger.Data(triggerIdx) = 1;% obj.TriggerAmplitude;

% length & amplitude of trigger pulses
triggerLength = .001;
tmp = conv(tsc.Trigger.Data>0,ones(1,ceil(fs*triggerLength)),'full');
tsc.Trigger.Data = tmp(1:numel(tsc.Trigger.Data)) * obj.TriggerAmplitude;

% Update obj property & notify listeners
if ~isequal(obj.OutputData,tsc)
    obj.OutputData = tsc;
    notify(obj,'Update')
end

% Combine output data to matrix
outputData = [obj.OutputData.Stimulus.Data obj.OutputData.Trigger.Data];

% Queue output data
tmp = 'daq:Session:queuedDataHasBeenDeleted';
warning('off',tmp)
obj.Session.release;
obj.Session.queueOutputData(outputData)
warning('on',tmp)

% Print message & fire notifier
intrinsic.message('Queuing output data: %d samples at %d Hz (%g seconds)',...
    obj.Session.NumberOfScans,obj.SamplingRate,obj.Session.DurationInSeconds)
