function loadData(obj)

% Select directory
if exist(obj.Parent.DirData,'dir')
    tmp = fullfile(obj.Parent.DirData,obj.Parent.Username);
    if ~exist(tmp,'dir')
        tmp = obj.Parent.DirData;
    end
else
    tmp = pwd;
end
DirLoad = uigetdir(tmp);
if isequal(DirLoad,0)
    return
end

% Open dialog box
[~,dataset] = fileparts(DirLoad);
d   = dialog( ...
    'Name',     '', ...
    'Visible',  'off', ...
    'CloseRequestFcn', []);
ds  = uicontrol('Parent',d,...
    'Style',    'text', ...
    'String',   {sprintf('Loading dataset %s',dataset),'','',''});
d.Position(3:4) = ds.Extent(3:4) + 50;
ds.Position = [0 d.Position(4)/2-ds.Extent(4)/2 d.Position(3) ds.Extent(4)];
movegui(d,'center')
d.Visible = 'on';
drawnow

try
    % Load data.mat
    intrinsic.message('Loading dataset %s',dataset)
    FileLoad = fullfile(DirLoad,'data.mat');
    if ~exist(FileLoad,'file')
        error('Can''t find data.mat in directory\n%s',DirLoad);
    end
    obj.P = load(FileLoad);

    % Load images
    fns = fullfile(DirLoad,{obj.P.Data.Trials.Filename});
    for ii = 1:numel(fns)
        obj.nTrials = ii;
        intrinsic.message('Reading %s',obj.P.Data.Trials(ii).Filename)
        ds.String{3} = sprintf('Reading image %d/%d',ii,numel(fns));
        ds.String{4} = obj.P.Data.Trials(ii).Filename;
        drawnow
        if ~exist(fns{ii},'file')
            error('Can''t find %s',fns{ii})
        end
        tmp  = imfinfo(fns{ii});
        data = zeros(tmp(1).Width,tmp(1).Height,tmp(1).SamplesPerPixel,...
            numel(tmp),'uint16');
        for jj = 1:size(data,4)
            data(:,:,:,jj) = imread(fns{ii},jj);
        end
        obj.runMean(data);
    end

    % Set object properties
    obj.Trials = obj.P.Data.Trials;
    obj.WinResponse = obj.P.Data.WinResponse;

    % Calculate window means
    obj.calculateWinMeans
    
    % Set more object properties
	obj.Sigma  = obj.P.Data.Sigma;
    obj.Point  = obj.P.Data.Point;
    
    % Close dialog box
    delete(d)
    
catch E
    % Close dialog box and rethrow error
    delete(d)
    movegui(errordlg(E.message,'Error loading dataset'),'center')
    rethrow(E)
end