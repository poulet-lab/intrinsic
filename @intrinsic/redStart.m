function redStart(obj,~,~)

nruns = 10;
ovs   = obj.Oversampling;

obj.clearData
obj.TimeStamp = now;

ntrig   = nnz(obj.DAQvec.cam(:));
daq_vec = full([obj.DAQvec.cam(:) obj.DAQvec.stim(:)]);

obj.StimIn = nan(length(obj.DAQvec.stim),nruns);

%% CONFIGURE CAMERA TRIGGER
switch obj.VideoAdaptorName
    case 'qimaging'
        triggerconfig(obj.VideoInputRed,'hardware','risingEdge','TTL')
        obj.VideoInputRed.TriggerRepeat  = ntrig - 1;
    case 'hamamatsu'
        triggerconfig(obj.VideoInputRed,'hardware','RisingEdge','EdgeTrigger')
        obj.VideoInputRed.TriggerRepeat  = ntrig - 2;
end
obj.VideoInputRed.FramesPerTrigger       = 1;
obj.VideoInputRed.FramesAcquiredFcn      = @display_frame_count;
obj.VideoInputRed.FramesAcquiredFcnCount = 1;

%% SELECT DAQ DEVICE
daqreset                                        % release all DAQ devices
DAQdev = daq.getDevices;                        % list all DAQ devices
DAQidx = find(arrayfun(@(x) ...                 % index of 1st NI device
    strcmp(x.Vendor.ID,'ni'),DAQdev),1);
DAQdev = DAQdev(DAQidx);                        % select 1st NI device

%% CONFIGURE DAQ SESSION
obj.DAQsession = daq.createSession(DAQdev.Vendor.ID);
if strcmp(DAQdev.Model,'USB-6001')
    obj.DAQsession.addAnalogOutputChannel(DAQdev.ID,1,'Voltage');
    obj.DAQsession.addAnalogOutputChannel(DAQdev.ID,0,'Voltage');
    %obj.DAQsession.addAnalogInputChannel(DAQdev.ID,0,'Voltage');
    daq_vec(:,1) = daq_vec(:,1) * 5;
else
    obj.DAQsession.addDigitalChannel(DAQdev.ID,'Port0/line0','OutputOnly');
    obj.DAQsession.addAnalogOutputChannel(DAQdev.ID,0,'Voltage');
    obj.DAQsession.addAnalogInputChannel(DAQdev.ID,0,'Voltage');
    obj.DAQsession.Channels(3).Name = 'Stimulus In';
end
obj.DAQsession.Channels(1).Name = 'Camera clock';
obj.DAQsession.Channels(2).Name = 'Stimulus Out';
obj.DAQsession.Rate = obj.DAQrate;


%% RUN
tmp    = obj.Settings.Stimulus;
dpause = round(tmp.inter-tmp.pre-tmp.post);

obj.Flags.Running = true;
for ii = 1:nruns

    start(obj.VideoInputRed)                            % arm the camera
    pause(1)                                            % safety margin
    queueOutputData(obj.DAQsession,daq_vec)             % queue DAQ data
    obj.StimIn(:,ii) = obj.DAQsession.startForeground;  % start DAQ session
    pause(1)                                            % safety margin
    release(obj.DAQsession)                             % release DAQ session
    if ~isrunning(obj.VideoInputRed) && ...             % check for interruption
            obj.VideoInputRed.FramesAvailable ~= ...
            obj.VideoInputRed.TriggerRepeat+1
        obj.status
        break
    end
    stop(obj.VideoInputRed)                         % disarm the camera

    % get data from camera
    obj.status('Processing ...');
    drawnow
    try
        switch obj.VideoAdaptorName
            case 'hamamatsu'
                % Our Hamamatsu Camera seems to miss the first frame
                data = getdata(obj.VideoInputRed,ntrig-1,'uint16');
                data = squeeze(data(:,:,1,(obj.WarmupN):end));
            otherwise
                % Other cameras (like the Q-Cam) should work properly
                data = getdata(obj.VideoInputRed,ntrig,'uint16');
                data = squeeze(data(:,:,1,(obj.WarmupN+1):end));
        end
    catch ME
        obj.status
        errordlg(ME.message)
        ME.rethrow
    end

    % save data to obj.Stack, process stack
    if ovs>1
        data = reshape(data,[size(data,1) size(data,2) ovs size(data,3)/ovs]);
        obj.Stack{ii} = uint16(squeeze(mean(data,3)));
    else
        obj.Stack{ii} = uint16(data);
    end
    obj.processStack

    % format figure title
    for pp = 1:dpause
        if ~obj.Flags.Running
            obj.status
            return
        else
            obj.status(sprintf('Waiting (%ds)',dpause-pp))
            pause(1)
        end
    end
end
obj.Flags.Running   = false;
obj.status

release(obj.DAQsession)
obj.DAQsession = [];

    function display_frame_count(~,~,~)
        asd = sprintf(...
            'Acquiring Data (run %d/%d: %d%%)',...
            [ii nruns floor(100*obj.VideoInputRed.FramesAvailable/ ...
            (obj.VideoInputRed.TriggerRepeat+1))]);
        obj.status(asd)
    end
end
