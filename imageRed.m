classdef imageRed < imageGeneric

    properties (SetAccess = immutable)
        Mode
    end
    
    properties (SetAccess = private)
        Time
        BitDepth
        DeviceProperties
    end
    
    properties (Access = private)
        ROI
    end
    
    methods
        function obj = imageRed(varargin)
            % check arguments
            narginchk(1,1)
            
            % call constructor of superclass
            obj = obj@imageGeneric(varargin{:});
            
            % save mode of Video Input Object "Green"
            obj.Mode = obj.Camera.Input.Red.VideoFormat;
            
            % Create GUI
            obj.Visible = 'on';
        end
    end
    
    methods (Access = protected)
        function createFigure(obj)
            createFigure@imageGeneric(obj)
            colormap(obj.Figure,'gray')
            obj.Figure.Name = 'Red Image';
            obj.ROI = roi_intrinsic(obj.Axes);
        end
    end
    
    methods (Static)
        function obj = saveobj(obj)
            saveobj@imageGeneric(obj)
        end
        
        function obj = loadobj(obj)
            loadobj@imageGeneric(obj)
        end
    end
end