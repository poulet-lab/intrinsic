classdef subsystemData < subsystemGeneric

    properties (Constant = true, Access = protected)
        MatPrefix = 'data_'
        DataType = 'double'
    end

    properties (GetAccess = private, SetAccess = immutable, Transient)
        DirTemp
    end

    properties (SetAccess = private, SetObservable, Transient, NonCopyable)
        DataMean
        DataVar
        
        Baseline
        Control
        Stimulus
    end
    
    properties (SetAccess = private, SetObservable, AbortSet)
        nTrials (1,:) = 0;
        Trials
        
        WinBaseline = [NaN NaN];
        WinControl  = [NaN NaN];
        WinStimulus = [NaN NaN];
        
        IdxBaseline = [NaN NaN];
        IdxControl  = [NaN NaN];
        IdxStimulus = [NaN NaN];
        
        Running (1,:) logical = false;    % Bool: is an acquisition running right now?
        Unsaved (1,:) logical = false;    % Bool: is there unsaved data?
    end

    properties %(Access = private)
        P
    end

    methods
        function obj = subsystemData(varargin)
            obj = obj@subsystemGeneric(varargin{:});

            % Set directory for temporary data
            obj.DirTemp = fullfile(obj.Parent.DirBase,'tempdata');
            if ~exist(obj.DirTemp,'dir')
                mkdir(obj.DirTemp)
            end

            % Create listeners
            addlistener(obj.Parent.Stimulus,'Update',@obj.getParameters);
            addlistener(obj.Parent.Camera,'Update',@obj.getParameters);
            addlistener(obj.Parent.DAQ,'Update',@obj.getParameters);

            obj.getParameters()
        end
    end
    
    methods (Access = private)
        checkDirTemp(obj)
        getDataFromCamera(obj)
        getParameters(obj,~,~)
        save2tiff(obj,filename,data,timestamp)
    end

    methods (Access = {?intrinsic})
       clearData(obj,force)
       start(obj,~,~)
       stop(obj,~,~)
    end
end
