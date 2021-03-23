function out = userSelect(obj)

out = false;

Usernames = obj.loadVar('Usernames',{''});
Username  = obj.Username;
DirData   = obj.DirData;

window = settingsWindow(...
    'Name',  	'Select User');
window.addPopupEdit( ...
    'Label',  	'Usernames / Initials', ...
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
        out = true;
        obj.saveVar('Usernames',Usernames)
        obj.saveVar('Username',Username)
        obj.saveVar('DirData',DirData)
        close(window.Handle)
    end

end