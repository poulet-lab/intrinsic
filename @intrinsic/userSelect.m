function out = userSelect(obj)

out = false;

Usernames = obj.loadVar('Usernames',{''},true);
Username  = obj.loadVar('Username',{''},true);
DirData   = obj.DirData;

% No need to show the user selection if there is only one user
if numel(Usernames)==1
    obj.Username = Username;
    obj.UserSettings = obj.getUserSettings();
    out = true;
    return
end

window = settingsWindow(...
    'Name',  	'Select User');
window.addPopupEdit( ...
    'Label',  	'Username', ...
    'String',  	Usernames, ...
    'Value',    find(ismember(Usernames,Username),1), ...
    'Callback', @cbUsername);
[controls.okay,controls.cancel] = window.addOKCancel(...
    'Callback',	@cbOkay);

window.Visible = 'on';
uiwait(window.Handle)


    function cbUsername(src,~)
        Usernames = src.String;
        Username = src.String{src.Value};
    end

    function cbOkay(~,~)
        obj.saveVar('DirData',DirData)
        obj.saveVar('Usernames',Usernames)
        obj.saveVar('Username',Username)
        obj.Username = Username;
        obj.UserSettings = obj.getUserSettings();
        out = true;
        close(window.Handle)
    end
end