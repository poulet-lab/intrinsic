function varargout = setup(obj)
% open GUI to change stimulus settings.

nargoutchk(0,1)

obj.Parent.h.axes.temporalBg.Visible = 'Off';

% create settings window & panels
window = settingsWindow(...
    'Name',             'Stimulus Settings', ...
    'Width',            260, ...
    'CloseRequestFcn',  @cbClose, ...
    'DeleteFcn',        @cbDelete);
obj.Figure = window.Handle;
panel(1)   = window.addPanel('Title','Waveform');
panel(2)   = window.addPanel('Title','Timing');

% local copy of parameter struct
Parameters = obj.Parameters;

% create UI controls
Controls.Type = panel(1).addPopupmenu( ...
    'Label',   	'Waveform Type', ...
    'Callback',	@cbType, ...
    'String',  	{'Sinusoidal', 'Triangular', 'Square'});
Controls.Type.Value = max([find(strcmp(Controls.Type.String,Parameters.Type)) 1]);
Controls.Frequency = panel(1).addEdit( ...
    'Label',   	'Frequency (Hz)', ...
    'Callback',	{@cbEdit,[0.01 obj.Parent.DAQ.Session.Rate/2]}, ...
    'Value',	Parameters.Frequency);
Controls.DutyCycle = panel(1).addEdit( ...
    'Label',   	'Duty Cycle (%)', ...
    'Callback',	{@cbEdit,[0 100]}, ...
    'Value',	Parameters.DutyCycle);
Controls.Ramp = panel(1).addEdit( ...
    'Label',   	'Ramp (%)', ...
    'Callback',	{@cbEdit,[0 100]}, ...
    'Value',	Parameters.Ramp);
Controls.Amplitude = panel(1).addEdit( ...
    'Label',   	'Amplitude (V)', ...
    'Callback',	{@cbEdit,[0 obj.Parent.DAQ.MaxStimulusAmplitude(2)]}, ...
    'Value',	Parameters.Amplitude);
Controls.Duration = panel(2).addEdit( ...
    'Label',   	'Duration (s)', ...
    'Callback',	{@cbEdit,[0 100]}, ...
    'Value',	Parameters.Duration);
Controls.PreStimulus = panel(2).addEdit( ...
    'Label',   	'Pre-Stimulus (s)', ...
    'Callback',	{@cbEdit,[1/obj.Parent.Camera.FrameRate 100]}, ...
    'Value',	Parameters.PreStimulus);
Controls.PostStimulus = panel(2).addEdit( ...
    'Label',   	'Post-Stimulus (s)', ...
    'Callback',	{@cbEdit,[0 100]}, ...
    'Value',	Parameters.PostStimulus);
Controls.InterStimulus = panel(2).addEdit( ...
    'Label',   	'Inter-Stimulus (s)', ...
    'Callback',	{@cbEdit,[0 1000]}, ...
    'Value',	Parameters.InterStimulus);
[Controls.okay,Controls.cancel] = window.addOKCancel(...
    'Callback',	@cbOkay);

% edit fields: synchronize Value & String, add Tag
fn = fieldnames(Controls)';
fn = fn(structfun(@(x) strcmp(x.Style,'edit'),Controls));
for f = fn
    Controls.(f{:}).String = sprintf('%g',Controls.(f{:}).Value);
    Controls.(f{:}).Value  = str2double(Controls.(f{:}).String);
    Controls.(f{:}).Tag    = f{:};
end

% save appdata & initialize
cbType(Controls.Type,[])
setappdata(obj.Figure,'controls',Controls);
setappdata(obj.Figure,'parameters',Parameters);
window.Visible = 'on';

% output arguments
if nargout
    varargout{1} = obj.Figure;
end

    function cbType(control,~)
        Parameters.Type = control.String{control.Value};
        switch Parameters.Type
            case 'Sinusoidal'
                Parameters.DutyCycle = 50;
                Parameters.Ramp = NaN;
                Controls.DutyCycle.Enable = 'off';
                Controls.Ramp.Enable = 'off';
            case 'Triangular'
                Parameters.DutyCycle = 50;
                Parameters.Ramp = 100;
                Controls.DutyCycle.Enable = 'off';
                Controls.Ramp.Enable = 'off';
            case 'Square'
                Parameters.DutyCycle = obj.Parameters.DutyCycle;
                Parameters.Ramp = 0;
                Controls.DutyCycle.Enable = 'on';
                Controls.Ramp.Enable = 'on';
        end
        Controls.DutyCycle.String = Parameters.DutyCycle;
        Controls.Ramp.String = Parameters.Ramp;
        updateLocalParameters()
    end

    function cbEdit(control,~,limits)
        value = str2double(control.String);
        if isnan(value)
            value = control.Value;
        else
            value = max(value,limits(1));
            value = min(value,limits(2));
        end
        control.String = sprintf('%g',value);
        control.Value  = str2double(control.String);
        Parameters.(control.Tag) = control.Value;
        updateLocalParameters()
    end

    function updateLocalParameters()
        setappdata(obj.Figure,'parameters',Parameters);
        obj.Parent.plotStimulus(Parameters)
    end

    function cbOkay(~,~,~)
        Parameters = getappdata(obj.Figure,'parameters');
        for Var = fieldnames(Parameters)'
            obj.saveVar(Var{:},Parameters.(Var{:}))
        end
        if ~isequaln(obj.Parameters,Parameters)
            obj.Parameters = Parameters;
        end
        delete(obj.Figure)
    end

    function cbClose(~,~,~)
        if ~isequal(Parameters,obj.Parameters)
            obj.Parent.plotStimulus;
        end
        delete(obj.Figure)
    end

    function cbDelete(~,~,~)
        obj.Parent.h.axes.temporalBg.Visible = 'Off';
    end
end