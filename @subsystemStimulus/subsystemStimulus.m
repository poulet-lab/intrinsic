classdef subsystemStimulus < subsystemGeneric

    properties (Constant = true, Access = private)
        toolbox   = ~isempty(ver('IMAQ')) && ...
            license('test','image_acquisition_toolbox');
    end
        
	properties (Constant = true, Access = protected)
        MatPrefix = 'stimulus_'
    end
    
    properties (SetAccess = private, SetObservable, AbortSet)
        Parameters
    end
    
    properties (Access = private, Transient)
        Figure
    end

    methods
        function obj = subsystemStimulus(varargin)
            obj = obj@subsystemGeneric(varargin{:});

            % load stimulus parameters
            p.Type          = obj.loadVar('Type','Sinusoidal');
            p.Frequency     = obj.loadVar('Frequency',10);
            p.DutyCycle    	= obj.loadVar('DutyCycle',50);
            p.Ramp          = obj.loadVar('Ramp',0);
            p.Amplitude   	= obj.loadVar('Amplitude',5);
            p.Duration      = obj.loadVar('Duration',2);
            p.PreStimulus   = obj.loadVar('PreStimulus',5);
            p.PostStimulus  = obj.loadVar('PostStimulus',10);
            p.InterStimulus = obj.loadVar('InterStimulus',20);
            obj.Parameters  = p;
        end
        
        varargout = setup(obj)
        ts = generate(obj,p,fs)
    end
end
