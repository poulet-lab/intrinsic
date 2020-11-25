classdef stimulus < handle

    properties (Constant = true, Access = private)
        toolbox   = ~isempty(ver('IMAQ')) && ...
            license('test','image_acquisition_toolbox');
        MatPrefix = 'stimulus_'
    end

    properties (SetAccess = private)
        Type
        Frequency
        DutyCycle
        Ramp
        Amplitude
        Duration
        PreStimulus
        PostStimulus
        InterStimulus
    end
        
    properties (SetAccess = private, SetObservable, AbortSet)
        Timeseries
    end
    
    properties (Access = private)
        Parent
    end

    properties (Access = private, Transient)
        Figure
    end
    
    events
        SettingsUpdated
    end

    methods
        varargout = setup(obj)
        varargout = generate(obj)
        cbOkay(obj,~,~)

        function obj = stimulus(parent)
            validateattributes(parent,{'intrinsic'},{'scalar'});
            obj.Parent = parent;
            
            obj.Type = obj.loadVar('Type','Sinusoidal');
            obj.Frequency = obj.loadVar('Frequency',10);
            obj.DutyCycle = obj.loadVar('DutyCycle',50);
            obj.Ramp = obj.loadVar('Ramp',0);
            obj.Amplitude = obj.loadVar('Amplitude',5);
            obj.Duration = obj.loadVar('Duration',2);
            obj.PreStimulus = obj.loadVar('PreStimulus',5);
            obj.PostStimulus = obj.loadVar('PostStimulus',10);
            obj.InterStimulus = obj.loadVar('InterStimulus',20);
            
            obj.generate()
        end
        
        function set.Type(obj,value)
            validatestring(value,{'Sinusoidal', 'Triangular', 'Square'});
            obj.Type = value;
        end
    end

    methods (Access = private)
        function out = loadVar(obj,var,default)
            out = obj.Parent.loadVar([obj.MatPrefix var],default);
        end

        function saveVar(obj,varName,data)
            obj.Parent.saveVar([obj.MatPrefix varName],data);
        end
    end
end
