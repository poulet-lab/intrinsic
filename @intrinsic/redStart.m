function redStart(obj,~,~)

%% check if tempdata folder is empty
obj.checkTempData()

%% Just for testing
obj.Red = imageRed(obj);

return
%%


ntrig = obj.DAQ.nTrigger;
ovs   = obj.Camera.Downsample;
nruns = 10;

% obj.clearData
% obj.TimeStamp = now;

%obj.StimIn = nan(length(obj.DAQvec.stim),nruns);




%% RUN
%tmp    = obj.Settings.Stimulus;
dpause = round(tmp.inter-tmp.pre-tmp.post);

obj.Flags.Running = true;
for ii = 1:nruns

    fn = fullfile(obj.DirBase,'datastore',sprintf('data%03d.tif',ii));
    
    obj.DAQ.queueData()
    obj.Camera.start()
    obj.DAQ.run()
    obj.Camera.stop();
    obj.Camera.save(fn)

    %data = imageDatastore(fullfile(obj.DirBase,'datastore'),'FileExtensions','.tif')
    
    
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
            'Acquired Data (run %d/%d: %d%%)',...
            [ii nruns floor(100*obj.VideoInputRed.FramesAvailable/ ...
            (obj.VideoInputRed.TriggerRepeat+1))]);
        obj.status(asd)
    end
end
