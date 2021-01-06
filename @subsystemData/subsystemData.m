classdef subsystemData < subsystemGeneric
    
    properties (Constant = true, Access = protected)
        MatPrefix = 'data_'
    end
    
    properties (SetAccess = private)
        n = 0;
        Mean
        Var
    end
    
    properties (Access = private)
        DataType = 'double';
    end
    
    methods
        function obj = subsystemData(varargin)
            obj = obj@subsystemGeneric(varargin{:});
        end
    end
    
    methods (Access = {?intrinsic})
        function clearData(obj)
            obj.Mean = [];
            obj.Var = [];
            obj.n = 0;
        end
    end
    
    methods (Access = {?subsystemCamera})
        function addCameraData(obj,data,metadata)
            if obj.n
                validateattributes(data,{'numeric'},{'size',size(obj.Mean)})
            end
            
            % increment n
            obj.n = obj.n + 1;
            
            
            % save raw data to TIFF
            
            obj.Parent.message('Processing data (trial %d)\n',obj.n)
            data = cast(data,obj.DataType);
            if obj.n == 1
                % Initialize Mean and Var
                obj.Mean = data;
                obj.Var  = zeros(size(data),obj.DataType);
            else
                % Update Mean and Var using Welford's online algorithm
                norm     = obj.n - 1;
                mean0    = obj.Mean;
                obj.Mean = mean0 + (data - mean0) / obj.n;
                obj.Var  = (obj.Var .* (norm-1) + (data-mean0) .* ...
                    (data-obj.Mean)) / norm;
            end
            clear mean0 data
        end
    end
end