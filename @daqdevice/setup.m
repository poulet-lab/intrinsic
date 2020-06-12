function varargout = setup(obj)
% open GUI to change DAQ settings.

nargoutchk(0,1)

% create settings window & panels
window = settingsWindow(...
    'Name',         'DAQ Settings', ...
    'Width',        300);
obj.Fig  = window.Handle;
panel(1) = window.addPanel('Title','Device Selection');
panel(2) = window.addPanel('Title','Channel Selection');
panel(3) = window.addPanel('Title','Output Parameters');

% create controls: device selection
controls.vendor = panel(1).addUIControl( ...
    'Style',        'popupmenu', ...
    'Label',        'Vendor', ...
    'Callback',     @obj.cbVendor, ...
    'String',       {obj.Vendors.FullName});
controls.vendor.Value = max([find(strcmp(controls.vendor.String,...
    loadVar(obj,'deviceID',NaN)),1) 1]);
controls.device = panel(1).addUIControl( ...
    'Style',        'popupmenu', ...
    'Label',        'Device', ...
    'Callback',     @obj.cbDevice, ...
    'String',       {''});

% create controls: channel parameters
controls.channel = gobjects(numel(obj.ChannelProp),1);
for ii = 1:numel(controls.channel)
    controls.channel(ii) = panel(2).addUIControl( ...
        'Style',        'popupmenu', ...
        'Label',        obj.ChannelProp(ii).label, ...
        'Callback',     @obj.cbChannel, ...
        'String',       {''});
end

% create controls: output parameters
controls.amp = panel(3).addUIControl( ...
    'Style',        'edit', ...
    'Label',        'Trigger Amplitude (V)', ...
    'Callback',     @obj.cbTriggerAmp);
controls.rate = panel(3).addUIControl( ...
    'Style',        'edit', ...
    'Label',        'Sampling Rate (Hz)', ...
    'Callback',     @obj.cbRate);

% create OK/Cancel buttons
[controls.okay,controls.cancel] = window.addOKCancel(...
    'Callback',     @obj.cbOkay);

% save appdata & initialize
setappdata(obj.Fig,'controls',controls);
obj.cbVendor(controls.vendor)
window.Visible = 'on';

% output arguments
if nargout == 1
    varargout{1} = obj.Fig;
end