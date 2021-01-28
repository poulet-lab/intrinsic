classdef imageRed < imageGeneric

    properties (Access = private)
        CDataControl
        ROI
        ButtonControl
        EditSigma
    end

    methods
        function obj = imageRed(varargin)

            % Call constructor of superclass
            obj = obj@imageGeneric(varargin{:});
                        
            % Listeners
            addlistener(obj.Parent.Data,'DFF','PostSet',@obj.updateCData);
        end
    end
    
    methods (Access = protected)
        function createFigure(obj)
            obj.Scale = copy(obj.Scale);
            obj.Scale.UseBinning = true;
            
            createFigure@imageGeneric(obj)
            colormap(obj.Figure,flipud(brewermap(256,'PuOr')))
            
            obj.ButtonControl = uicontrol(obj.Toolbar, ...
                'Style',        'togglebutton', ...
                'Value',        0, ...
                'Position',     [0 1 50 21], ...
                'String',       'Control', ...
                'Tag',          'toggleControl', ...
                'Enable',       'inactive', ...
                'Tooltip',     	'Toggle control window');
            tmp = uicontrol(obj.Toolbar, ...
                'Style',       	'Text', ...
                'String',    	'Sigma:', ...
                'Position',    	[sum(obj.ButtonControl.Position([1 3]))+10 0 35 18], ...
                'Horizontal',  	'left');
            obj.EditSigma = uicontrol(obj.Toolbar, ...
                'Style',       	'Edit', ...
                'String',     	'0', ...
                'Position',   	[sum(tmp.Position([1 3])) 1 30 20], ...
                'Horizontal', 	'right', ...
                'Callback',    	@obj.cbSigma, ...
                'Tooltip',    	'Width of spatial Gaussian filter');
            uicontrol(obj.Toolbar, ...
                'Style',       	'Text', ...
                'String',    	'µm', ...
                'Position',    	[sum(obj.EditSigma.Position([1 3])) 0 20 18], ...
                'Horizontal',  	'left');
            
            obj.Figure.Name = 'Red Image';
            obj.ROI = roi_intrinsic(obj.Axes);
            obj.ROI.Outline.Visible = 'off';
            
            addlistener(obj.ROI,'Update',@obj.cbUpdateROI);
            addlistener(obj.ROI,'UpdateCenter',@obj.cbUpdateROIcenter);
            
            % pointer manager for ROI visibility
            pb.enterFcn = @pointerEnter;
            pb.exitFcn  = @pointerExit;
            pb.traverseFcn = [];
            iptSetPointerBehavior(obj.Axes,pb);
            iptPointerManager(obj.Figure,'enable')
            
            % mouse up/down for control toggle
            obj.Figure.WindowButtonDownFcn = @mouseDown;
            obj.Figure.WindowButtonUpFcn = @mouseUp;
            
            function pointerEnter(~,~)
                obj.ROI.Outline.Visible = 'on';
                obj.ROI.Extent.Visible  = 'on';
            end
            function pointerExit(~,~)
                obj.ROI.Outline.Visible = 'off';
                obj.ROI.Extent.Visible  = 'off';
            end
            function mouseDown(~,~)
                cObj = obj.Figure.CurrentObject;
                if isa(cObj,'matlab.ui.control.UIControl') && ...
                    strcmp(cObj.Style,'togglebutton') && ...
                    strcmp(cObj.Tag,'toggleControl')
                    
                    cObj.Value = 1;
                    obj.CData  = obj.Parent.Data.DFFcontrol;
                end
                
            end
            function mouseUp(~,~)
                cObj = obj.Figure.CurrentObject;
                if isa(cObj,'matlab.ui.control.UIControl') && ...
                    strcmp(cObj.Style,'togglebutton') && ...
                    strcmp(cObj.Tag,'toggleControl')
                
                    cObj.Value = 0;
                    obj.CData  = obj.Parent.Data.DFF;
                end
            end
        end
        
        function cbUpdateROI(obj,~,~)
            if ~obj.Parent.Data.nTrials
                obj.Parent.h.plot.spatialAverage.XData = [];
                obj.Parent.h.plot.spatialAverage.YData = [];
                obj.Parent.h.plot.spatialControl.XData = [];
                obj.Parent.h.plot.spatialControl.YData = [];
                obj.Parent.h.axes.spatial.YLim = [-1 1];
                return
            end
            if ~obj.Visible
                return
            end
            
            [xi,yi,y] = improfile(obj.Parent.Data.DFF,...
                obj.ROI.Line.XData,obj.ROI.Line.YData,'nearest');
            x         = sqrt((xi-obj.ROI.Center.Position(1)).^2+ ...
                (yi-obj.ROI.Center.Position(2)).^2);
            tmp       = 1:floor(length(x)/2);
            x(tmp)    = -x(tmp);
            x         = x / obj.Scale.PxPerCm;
            obj.Parent.h.plot.spatialAverage.XData = x;
            obj.Parent.h.plot.spatialAverage.YData = y;

            tmp = obj.CData(obj.ROI.mask(obj.Size));
            obj.CLim = max(abs(tmp(isfinite(tmp)))) * [-1 1];
            obj.Parent.h.image.colorbar.YData = linspace(obj.CLim(1),obj.CLim(2),256);

            obj.Parent.h.axes.spatial.XLim = x([1 end]);
            if any(diff(y(:)))
                obj.Parent.h.axes.spatial.YLim = [min(y) max(y)];
            else
                obj.Parent.h.axes.spatial.YLim = [-1 1];
            end
            
            if ~isempty(obj.Parent.Data.DFFcontrol)
                [~,~,y] = improfile(obj.Parent.Data.DFFcontrol,...
                    obj.ROI.Line.XData,obj.ROI.Line.YData,'nearest');
                obj.Parent.h.plot.spatialControl.XData = x;
                obj.Parent.h.plot.spatialControl.YData = y;
            end
        end
        
        function cbUpdateROIcenter(obj,~,~)
            obj.Parent.Data.Point = round(obj.ROI.coordsCenter);
            obj.Parent.Data.calculateTemporal()
        end
        
        function cbSigma(obj,ctrl,~)
            value = str2double(ctrl.String);
            if isempty(value) || value<=0 || isnan(value)
                value        = 0;
            end
            ctrl.String  = sprintf('%0.5g',value);
            value = str2double(ctrl.String);
            obj.Parent.Data.Sigma = value * (obj.Scale.PxPerCm/1E4);
        end

        function updateCData(obj,~,~)
            if ~obj.Parent.Data.nTrials
                obj.Visible = false;
                obj.CData = nan(size(obj.CData));
                obj.cbUpdateROI();
            else
                obj.CData = obj.Parent.Data.DFF;
                obj.Visible = true;
                obj.cbUpdateROI();
                obj.focus();
            end
        end
    end

    methods (Access = {?subsystemData})
        function setCData(obj,in1,in2)
            obj.CData = in1;
            if nargin == 3
                obj.CDataControl = in2;
            end
        end
        
        function setScale(obj)
            obj.Scale = copy(obj.Parent.Scale);
            obj.Scale.UseBinning = true;
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