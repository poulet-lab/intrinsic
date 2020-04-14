function fileSave(obj,~,~)

if ~obj.nTrials
    warndlg('There''s no data to save.','Hold on ...','modal')
    return
end

hdlg = dialog( ...                                  % create dialog window
    'Position',         [200 200 250 96], ...
    'Visible',          'off', ...
    'Name',             'Save Dataset');
movegui(hdlg,'center')                              % center dialog window

uicontrol( ...                                      % UI text "Initials:"
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
jedit.KeyTypedCallback = @validate;                 % callback: any key
jedit.ActionPerformedCallback = @close;             % callback: enter key

uicontrol( ...                                      % UI text "Comments:"
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

    % Generate directory names, select data to save, save data
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

        % check for existing directory, rename if comments changed
        tmp = dir(fullfile(obj.DirSave,datestr(obj.TimeStamp,[ts_form '*'])));
        if isempty(tmp)
            mkdir(fullfile(obj.DirSave,dirname))
        elseif ~strcmp(tmp(1).name,dirname)
            movefile(fullfile(obj.DirSave,tmp(1).name) ,...
                fullfile(obj.DirSave,dirname))
        end
        dirsave = fullfile(obj.DirSave,dirname);

        % exclude selected properties from saving
        exc = {'h','VideoPreview','Settings','Flags','Movie','Stack',...
            'SequenceRaw','SequenceFilt'};
        tmp = ?intrinsic;
        tmp = {tmp.PropertyList.Name};
        exc = [exc tmp(~cellfun(@isempty,regexpi(tmp,'VideoInput')))];
        exc = [exc tmp(~cellfun(@isempty,regexpi(tmp,'ImageRed')))];

        % exclude dependent properties from saving
        tmp = ?intrinsic;
        tmp = {tmp.PropertyList([tmp.PropertyList.Dependent]).Name};
        exc = unique([exc tmp]);

        % save remaining properties to data.mat
        saveFile = matfile(fullfile(dirsave,'data.mat'),'Writable',true);
        for fn = setxor(fieldnames(obj),exc)'
            saveFile.(fn{:}) = obj.(fn{:});
        end
        m.Properties.Writable = false;


        % save stack as tiff
        tic
        options         = struct;
        options.big     = true;
        options.message = false;
        for ii = 1:obj.nTrials
            saveastiff(obj.Stack{ii},...
                fullfile(dirsave,sprintf('stack%03d.tiff',ii)),options);
        end
        toc

        % copy settings.mat
        copyfile(obj.Settings.Properties.Source,dirsave)

        % save images (red, green, composite)
        if ~isempty(obj.h.image.red)
            imwrite(obj.h.image.red.CData,fullfile(dirsave,'red.png'),'PNG')
            imwrite(imresize(obj.h.image.red.CData,obj.Binning,'nearest'),...
                fullfile(dirsave,'red_scaled.png'),'PNG')
        end
        if ~isempty(obj.ImageGreen)
            tmp = ind2rgb(obj.ImageGreen,gray(2^obj.VideoBits));
            imwrite(tmp,fullfile(dirsave,'green.png'),'PNG')
            if ~isempty(obj.h.image.red)
                tmp = imblend(imresize(obj.h.image.red.CData,obj.Binning,...
                    'nearest'),tmp,1,'hard light');
                imwrite(tmp,fullfile(dirsave,'fused.png'),'PNG')
            end
        end

        % TODO: save PDF
        % use copyobj to copy axes to invisible figure
        % header: date + time, initials, comments
        % image green, image red, fused image
        % temporal plot
        % spatial plot

        % set SAVED flag to true
        obj.Flags.Saved = true;
    end

    % Accept values of textfields, call saveData(), close dialog window
    function close(~,~)
        if length(strtrim(char(jedit.getText))) == 2
            % get strings from textfields
            obj.Settings.initials = char(jedit.getText);
            comment = hcmnt.String;

            % disable UI controls while processing the files
            set(findobj('parent',hdlg,'type','uicontrol'),'enable','off')
            jedit.Enabled = 0;
            drawnow

            % save data, then close dialog
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
