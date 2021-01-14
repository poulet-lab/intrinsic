function getDataFromCamera(obj)

obj.Unsaved = true;

% increment n
obj.n = obj.n + 1;

% Get data and metadata from the camera
nframes = obj.Parent.Camera.Input.Red.FramesAvailable;
if ~nframes
    error('No data available.')
end
obj.Parent.message('Obtaining %d frames from camera',nframes)
[data,~,metadata] = getdata(obj.Parent.Camera.Input.Red,nframes);

% Save raw data to TIFF
fn = obj.save2tiff(data,datenum(metadata(1).AbsTime));
obj.Trials(obj.n).Filename = fn;

% Save timestamps
obj.Trials(obj.n).TimestampsCamera = datenum(vertcat(metadata.AbsTime));

% Cast data to desired class
data = cast(data,obj.DataType);

% Calculate running mean and variance
obj.Parent.message('Calculating running mean & variance')
if obj.n == 1
    % Initialize Mean and Var
    obj.Mean = data;
    obj.Var  = zeros(size(data),obj.DataType);
else
    % Update Mean and Var using Welford's online algorithm
    norm     = obj.n - 1;
    mean0    = obj.Mean;
    obj.Mean = mean0 + (data - mean0) / obj.n;
    obj.Var  = (obj.Var .* (norm-1) + (data-mean0) .* ...
        (data-obj.Mean)) / norm;
end

% hand over to separate function!
obj.Parent.message('Calculating baseline mean & variance')
idxBase = obj.Parent.DAQ.tTrigger < 0;
meanBase = mean(obj.Mean(:,:,1,idxBase),4);
%stim = mean(stack(:,:,obj.Time>=0 & obj.Time < obj.WinResponse(2)),3);
if obj.n == 1
    varBase = zeros(size(meanBase),obj.DataType);
else
    % the variance of the total group is equal to the mean of
    % the variances of the subgroups, plus the variance of the
    % means of the subgroups
    varBase = mean(obj.Var(:,:,1,idxBase),4) + ...
        var(obj.Mean(:,:,1,idxBase),[],4);
end
stdBase = sqrt(varBase);
% 
% % obtain baseline & stimulus
% base = mean(stack(:,:,obj.Time<0),3);
% stim = mean(stack(:,:,obj.Time>=0 & obj.Time < obj.WinResponse(2)),3);
% 
% % obtain the average response (time res., baseline substracted)
% SequenceRaw  = stack - base;
% ImageRedBase = base;
% ImageRedStim = stim;