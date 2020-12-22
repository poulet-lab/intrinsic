function settingsGeneral(obj,~,~)

% create settings window & panels
window = settingsWindow(...
    'Name',  	'General Settings', ...
    'Width',	350);

% create UI controls
window.addDirectory( ...
    'Label',  	'Data Directory', ...
    'String',  	pwd, ...
    'Callback',	@cbDirectory);
window.addPopupEdit( ...
    'Label',  	'Usernames / Initials', ...
    'String',  	{'A','B'});
[controls.okay,controls.cancel] = window.addOKCancel(...
    'Callback',	@obj.cbOkay);

% % save appdata & initialize
% cbType(Controls.Type,[])
% setappdata(obj.Figure,'controls',Controls);
% setappdata(obj.Figure,'parameters',Parameters);
window.Visible = 'on';





    function cbDirectory(src,~)
        %keyboard
    end

end