function start(obj,~,~)

% Check if tempdata is empty
obj.checkDirTemp()

% Check for unsaved data
if obj.Unsaved
    warndlg('Unsaved data!')
    return
end
obj.Unsaved = true;

% Check for ongoing acquisition
if obj.Running
    return
end
obj.Running = true;

% Collect parameters
obj.getParameters()
obj.P.Scale.Magnification	= obj.Parent.Scale.Magnification;
obj.P.Scale.PxPerCm         = obj.Parent.Scale.PxPerCm;

% Copy settings files to tempdata
copyfile(obj.Parent.Settings.Properties.Source,fullfile(obj.DirTemp))
copyfile(obj.Parent.UserSettings.Properties.Source,fullfile(obj.DirTemp))

% Just for testing
obj.Parent.Red.setScale()
%imageRed(obj.Parent);

disp(' ')
dPause = obj.P.Stimulus.InterTrial;
ii = 0;
while true
    ii = ii + 1;

    % Acquire data
    intrinsic.message('Starting trial %d',ii)
    obj.Parent.DAQ.queueData()
    obj.Parent.Camera.start(obj.Parent.DAQ.nFrameTrigger)
    obj.Parent.DAQ.start()
    obj.Parent.Camera.stop()
    if obj.Running
        obj.Parent.status('Processing ...')
        obj.getDataFromCamera()
        obj.Trials(obj.nTrials).InputData = obj.Parent.DAQ.InputData;
    end

    % Inter-trial pause
    for pp = 1:dPause
        if ~obj.Running
            obj.Parent.status
            disp(' ')
            return
        else
            obj.Parent.status(sprintf('Waiting (%ds)',dPause-pp))
            pause(1)
        end
    end
    disp(' ')
end
