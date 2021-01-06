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
            obj.updateCrossSection;

            % Listeners
            addlistener(obj,'CData','PostSet',@obj.updateCrossSection);
            addlistener(obj.ROI,'Update',@obj.updateCrossSection);
            
            % JUST FOR TESTING
            tmp = double(imread('test.jpg'));
            tmp = tmp(:,:,1);
            tmp = tmp - median(tmp(:));
            obj.CData = tmp;
        end
    end
    
    methods (Access = protected)
        function createFigure(obj)
            createFigure@imageGeneric(obj)
            colormap(obj.Figure,'gray')
            obj.Figure.Name = 'Red Image';
            obj.ROI = roi_intrinsic(obj.Axes);
            obj.ROI.Outline.Visible = 'off';
            
            % pointer manager for ROI visibility
            pb.enterFcn = @pointerEnter;
            pb.exitFcn  = @pointerExit;
            pb.traverseFcn = [];
            iptSetPointerBehavior(obj.Axes,pb);
            iptPointerManager(obj.Figure,'enable')
            
            function pointerEnter(~,~)
                obj.ROI.Outline.Visible = 'on';
                %obj.ROI.Outline.EdgeAlpha = 1;
                obj.ROI.Extent.Visible  = 'on';
            end
            function pointerExit(~,~)
                obj.ROI.Outline.Visible = 'off';
                %obj.ROI.Outline.EdgeAlpha = 0.2;
                obj.ROI.Extent.Visible  = 'off';
            end
        end
        
        function updateCrossSection(obj,~,~)
            [xi,yi,y] = improfile(obj.CData,...
                obj.ROI.Line.XData,obj.ROI.Line.YData,'nearest');
            x         = sqrt((xi-obj.ROI.Center.Position(1)).^2+ ...
                (yi-obj.ROI.Center.Position(2)).^2);
            tmp       = 1:floor(length(x)/2);
            x(tmp)    = -x(tmp);
            x         = x / obj.Scale.PxPerCm;
            obj.Parent.h.plot.spatialAverage.XData = x;
            obj.Parent.h.plot.spatialAverage.YData = y;
            obj.Parent.h.axes.spatial.XLim = x([1 end]);
            
            mask = obj.ROI.mask(obj.Size);
            obj.CLim = [min(obj.CData(mask(:))) max(obj.CData(mask(:)))];
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