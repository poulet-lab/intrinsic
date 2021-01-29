function cbOkay(obj,~,~)

deviceData = getappdata(obj.Figure,'deviceData');
controls   = getappdata(obj.Figure,'controls');

% save values to object properties
obj.DeviceData     = deviceData;
obj.Magnification  = controls.magnification.String{controls.magnification.Value};

% save values to matfile
obj.saveVar('Magnification', obj.Magnification)
obj.saveVar('Data', obj.Data)

% close figure & fire notifier
close(obj.Figure)
notify(obj,'Update')