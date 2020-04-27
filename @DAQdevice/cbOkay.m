function obj = cbOkay(obj,~,~)
obj.toggleCtrls('off')

% save variables to matfile
obj.saveVar('vendorID',  getappdata(obj.fig,'vendorID'))
obj.saveVar('deviceID',  getappdata(obj.fig,'deviceID'))
obj.saveVar('channelIDs',getappdata(obj.fig,'channelIDs'))
obj.saveVar('rate',      getappdata(obj.fig,'rate'))
obj.saveVar('triggerAmp',getappdata(obj.fig,'triggerAmp'))

% create interface
obj.createSession()

% close figure
close(obj.fig)
