function obj = cbOkay(obj,~,~)
obj.toggleCtrls('off')

% get values
adaptor      = getappdata(obj.fig,'adaptor');
deviceID     = getappdata(obj.fig,'deviceID');
deviceName   = getappdata(obj.fig,'deviceName');
mode         = getappdata(obj.fig,'mode');
resolution   = getappdata(obj.fig,'resolution');
ROI          = getappdata(obj.fig,'roi');
rate         = getappdata(obj.fig,'rate');
downsample = getappdata(obj.fig,'downsample');

% save values to matfile
obj.saveVar('adaptor',adaptor);
obj.saveVar('deviceID',deviceID);
obj.saveVar('deviceName',deviceName);
obj.saveVar('mode',mode);
obj.saveVar('resolution',resolution);
obj.saveVar('ROI',ROI);
obj.saveVar('framerate',rate);
obj.saveVar('downsample',downsample);

% create videoinput objects
obj.createInputs;

close(obj.fig)
