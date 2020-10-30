function cbOkay(obj,~,~)

deviceData = getappdata(obj.Figure,'deviceData');
controls   = getappdata(obj.Figure,'controls');

% save values to object properties
obj.Magnifications = controls.magnification.String;
obj.Magnification  = obj.Magnifications{controls.magnification.Value};
obj.DeviceData     = deviceData;

% save values to matfile
obj.saveVar('Magnifications', obj.Magnifications)
obj.saveVar('Magnification', obj.Magnification)
obj.saveVar('Data', obj.Data)
obj.saveVar('PxPerCm', obj.PxPerCm)

close(obj.Figure)