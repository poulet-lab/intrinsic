function obj = cbOkay(obj,~,~)
obj.toggleCtrls('off')

% save variables to matfile
obj.saveVar('vendorID',  getappdata(obj.Fig,'vendorID'))
obj.saveVar('deviceID',  getappdata(obj.Fig,'deviceID'))
obj.saveVar('channelIDs',getappdata(obj.Fig,'channelIDs'))
obj.saveVar('rate',      getappdata(obj.Fig,'rate'))
obj.saveVar('triggerAmp',getappdata(obj.Fig,'triggerAmp'))

% create interface
obj.createSession()

% close figure
close(obj.Fig)
