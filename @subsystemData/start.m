function start(obj,~,~)

% Check if tempdata is empty
obj.checkDirTemp()

% Check for ongoing acquisition
if obj.Running
    return
end
obj.Running = true;

% Copy settings file to tempdata
copyfile(obj.Parent.Settings.Properties.Source,fullfile(obj.DirTemp))

% Just for testing
% obj.Red = imageRed(obj);

disp(' ')
dPause = obj.Parent.Stimulus.Parameters.InterTrial;
ii = 0;
while true
    ii = ii + 1;
    
    % Acquire data
    intrinsic.message('Starting trial %d',ii)
    obj.Parent.DAQ.queueData()
    obj.Parent.Camera.start()
    obj.Parent.DAQ.start()
    obj.Parent.Camera.stop()
    if obj.Running
        obj.getDataFromCamera()
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