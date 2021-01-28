function obj = cbOkay(obj,~,~)
obj.toggleCtrls('off')

% get values
adaptor      = getappdata(obj.Figure,'adaptor');
deviceID     = getappdata(obj.Figure,'deviceID');
deviceName   = getappdata(obj.Figure,'deviceName');
mode         = getappdata(obj.Figure,'mode');
resolution   = getappdata(obj.Figure,'resolution');
ROI          = getappdata(obj.Figure,'roi');
rate         = getappdata(obj.Figure,'rate');
downsample   = getappdata(obj.Figure,'downsample');
triggerSrc   = getappdata(obj.Figure,'triggerSource');
triggerCond  = getappdata(obj.Figure,'triggerCondition');

% save values to matfile
obj.saveVar('adaptor',adaptor);
obj.saveVar('deviceID',deviceID);
obj.saveVar('deviceName',deviceName);
obj.saveVar('mode',mode);
obj.saveVar('resolution',resolution);
obj.saveVar('ROI',ROI);
obj.saveVar('framerate',rate);
obj.saveVar('downsample',downsample);
obj.saveVar('triggerSource',triggerSrc);
obj.saveVar('triggerCondition',triggerCond);

% create videoinput objects
obj.createInputs;

% notify listeners of updated settings
notify(obj,'Update')

% close figure
close(obj.Figure)
