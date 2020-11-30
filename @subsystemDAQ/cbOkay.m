function obj = cbOkay(obj,~,~)
obj.toggleCtrls('off')

% save variables to matfile
obj.saveVar('vendorID',  getappdata(obj.Figure,'vendorID'))
obj.saveVar('deviceID',  getappdata(obj.Figure,'deviceID'))
obj.saveVar('channelIDs',getappdata(obj.Figure,'channelIDs'))
obj.saveVar('rate',      getappdata(obj.Figure,'rate'))
obj.saveVar('triggerAmp',getappdata(obj.Figure,'triggerAmp'))

% create interface
obj.createSession()

% close figure
close(obj.Figure)
