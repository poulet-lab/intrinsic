function saveData(obj)

% Open dialog box
d = dialog('Position',[0 0 200 100], ...
    'Name',     '', ...
    'Visible',  'off', ...
    'CloseRequestFcn', []);
tmp = uicontrol('Parent',d,...
    'Style',    'text', ...
    'String',   'Saving dataset ...');
tmp.Position = [d.Position(3:4)/2-tmp.Extent(3:4)/2 tmp.Extent(3:4)];
movegui(d,'center')
d.Visible = 'on';
drawnow

try
    % Create output directory
    DirSave = fullfile(obj.Parent.DirData,obj.Parent.Username, ...
        datestr(obj.Trials(1).TimestampsCamera(1),'yymmdd'), ...
        datestr(obj.Trials(1).TimestampsCamera(1),'yymmdd_HHMMSS'));
    if ~exist('DirSave','dir')
        [status,msg] = mkdir(DirSave);
        if ~status
            error('Error creating output directory:\n%s',msg)
        end
    end

    % Copy contents of DirTemp
    intrinsic.message('Moving files to %s',DirSave)
    [status,msg] = movefile(fullfile(obj.DirTemp,'*'),DirSave);
    if ~status
        error('Error moving files to output directory:\n%s',msg)
    end

    % Save anatomical reference
    if ~isempty(obj.Parent.Green)
        obj.Parent.Green.saveTIFF(DirSave)
    end

    % Save some extra information
    copyfile(fullfile(obj.Parent.DirBase,'diary.txt'),DirSave);
    tmp = obj.P;
    tmp.Data = struct(obj);
    tmp.Data = rmfield(tmp.Data,intersect(fieldnames(obj),{'P','Running',...
        'Unsaved','IdxResponse','IdxBaseline','DFF','DFFcontrol'}));
    save(fullfile(DirSave,'data.mat'),'-struct','tmp')

    intrinsic.message('Done.')
    delete(d)
    
catch E
    delete(d)
    movegui(errordlg(E.message,'Error saving dataset'),'center')
    rethrow(E)
end

obj.Unsaved = false;