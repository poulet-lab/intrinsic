function fileSave(obj,~,~)

if ~obj.nTrials
    warndlg('There''s no data to save.','Hold on ...','modal')
    return
end

hdlg = dialog( ...                                  % create dialog
    'Position',         [200 200 250 96], ...
    'Visible',          'off', ...
    'Name',             'Save Dataset');
movegui(hdlg,'center')                              % center dialog

uicontrol( ...                                      % UI text
    'Parent',  	hdlg, ...
    'Style',  	'text',...
    'Position',	[10 65 60 17],...
    'String',  	'Initials:', ...
    'Horizon', 	'left');

% Define JAVA textfield for entering initials
mask  = javax.swing.text.MaskFormatter('UU');       % define Mask
jedit = javax.swing.JFormattedTextField(mask);      % create JAVA textfield
jedit = javacomponent(jedit,[70,66,26,20],hdlg);    % place JAVA textfield
jedit.Text = obj.loadVar('initials','XX');          % load last initials
jedit.SelectionStart = 0;                           % select string
jedit.KeyTypedCallback = @validate;                % callback: any key
jedit.ActionPerformedCallback = @close;             % callback: enter key

uicontrol( ...                                      % UI text
    'Parent',  	hdlg, ...
    'Style',  	'text',...
    'Position',	[10 40 60 17],...
    'String',  	'Comments:', ...
    'Horizon', 	'left');
hcmnt = uicontrol( ...                              % textfield: comments
    'Parent',   hdlg, ...
    'Style',    'edit', ...
    'Position', [70,40,170,20], ...
    'Horizon',  'left', ...
    'Callback', @close);
comment = '';

hok = uicontrol( ...                                % OK button
    'Parent',   hdlg, ...
    'Position', [8 10 110 20],...
    'String',   'Save Dataset', ...
    'Callback', @close);

hdlg.Visible = 'on';                                % make dialog visible
drawnow

validate(jedit,[])                                  % check validity
jedit.requestFocus()                                % focus TextField
uiwait(hdlg)                                        % wait for dialog


% for ii = 1:obj.nTrials
%     v = VideoWriter(...
%         fullfile(dirsave,sprintf('%02d.mj2',ii)),'Archival');
%     v.MJ2BitDepth = 12;
%     v.FrameRate = obj.RateCam;
%     v.LosslessCompression = true;
%     open(v)
%     tmp = size(obj.StackStim);
%     writeVideo(v,reshape(obj.StackStim(:,:,:,ii),tmp(1),tmp(2),1,tmp(3)))
%     close(v)
% end

    function saveData()
        
        % format comment string
        if ~isempty(comment)
            comment = ['___' strtrim(comment)];
            comment(~isstrprop(comment,'alphanum')) = '_';
        end

        % generate directory name
        ts_form = 'yymmdd_HHMMSS_';                 % format for timestamp
        dirname = [datestr(obj.TimeStamp,ts_form) ...
            obj.Settings.initials comment];

        % check for existing directory, rename if necessary
        tmp = dir(fullfile(obj.DirSave,datestr(obj.TimeStamp,[ts_form '*'])));
        if isempty(tmp)
            mkdir(fullfile(obj.DirSave,dirname))
        elseif ~strcmp(tmp(1).name,dirname)
            movefile(fullfile(obj.DirSave,tmp(1).name) ,...
                fullfile(obj.DirSave,dirname))
        end
        dirsave = fullfile(obj.DirSave,dirname);
        
        % exclude some variables from saving
        exc = {'h','VideoPreview','Settings','State'};
        tmp = ?intrinsic;
        tmp = {tmp.PropertyList.Name};
        exc = [exc tmp(~cellfun(@isempty,regexpi(tmp,'VideoInput')))];
        exc = [exc tmp(~cellfun(@isempty,regexpi(tmp,'Image')))];
        tmp = ?intrinsic;
        tmp = {tmp.PropertyList([tmp.PropertyList.Dependent]).Name};
        exc = unique([exc tmp]);
        
        % save remaining variables to data.mat
        saveFile = matfile(fullfile(dirsave,'data.mat'),'Writable',true);
        for fn = setxor(fieldnames(obj),exc)'
            saveFile.(fn{:}) = obj.(fn{:});
        end
        
        % copy settings.mat
        copyfile(obj.Settings.Properties.Source,dirsave)
        
        % save images
        if ~isempty(obj.h.image.red)
            imwrite(obj.h.image.red.CData,fullfile(dirsave,'red.png'),'PNG')
            imwrite(imresize(obj.h.image.red.CData,obj.Binning,'nearest'),...
                fullfile(dirsave,'red_scaled.png'),'PNG')
        end
        if ~isempty(obj.h.image.green)
            imwrite(obj.h.image.green.CData,fullfile(dirsave,'green.png'),'PNG')
        end
        
        obj.State.Saved = true;
    end

    % Accept values of textfields, close dialog window
    function close(~,~)
        if length(strtrim(char(jedit.getText))) == 2
            obj.Settings.initials = char(jedit.getText);
            comment = hcmnt.String;
            set(findobj('parent',hdlg,'type','uicontrol'),'enable','off')
            jedit.Enabled = 0;
            drawnow
            saveData()
            delete(hdlg)
        else
            beep
        end
    end

    % Enable/disable OK button, depending on validity of initials
    function validate(jObj,~)
        if length(strtrim(char(jObj.getText))) == 2
            hok.Enable = 'on';
        else
            hok.Enable = 'off';
        end
    end
end