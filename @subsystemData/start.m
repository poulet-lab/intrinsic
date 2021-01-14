function start(obj,~,~)

% Check if tempdata is empty
obj.checkDirTemp()

% Check for unsaved data
if obj.Unsaved
    warndlg('Unsaved data!')
    return
end

% Check for ongoing acquisition
if obj.Running
    return
end
obj.Running = true;

% Collect parameters
%obj.P.Version           = intrinsic.version();
%obj.P.Date              = now();
obj.P.Camera.Adaptor        = obj.Parent.Camera.Adaptor;
obj.P.Camera.DeviceName     = obj.Parent.Camera.DeviceName;
obj.P.Camera.Mode           = obj.Parent.Camera.Mode;
obj.P.Camera.DataType       = obj.Parent.Camera.DataType;
obj.P.Camera.Binning        = obj.Parent.Camera.Binning;
obj.P.Camera.BitDepth       = obj.Parent.Camera.BitDepth;
obj.P.Camera.Resolution     = obj.Parent.Camera.Resolution;
obj.P.Camera.ROI            = obj.Parent.Camera.ROI;
obj.P.Camera.FrameRate      = obj.Parent.Camera.FrameRate;
obj.P.DAQ.VendorID          = obj.Parent.DAQ.Session.Vendor.ID;
obj.P.DAQ.VendorName        = obj.Parent.DAQ.Session.Vendor.FullName;
obj.P.DAQ.OutputData        = obj.Parent.DAQ.OutputData;
obj.P.DAQ.nTrigger          = obj.Parent.DAQ.nTrigger;
obj.P.DAQ.tTrigger          = obj.Parent.DAQ.tTrigger;
obj.P.Scale.Magnification   = obj.Parent.Scale.Magnification;
obj.P.Scale.PxPerCm         = obj.Parent.Scale.PxPerCm;
obj.P.Stimulus              = obj.Parent.Stimulus.Parameters;

% Copy settings file to tempdata
copyfile(obj.Parent.Settings.Properties.Source,fullfile(obj.DirTemp))

% Just for testing
% obj.Red = imageRed(obj);

disp(' ')
dPause = obj.P.Stimulus.InterTrial;
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
        obj.Trials(obj.n).InputData = obj.Parent.DAQ.InputData;
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