function saveData(obj)

% Create output directory
DirSave = fullfile(obj.Parent.DirData,obj.Parent.Username,...
    datestr(obj.Trials(1).TimestampDAQ,'yymmdd_HHMMSS'));
status = mkdir(DirSave);
if ~status
    errordlg({'Error creating output directory:',DirSave},'Error')
end

% Copy contents of DirTemp
intrinsic.message('Moving files to %s',DirSave)
[status,msg] = movefile(fullfile(obj.DirTemp,'*'),DirSave);
if ~status
    errordlg({'Error moving files to output directory:',msg},'Error')
end

% Save anatomical reference
obj.Parent.Green.saveTIFF(DirSave)

% Save some extra information
copyfile(fullfile(obj.Parent.DirBase,'diary.txt'),DirSave);
tmp = obj.P;
save(fullfile(DirSave,'data.mat'),'-struct','tmp')

intrinsic.message('Done.')

obj.Unsaved = false;