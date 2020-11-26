classdef stimulus < handle

    properties (Constant = true, Access = private)
        toolbox   = ~isempty(ver('IMAQ')) && ...
            license('test','image_acquisition_toolbox');
        MatPrefix = 'stimulus_'
    end
        
    properties (SetAccess = private, SetObservable, AbortSet)
        Parameters
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
        varargout = generate(obj,p)

        function obj = stimulus(parent)
            validateattributes(parent,{'intrinsic'},{'scalar'});
            obj.Parent = parent;

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
