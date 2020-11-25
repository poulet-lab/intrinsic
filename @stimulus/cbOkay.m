function obj = cbOkay(obj,~,~)

Controls = getappdata(obj.Figure,'controls');

% apply & save values of edit fields
Variables = {'Type','Frequency', 'DutyCycle', 'Ramp', 'Amplitude', ...
    'Duration', 'PreStimulus', 'PostStimulus', 'InterStimulus'};
for Var = Variables
    switch Controls.(Var{:}).Style
        case 'popupmenu'
            Value = Controls.(Var{:}).String{Controls.(Var{:}).Value};
        otherwise
            Value = str2double(Controls.(Var{:}).String);
    end
    obj.(Var{:}) = Value;
    obj.saveVar(Var{:},Value)
end

% generate stimulus waveform
obj.generate()

% close figure
close(obj.Figure)
