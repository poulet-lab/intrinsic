function getDataFromCamera(obj)
% Get RAW data from camera, save to TIFF, update running mean & variance

% Update obj.Unsaved flag, increment n
obj.Unsaved = true;
obj.nTrials = obj.nTrials + 1;

% Get data and metadata from the camera
nframes = obj.Parent.Camera.Input.Red.FramesAvailable;
if ~nframes
    error('No data available.')
elseif nframes < obj.P.DAQ.nFrameTrigger
    warning('Some frames where dropped. Try lowering frame rate and/or exposure time.')
end
obj.Parent.message('Obtaining %d frames from camera',nframes)
[data,~,metadata] = getdata(obj.Parent.Camera.Input.Red,nframes);

% Save raw data to TIFF
timestamp = datenum(metadata(1).AbsTime);
fn = sprintf('%03d_%s.tif',obj.nTrials,datestr(timestamp,'yymmdd_HHMMSS'));
obj.Parent.message('Saving image data to disk: %s',fn)
obj.save2tiff(fn,data,timestamp);
obj.Trials(obj.nTrials).Filename = fn;

% Save timestamps
obj.Trials(obj.nTrials).TimestampsCamera = datenum(vertcat(metadata.AbsTime));
obj.Trials(obj.nTrials).TimestampDAQ = obj.Parent.DAQ.tStartTrigger;

% Cast data to desired class
data = cast(data,obj.DataType);

% Calculate running mean and variance
obj.Parent.message('Calculating running mean & variance')
if obj.nTrials == 1
    % Initialize Mean and Var
    obj.DataMean = data;
    obj.DataVar  = zeros(size(data),obj.DataType);
else
    % Update Mean and Var using Welford's online algorithm
    norm  = obj.nTrials - 1;
    mean0 = obj.DataMean;
    obj.DataMean = mean0 + (data - mean0) / obj.nTrials;
    obj.DataVar  = (obj.DataVar .* (norm-1) + (data-mean0) .* ...
        (data-obj.DataMean)) / norm;
end

% Calculate window means
obj.calculateWinMeans

% hand over to separate function!
obj.Parent.message('Calculating baseline mean & variance')
idxBase = obj.Parent.DAQ.tFrameTrigger < 0;
meanBase = mean(obj.DataMean(:,:,1,idxBase),4);
%stim = mean(stack(:,:,obj.Time>=0 & obj.Time < obj.WinResponse(2)),3);
if obj.nTrials == 1
    varBase = zeros(size(meanBase),obj.DataType);
else
    % the variance of the total group is equal to the mean of
    % the variances of the subgroups, plus the variance of the
    % means of the subgroups
    varBase = mean(obj.DataVar(:,:,1,idxBase),4) + ...
        var(obj.DataMean(:,:,1,idxBase),[],4);
end
