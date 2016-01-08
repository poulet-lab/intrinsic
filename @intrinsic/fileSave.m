function fileSave(obj,~,~)

if isempty(obj.StackStim)                           % check for data
    warning('There''s no data to save.')
    return
end
isdata = squeeze(obj.StackStim(1,1,1,:)) ~= intmax('uint16');
if ~any(isdata)
    warning('There''s no data to save.')
    return
end

hdlg = dialog( ...                                  % create dialog
    'Position',         [200 200 250 96], ...
    'Visible',          'off', ...
    'Name',             'Save Dataset');
movegui(hdlg,'center')                              % center dialog

uicontrol( ...                                      % add some text
    'Parent',  	hdlg, ...
    'Style',  	'text',...
    'Position',	[10 65 60 17],...
    'String',  	'Initials:', ...
    'Horizon', 	'left');

mask  = javax.swing.text.MaskFormatter('UU');       % define Mask
jedit = javax.swing.JFormattedTextField(mask);      % create JAVA TextField
jedit = javacomponent(jedit,[70,66,26,20],hdlg);    % place JAVA TextField
jedit.Text = obj.loadVar('initials','XX');          % load last initials
jedit.SelectionStart = 0;                           % select string
jedit.KeyTypedCallback = @validate1;                % callback: any key
jedit.ActionPerformedCallback = @close;             % callback: enter key

uicontrol( ...                                      % add some text
    'Parent',  	hdlg, ...
    'Style',  	'text',...
    'Position',	[10 40 60 17],...
    'String',  	'Comments:', ...
    'Horizon', 	'left');
hcmnt = uicontrol( ...
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

validate1(jedit,[])                                 % check validity
jedit.requestFocus()                                % focus TextField
uiwait(hdlg)                                        % wait for dialog

if ~isempty(comment)
    comment = ['___' strtrim(comment)];
    comment(~isstrprop(comment,'alphanum')) = '_';
end

dirname = [datestr(now,'yymmdd_HHMM_') obj.Settings.initials comment];
disp(dirname)


    function close(~,~)
        if length(strtrim(char(jedit.getText))) == 2
            obj.Settings.initials = char(jedit.getText);
            comment = hcmnt.String;
            delete(hdlg)
        else
            beep
        end
    end

    function validate1(jObj,~)
        if length(strtrim(char(jObj.getText))) == 2
            hok.Enable = 'on';
        else
            hok.Enable = 'off';
        end
    end
end