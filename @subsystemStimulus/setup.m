function varargout = setup(obj)
% open GUI to change stimulus settings.

nargoutchk(0,1)

% local copy of object properties
Parameters = struct(obj);

% create settings window & panels
window = settingsWindow(...
    'Name',             'Stimulus Settings', ...
    'Width',            260, ...
    'CloseRequestFcn',  @cbClose);
hFigure = window.Handle;
panel(1)   = window.addPanel('Title','Waveform');
panel(2)   = window.addPanel('Title','Timing');

% create UI controls
Controls.Type = panel(1).addPopupmenu( ...
    'Label',   	'Waveform Type', ...
    'Callback',	@cbType, ...
    'String',  	{'Sinusoidal', 'Triangular', 'Square'});
Controls.Type.Value = max([find(strcmp(Controls.Type.String,Parameters.Type)) 1]);
Controls.Frequency = panel(1).addEdit( ...
    'Label',   	'Frequency (Hz)', ...
    'Callback',	{@cbEdit,[0.01 500]}, ...
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
    'Callback',	{@cbEdit,[2 100]}, ...
    'Value',	Parameters.PostStimulus);
Controls.InterTrial = panel(2).addEdit( ...
    'Label',   	'Inter-Trial (s)', ...
    'Callback',	{@cbEdit,[0 1000]}, ...
    'Value',	Parameters.InterTrial);
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
window.Visible = 'on';

% output arguments
if nargout
    varargout{1} = hFigure;
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
                Parameters.DutyCycle = obj.DutyCycle;
                Parameters.Ramp = 0;
                Controls.DutyCycle.Enable = 'on';
                Controls.Ramp.Enable = 'on';
        end
        Controls.DutyCycle.String = Parameters.DutyCycle;
        Controls.Ramp.String = Parameters.Ramp;
        plotStimulus()
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
        plotStimulus()
    end

    function plotStimulus()
        obj.Parent.plotStimulus(Parameters)
    end

    function cbOkay(~,~,~)
        for Var = fieldnames(Parameters)'
            obj.saveVar(Var{:},Parameters.(Var{:}))
        end
        if ~isequaln(struct(obj),Parameters)
            for Var = fieldnames(Parameters)'
                obj.(Var{:}) = Parameters.(Var{:});
            end
            notify(obj,'Update')
        end
        delete(hFigure)
    end

    function cbClose(~,~,~)
        if ~isequal(Parameters,struct(obj))
            obj.Parent.plotStimulus;
        end
        delete(hFigure)
    end
end
