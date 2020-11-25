function varargout = setup(obj)
% open GUI to change stimulus settings.

nargoutchk(0,1)

% create settings window & panels
window     = settingsWindow('Name','Stimulus Settings','Width',260);
obj.Figure = window.Handle;
panel(1)   = window.addPanel('Title','Waveform');
panel(2)   = window.addPanel('Title','Timing');

% create UI controls
Controls.Type = panel(1).addPopupmenu( ...
    'Label',   	'Waveform Type', ...
    'Callback',	@cbType, ...
    'String',  	{'Sinusoidal', 'Triangular', 'Square'});
Controls.Type.Value = max([find(strcmp(Controls.Type.String,obj.Type)) 1]);
Controls.Frequency = panel(1).addEdit( ...
    'Label',   	'Frequency (Hz)', ...
    'Callback',	{@forceValue,[0.01 obj.Parent.DAQ.Session.Rate/2]}, ...
    'Value',	obj.Frequency);
Controls.DutyCycle = panel(1).addEdit( ...
    'Label',   	'Duty Cycle (%)', ...
    'Callback',	{@forceValue,[0 100]}, ...
    'Value',	obj.DutyCycle);
Controls.Ramp = panel(1).addEdit( ...
    'Label',   	'Ramp (%)', ...
    'Callback',	{@forceValue,[0 100]}, ...
    'Value',	obj.Ramp);
Controls.Amplitude = panel(1).addEdit( ...
    'Label',   	'Amplitude (V)', ...
    'Callback',	{@forceValue,[0 obj.Parent.DAQ.MaxStimulusAmplitude]}, ...
    'Value',	obj.Amplitude);
Controls.Duration = panel(2).addEdit( ...
    'Label',   	'Duration (s)', ...
    'Callback',	{@forceValue,[0 100]}, ...
    'Value',	obj.Duration);
Controls.PreStimulus = panel(2).addEdit( ...
    'Label',   	'Pre-Stimulus (s)', ...
    'Callback',	{@forceValue,[1/obj.Parent.Camera.FrameRate 100]}, ...
    'Value',	obj.PreStimulus);
Controls.PostStimulus = panel(2).addEdit( ...
    'Label',   	'Post-Stimulus (s)', ...
    'Callback',	{@forceValue,[0 100]}, ...
    'Value',	obj.PostStimulus);
Controls.InterStimulus = panel(2).addEdit( ...
    'Label',   	'Inter-Stimulus (s)', ...
    'Callback',	{@forceValue,[0 1000]}, ...
    'Value',	obj.InterStimulus);
[Controls.okay,Controls.cancel] = window.addOKCancel(...
    'Callback',	@obj.cbOkay);

% edit fields: copy value to string
fn = fieldnames(Controls)';
fn = fn(structfun(@(x) strcmp(x.Style,'edit'),Controls));
for f = fn
    Controls.(f{:}).String = sprintf('%g',Controls.(f{:}).Value);
end

% save appdata & initialize
setappdata(obj.Figure,'controls',Controls);
cbType(Controls.Type,[])
window.Visible = 'on';

% output arguments
if nargout
    varargout{1} = obj.Figure;
end

    function cbType(control,~)
        switch control.String{control.Value}
            case 'Sinusoidal'
                Controls.DutyCycle.String = 50;
                Controls.DutyCycle.Enable = 'off';
                Controls.Ramp.String = NaN;
                Controls.Ramp.Enable = 'off';
            case 'Triangular'
                Controls.DutyCycle.String = 50;
                Controls.DutyCycle.Enable = 'off';
                Controls.Ramp.String = 100;
                Controls.Ramp.Enable = 'off';
            case 'Square'
                Controls.DutyCycle.String = obj.DutyCycle;
                Controls.DutyCycle.Enable = 'on';
                Controls.Ramp.String = 0;
                Controls.Ramp.Enable = 'on';
        end
    end

    function forceValue(control,~,limits)
        value = str2double(control.String);
        if isnan(value)
            value = control.Value;
        else
            value = max(value,limits(1));
            value = min(value,limits(2));
        end
        control.String = sprintf('%g',value);
        control.Value  = value;
    end
end