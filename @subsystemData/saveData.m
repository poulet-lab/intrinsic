function saveData(obj)

% Create output directory
DirSave = fullfile(obj.Parent.DirData,obj.Parent.Username,...
    datestr(obj.Trials(1).TimestampsCamera(1),'yymmdd_HHMMSS'));
if ~exist('DirSave','dir')
    status = mkdir(DirSave);
    if ~status
        errordlg({'Error creating output directory:',DirSave},'Error')
    end
end

% Copy contents of DirTemp
intrinsic.message('Moving files to %s',DirSave)
[status,msg] = movefile(fullfile(obj.DirTemp,'*'),DirSave);
if ~status
    errordlg({'Error moving files to output directory:',msg},'Error')
end

% Save anatomical reference
if ~isempty(obj.Parent.Green)
    obj.Parent.Green.saveTIFF(DirSave)
end

% Save some extra information
copyfile(fullfile(obj.Parent.DirBase,'diary.txt'),DirSave);
tmp = obj.P;
tmp.Data = struct(obj);
tmp.Data = rmfield(tmp.Data,{'IdxResponse','IdxBaseline','P'...
    'Running','Unsaved','DFF','DFFcontrol'});
save(fullfile(DirSave,'data.mat'),'-struct','tmp')

intrinsic.message('Done.')

obj.Unsaved = false;