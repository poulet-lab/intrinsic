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
        
        Running    (1,:) logical = false;	% Bool: is an acquisition running right now?
        Unsaved    (1,:) logical = false;	% Bool: is there unsaved data?
        
        IdxResponse = [NaN NaN]
        IdxControl = [NaN NaN]
        IdxBaseline = [NaN NaN]
    end
    
    properties (SetObservable, AbortSet)
        UseControl (1,:) logical = true;	% Bool: are we using the control window?
    end
    
    properties (Dependent, SetObservable, AbortSet)
        WinResponse
        WinControl
        WinBaseline
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

            % Get Parameters from subsystems
            obj.getParameters()
            
            % Default response window
            obj.WinResponse = [1 2];
        end
    end
    
    methods
        function out = get.WinResponse(obj)
            out = obj.idx2time(obj.IdxResponse);
        end

      	function out = get.WinControl(obj)
            out = obj.idx2time(obj.IdxControl);
        end
        
        function out = get.WinBaseline(obj)
            out = obj.idx2time(obj.IdxBaseline);
        end

        function set.WinResponse(obj,in)
            tmp = obj.time2idx(in);
            if obj.UseControl
                obj.IdxControl = obj.time2idx(0) - 1 - (tmp(end) - tmp);
                obj.IdxBaseline = 1:obj.IdxControl(1)-1;
            else
                obj.IdxControl = [];
                obj.IdxBaseline = 1:obj.time2idx(0)-1;
            end
            obj.IdxResponse = tmp;
        end
    end
    
    methods (Access = private)
        checkDirTemp(obj)
        getDataFromCamera(obj)
        getParameters(obj,~,~)
        save2tiff(obj,filename,data,timestamp)
        
        function out = time2idx(obj,in)
            if numel(in) == 1
                tmp = [obj.P.DAQ.tTrigger obj.P.DAQ.tTrigger(end) + ...
                    mode(diff(obj.P.DAQ.tTrigger))];
                [~,out] = min(abs(tmp-in));
            elseif numel(in) == 2
                out = obj.time2idx(in(1)):obj.time2idx(in(2))-1;
            end
        end
        
        function out = idx2time(obj,in)
            if isempty(in) || any(isnan(in))
                out = [NaN NaN];
            else
                out = obj.P.DAQ.tTrigger(in([1 end])) + ...
                    [0 mode(diff(obj.P.DAQ.tTrigger))];
            end
        end
    end

    methods (Access = {?intrinsic})
       clearData(obj,force)
       start(obj,~,~)
       stop(obj,~,~)
    end
end
