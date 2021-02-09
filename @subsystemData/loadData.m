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

% Load data.mat
FileLoad = fullfile(DirLoad,'data.mat');
if ~exist(FileLoad,'file')
    tmp = sprintf('Can''t find data.mat in directory\n%s',DirLoad);
    uiwait(warndlg(tmp,'Warning'))
    return
end
load(FileLoad)

keyboard