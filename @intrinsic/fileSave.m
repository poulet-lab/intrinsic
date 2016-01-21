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
    'Horizon',  'left');
comment = '';

hok = uicontrol( ...                                % OK button
    'Parent',   hdlg, ...
    'Position', [8 10 110 20],...
    'String',   'Save Dataset', ...
    'Callback', @close);

hdlg.Visible = 'on';                                % make dialog visible
drawnow

validate(jedit,[])                                 % check validity
jedit.requestFocus()                                % focus TextField
uiwait(hdlg)                                        % wait for dialog

if ~isempty(comment)                                % format comment string
    comment = ['___' strtrim(comment)];
    comment(~isstrprop(comment,'alphanum')) = '_';
end

dirname = [datestr(now,'yymmdd_HHMM_') obj.Settings.initials comment];
disp(dirname) 

% dirsave = fullfile(obj.DirSave,dirname);
% mkdir(dirsave)
% 
% fullfile(obj.DirSave,dirname)


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

% TODO: Implement actual save routine


    % Accept values of textfields, close dialog window
    function close(~,~)
        if length(strtrim(char(jedit.getText))) == 2
            obj.Settings.initials = char(jedit.getText);
            comment = hcmnt.String;
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