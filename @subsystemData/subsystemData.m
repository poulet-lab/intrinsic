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
        
        DataMeanBaseline
        DataMeanControl
        DataMeanResponse
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
            %addlistener(obj,'UseControl','PostSet',@updatedUseControl);

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
            
            % Define new window indices locally
            Local.IdxResponse = obj.time2idx(obj.forceWinResponse(in));
            if obj.UseControl
                Local.IdxControl  = obj.time2idx(0) - ...
                    (Local.IdxResponse(end) - Local.IdxResponse) - 1;
                Local.IdxBaseline = 1:Local.IdxControl(1)-1;
            else
                Local.IdxControl  = [];
                Local.IdxBaseline = 1:obj.time2idx(0)-1;
            end
            
            % Check if object properties need updating
            fns = {'IdxBaseline','IdxControl','IdxResponse'};
            upd = cellfun(@(x) ~isequal(Local.(x),obj.(x)),fns);
            for fn = fns(upd)
                obj.(fn{:}) = Local.(fn{:});
                obj.calculateWinMeans(fn{:});
            end
            
            % Call 
        end
    end

    methods (Access = {?intrinsic})
        new = forceWinResponse(obj,new)
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
        
        function calculateWinMeans(obj,winName)
            if ~obj.nTrials
                return
            end
            
            calculateAll = ~exist('winName','var');
            function calculateVal(idxName,propName)
                if calculateAll || strcmp(winName,idxName)
                    obj.(propName) = ...
                        mean(obj.DataMean(:,:,1,obj.(idxName)),4);
                end
            end
            
            calculateVal('IdxBaseline','DataMeanBaseline')
            calculateVal('IdxControl', 'DataMeanControl')
            calculateVal('IdxResponse','DataMeanResponse')

            % TODO: Calculate Variances
            
%             % obtain the average response (time res., baseline substracted)
%             obj.SequenceRaw  = stack - base;
%             obj.ImageRedBase = base;
%             obj.ImageRedStim = stim;
%             disp(src.Name)
        end
    end

    methods (Access = {?intrinsic})
       clearData(obj,force)
       start(obj,~,~)
       stop(obj,~,~)
    end
end
