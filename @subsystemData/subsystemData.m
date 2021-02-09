classdef subsystemData < subsystemGeneric

    properties (Constant = true, Access = protected)
        MatPrefix = 'data_'
        DataType = 'double'
        MATLAB = version('-release')
    end

    properties (GetAccess = private, SetAccess = immutable, Transient)
        DirTemp
        HostName
    end

    properties (Access = private, SetObservable, Transient, NonCopyable)
        DataMean
        DataVar
        
        DataMeanBaseline
        DataMeanControl
        DataMeanResponse
    end
    
    properties (SetAccess = private, SetObservable, Transient, NonCopyable)
        DFF
        DFFcontrol
    end
    
    properties (SetAccess = private, SetObservable, AbortSet)
        nTrials (1,:) = 0;
        Trials
        
        Running (1,:) logical = false;	% Bool: is an acquisition running right now?
        Unsaved (1,:) logical = false;	% Bool: is there unsaved data?
        
        IdxResponse = [NaN NaN]
        IdxControl  = [NaN NaN]
        IdxBaseline = [NaN NaN]
    end
    
    properties (SetAccess = {?imageRed}, SetObservable, AbortSet)
        Sigma = 0
        Point
    end
    
    properties (Access = private)
        SigmaPx = 0
    end
    
    properties (SetObservable, AbortSet)
        UseControl (1,:) logical = true;	% Bool: are we using the control window?
    end
    
    properties (Dependent, SetObservable, AbortSet)
        WinResponse
        WinControl
        WinBaseline
    end

    events
        UpdatedIndices
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

            % Set HostName
            if ispc
                obj.HostName = strtrim(getenv('COMPUTERNAME'));
            else
                obj.HostName = strtrim(getenv('HOSTNAME'));
            end
            
            % Create listeners
            addlistener(obj.Parent.Stimulus,'Update',@obj.getParameters);
            addlistener(obj.Parent.Camera,'Update',@obj.getParameters);
            addlistener(obj.Parent.DAQ,'Update',@obj.getParameters);
            %addlistener(obj.Parent.Red,'Update',@obj.updateROI);
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
            
            % Check if the object's actual properties need updating
            fns = {'IdxBaseline','IdxControl','IdxResponse'};
            upd = cellfun(@(x) ~isequal(Local.(x),obj.(x)),fns);
            for fn = fns(upd)
                obj.(fn{:}) = Local.(fn{:});
                obj.calculateWinMeans(fn{:});
            end
            
            % Fire notifier / run dependencies
            if any(upd)
                notify(obj,'UpdatedIndices')
                obj.calculateDFF()
            end
        end
        
        function set.Sigma(obj,in)
            obj.Sigma = in;
            obj.calculateDFF();
            obj.calculateTemporal()
        end
    end

    methods (Access = {?intrinsic})
        out = forceWinResponse(obj,in)
    end

    methods (Access = {?intrinsic})
        saveData(obj)
        loadData(obj)
    end
    
    methods (Access = private)
        checkDirTemp(obj)
        getDataFromCamera(obj)
        getParameters(obj,~,~)
        save2tiff(obj,filename,data,timestamp)
        
        function out = time2idx(obj,in)
            if numel(in) == 1
                tmp = [obj.P.DAQ.tFrameTrigger obj.P.DAQ.tFrameTrigger(end) + ...
                    mode(diff(obj.P.DAQ.tFrameTrigger))];
                [~,out] = min(abs(tmp-in));
            elseif numel(in) == 2
                out = obj.time2idx(in(1)):obj.time2idx(in(2))-1;
            end
        end
        
        function out = idx2time(obj,in)
            if isempty(in) || any(isnan(in))
                out = [NaN NaN];
            else
                out = obj.P.DAQ.tFrameTrigger(in([1 end])) + ...
                    [0 mode(diff(obj.P.DAQ.tFrameTrigger))];
            end
        end
        
        function calculateWinMeans(obj,winName)
            if ~obj.nTrials
                return
            end
            
            calculateAll = ~exist('winName','var');
            function calculateVal(idxName,propName)
                if calculateAll || isempty(obj.(propName)) || strcmp(winName,idxName)
                    obj.(propName) = ...
                        mean(obj.DataMean(:,:,1,obj.(idxName)),4);
                end
            end
            
            calculateVal('IdxBaseline','DataMeanBaseline')
            calculateVal('IdxControl', 'DataMeanControl')
            calculateVal('IdxResponse','DataMeanResponse')

            % TODO: Calculate Variances
            
            if calculateAll
                obj.calculateDFF();
            end
        end
        
        function calculateDFF(obj)
            if ~obj.nTrials
                return
            end
            
            % Calculate ΔF/F
            control  = (obj.DataMeanControl - obj.DataMeanBaseline) ./ ...
                obj.DataMeanBaseline .* 100;
            response = (obj.DataMeanResponse - obj.DataMeanBaseline) ./ ...
                obj.DataMeanBaseline .* 100;
            
            % Apply Gaussian filter
            if obj.Sigma
                control  = imgaussfilt(control,obj.Sigma);
                response = imgaussfilt(response,obj.Sigma);
            end
            
            % Set object properties
            obj.DFFcontrol = control;
            obj.DFF = response;
        end
    end
    
    methods (Access = {?imageRed})
        function calculateTemporal(obj)
                        
            % We can take a shortcut if no XY-position is selected
            if isempty(obj.Point) || any(isnan(obj.Point))
                return
            end
            
            % obtain sub-volume & center coordinates
            % Perhaps a bit cumbersome, this section ensures correct
            % sub-volumes even for XY-positions close to the border.

            tmp     = ceil(2*obj.Sigma);
            c1      = obj.Point(2)+(-tmp:tmp); 	% row indices of sub-volume
            c2      = obj.Point(1)+(-tmp:tmp); 	% col indices of sub-volume

            sz      = size(obj.DataMean);
            b1      = ismember(c1,1:sz(1));  	% bool: valid row indices
            b2      = ismember(c2,1:sz(2));   	% bool: valid col indices

            mask    = false(2*tmp+1,2*tmp+1);   % preallocate logical mask
            mask(tmp+1,tmp+1) = true;           % logical: X/Y center
            mask    = mask(b1,b2);              % trim mask to valid values
            [c3,c4] = find(mask);               % indices of X/Y center

            c1      = c1(b1);                 	% keep valid row indices
            c2      = c2(b2);                 	% keep valid col indices

            subVol  = (obj.DataMean(c1,c2,:) - obj.DataMeanBaseline(c1,c2)) ...
                ./ obj.DataMeanBaseline(c1,c2);

            % 2D Gaussian filtering of the sub-volume's 1st two dimensions
            if obj.Sigma > 0
                subVol = imgaussfilt(subVol,obj.Sigma);
            end

            % define X and Y values for temporal plot
            obj.Parent.h.plot.temporal.XData = obj.P.DAQ.tFrameTrigger;
            obj.Parent.h.plot.temporal.YData = squeeze(subVol(c3,c4,:)) * 100;            
        end
    end

    methods (Access = {?intrinsic})
       clearData(obj,force)
       start(obj,~,~)
       stop(obj,~,~)
    end
end
