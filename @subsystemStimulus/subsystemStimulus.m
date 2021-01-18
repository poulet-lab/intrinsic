classdef subsystemStimulus < subsystemGeneric
        
	properties (Constant = true, Access = protected)
        MatPrefix = 'stimulus_'
    end
    
    properties (SetAccess = private, SetObservable, AbortSet)
        Type
        Frequency
        DutyCycle
        Ramp
        Amplitude
        Duration
        PreStimulus
        PostStimulus
        InterTrial
    end

    methods
        function obj = subsystemStimulus(varargin)
            obj = obj@subsystemGeneric(varargin{:});

            % Load stimulus parameters
            obj.Type         = obj.loadVar('Type','Sinusoidal');
            obj.Frequency	 = obj.loadVar('Frequency',10);
            obj.DutyCycle 	 = obj.loadVar('DutyCycle',50);
            obj.Ramp    	 = obj.loadVar('Ramp',0);
            obj.Amplitude 	 = obj.loadVar('Amplitude',5);
            obj.Duration 	 = obj.loadVar('Duration',2);
            obj.PreStimulus	 = obj.loadVar('PreStimulus',5);
            obj.PostStimulus = obj.loadVar('PostStimulus',10);
            obj.InterTrial	 = obj.loadVar('InterTrial',20);
        end
        
        varargout = setup(obj)
        ts = generate(obj,p,fs)
    end
end
