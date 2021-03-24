function settingsGeneral(obj,~,~)

Usernames = obj.loadVar('Usernames',{''},true);
Username  = obj.Username;
DirData   = obj.DirData;

window = settingsWindow(...
    'Name',  	'General Settings', ...
    'Width',	400);
window.addDirectory( ...
    'Label',  	'Data Directory', ...
    'String',   DirData, ...
    'Callback', @cbDirData);
window.addPopupEdit( ...
    'Label',  	'Usernames / Initials', ...
    'String',  	Usernames, ...
    'Value',    find(ismember(Usernames,Username),1), ...
    'Callback', @cbUsername);
[controls.okay,controls.cancel] = window.addOKCancel(...
    'Callback',	@cbOkay);

window.Visible = 'on';

    function cbDirData(src,~)
        DirData = src.Directory;
    end

    function cbUsername(src,~)
        Usernames = src.String;
        Username = src.String{src.Value};
    end

    function cbOkay(~,~)
        obj.saveVar('Usernames',Usernames)
        obj.saveVar('Username',Username)
        obj.saveVar('DirData',DirData)
        close(window.Handle)
    end

end