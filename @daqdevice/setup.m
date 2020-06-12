function varargout = setup(obj)
% open GUI to change DAQ settings.

nargoutchk(0,1)

% create settings window & panels
window     = settingsWindow('Name','DAQ Settings','Width',300);
obj.Figure = window.Handle;
panel(1)   = window.addPanel('Title','Device Selection');
panel(2)   = window.addPanel('Title','Channel Selection');
panel(3)   = window.addPanel('Title','Output Parameters');

% create controls: device selection
controls.vendor = panel(1).addPopupmenu( ...
    'Label',  	'Vendor', ...
    'Callback',	@obj.cbVendor, ...
    'String', 	{obj.Vendors.FullName});
controls.vendor.Value = max([find(strcmp(controls.vendor.String,...
    loadVar(obj,'deviceID',NaN)),1) 1]);
controls.device = panel(1).addPopupmenu( ...
    'Label',   	'Device', ...
    'Callback',	@obj.cbDevice);

% create controls: channel parameters
controls.channel = gobjects(numel(obj.ChannelProp),1);
for ii = 1:numel(controls.channel)
    controls.channel(ii) = panel(2).addPopupmenu( ...
        'Label',  	obj.ChannelProp(ii).label, ...
        'Callback',	@obj.cbChannel, ...
        'String', 	{''});
end

% create controls: output parameters
controls.amp = panel(3).addEdit( ...
    'Label',   	'Trigger Amplitude (V)', ...
    'Callback',	@obj.cbTriggerAmp);
controls.rate = panel(3).addEdit( ...
    'Label',  	'Sampling Rate (Hz)', ...
    'Callback',	@obj.cbRate);

% create OK/Cancel buttons
[controls.okay,controls.cancel] = window.addOKCancel(...
    'Callback',	@obj.cbOkay);

% save appdata & initialize
setappdata(obj.Figure,'controls',controls);
obj.cbVendor(controls.vendor)
window.Visible = 'on';

% output arguments
if nargout == 1
    varargout{1} = obj.Figure;
end
