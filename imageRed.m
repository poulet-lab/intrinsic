classdef imageRed < imageGeneric

    properties (Access = private)
        CDataControl
        ROI
        ButtonControl
        Minimum
        Snap = false
    end
    
    properties (SetAccess = private, SetObservable, AbortSet)
        TransectResponse = struct('XData',[],'YData',[]);
        TransectControl  = struct('XData',[],'YData',[]);
    end
    
    properties (Dependent, SetObservable, AbortSet)
        Center
        Extent
        Line
    end
    
    events
        NewCenter
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

            obj.Figure.Name = 'Red Image';
            obj.ROI = roi_intrinsic(obj.Axes);
            obj.ROI.Outline.Visible = 'off';

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
                'Horizontal',  	'right');
            editSigma = uicontrol(obj.Toolbar, ...
                'Style',       	'Edit', ...
                'String',     	obj.Parent.Data.Sigma, ...
                'Position',   	[sum(tmp.Position([1 3])) 1 30 20], ...
                'Horizontal', 	'right', ...
                'Callback',    	@obj.cbSigma, ...
                'Tooltip',    	'Width of spatial Gaussian filter');
            tmp = uicontrol(obj.Toolbar, ...
                'Style',       	'Text', ...
                'String',    	'µm', ...
                'Position',    	[sum(editSigma.Position([1 3])) 0 20 18], ...
                'Horizontal',  	'left');
            tmp = uicontrol(obj.Toolbar, ...
                'Style',       	'Text', ...
                'String',    	'Radius:', ...
                'Position',    	[sum(tmp.Position([1 3]))+5 0 40 18], ...
                'Horizontal',  	'right');
            editRadius = uicontrol(obj.Toolbar, ...
                'Style',       	'Edit', ...
                'String',     	50, ...
                'Position',   	[sum(tmp.Position([1 3])) 1 30 20], ...
                'Horizontal', 	'right', ...
                'Callback',    	@obj.cbRadius, ...
                'Tooltip',    	'Radius for Auto-Contrast');
            tmp = uicontrol(obj.Toolbar, ...
                'Style',       	'Text', ...
                'String',    	'µm', ...
                'Position',    	[sum(editRadius.Position([1 3])) 0 20 18], ...
                'Horizontal',  	'left');
            tmp = uicontrol(obj.Toolbar, ...
                'Style',       	'Text', ...
                'String',    	'Minimum:', ...
                'Position',    	[sum(tmp.Position([1 3]))+5 0 45 18], ...
                'Horizontal',  	'right');
            editMinimum = uicontrol(obj.Toolbar, ...
                'Style',       	'Edit', ...
                'String',     	obj.Minimum, ...
                'Position',   	[sum(tmp.Position([1 3])) 1 30 20], ...
                'Horizontal', 	'right', ...
                'Callback',    	@cbMinimum, ...
                'Tooltip',    	'Minimum Color Scale');
            tmp = uicontrol(obj.Toolbar, ...
                'Style',       	'Text', ...
                'String',    	'%', ...
                'Position',    	[sum(editMinimum.Position([1 3])) 0 20 18], ...
                'Horizontal',  	'left');
            uicontrol(obj.Toolbar, ...
                'Style',        'checkbox', ...
                'String',       'Snap to peaks', ...
                'Value',        obj.Snap, ...
                'Callback',     @cbSnap, ...
                'Position',    	[sum(tmp.Position([1 3])) 1 85 20])

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
            
            % run some callbacks
            obj.cbSigma(editSigma);
            obj.cbRadius(editRadius);
            
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
            	elseif isa(cObj,'matlab.graphics.primitive.Image')
                    if strcmp(obj.Figure.SelectionType,'normal')
                        obj.Center = obj.Axes.CurrentPoint(2,1:2);
                    elseif strcmp(obj.Figure.SelectionType,'alt')
                        obj.Extent = obj.Axes.CurrentPoint(2,1:2); 
                    end
                end
            end
            
            function cbMinimum(ctrl,~)
                value = str2double(ctrl.String);
                if isempty(value) || value<=0 || isnan(value)
                    value        = 0;
                end
                ctrl.String = sprintf('%0.5g',value);
                value = str2double(ctrl.String);
                obj.Minimum = value;
                obj.cbUpdateROI()
            end
            
           	function cbSnap(ctrl,~)
                obj.Snap = ctrl.Value;
                if obj.Snap
                    obj.cbUpdateROIcenter()
                end
            end
        end
        
        function cbUpdateROI(obj,~,~)
            % Possible short-cuts
            if ~obj.Parent.Data.nTrials
                obj.TransectControl  = struct('XData',[],'YData',[]);
                obj.TransectResponse = struct('XData',[],'YData',[]);
                return
            end
            if ~obj.Visible
                return
            end
            
            % Response
            [xi,yi,yResponse] = improfile(obj.Parent.Data.DFF,...
                obj.ROI.Line.XData,obj.ROI.Line.YData,'nearest');
            xResponse = sqrt((xi-obj.ROI.Center.Position(1)).^2+ ...
                (yi-obj.ROI.Center.Position(2)).^2);
            tmp = 1:floor(length(xResponse)/2);
            xResponse(tmp) = -xResponse(tmp);
            xResponse = xResponse / (obj.Scale.PxPerCm / 1E4);

            % Control
            if ~isempty(obj.Parent.Data.DFFcontrol)
                [~,~,yControl] = improfile(obj.Parent.Data.DFFcontrol,...
                    obj.ROI.Line.XData,obj.ROI.Line.YData,'nearest');
                obj.TransectControl.XData = xResponse;
                obj.TransectControl.YData = yControl;
            end
            
            % CLim
            tmp = double.empty;
            if obj.ROI.Radius
                tmp = reshape(obj.CData(obj.ROI.mask(obj.Size)),[],1);
            end
            if isempty(tmp)
                tmp = yResponse(isfinite(yResponse));
            end
            obj.CLim = max([obj.Minimum; abs(tmp)]) * [-1 1];
            
            % Set object properties (at the very end - for listeners)
            obj.TransectResponse.XData = xResponse;
            obj.TransectResponse.YData = yResponse;
        end
        
        function cbUpdateROIcenter(obj,~,~)
            if obj.Snap
                [row,col,~] = find(imregionalmax(abs(obj.Parent.Data.DFF),8));
                [~,idx] = min(sqrt(power(col - obj.ROI.Center.Position(1),2) + ...
                    power(row - obj.ROI.Center.Position(2),2)));
                obj.ROI.Center.Position = [col(idx) row(idx)];
                obj.ROI.translate();
            end
            
            obj.Parent.Data.Point = round(obj.ROI.coordsCenter);
            notify(obj,'NewCenter')
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
        
        function cbRadius(obj,ctrl,~)
            value = str2double(ctrl.String);
            if isempty(value) || value<=0 || isnan(value)
                value        = 0;
            end
            ctrl.String = sprintf('%0.5g',value);
            value = str2double(ctrl.String);
            obj.ROI.Radius = value * (obj.Scale.PxPerCm/1E4);
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
    
    methods
        function savePNG(obj,fn)
            obj.ROI.Outline.Visible = 'off';
            obj.ROI.Extent.Visible  = 'off';
            savePNG@imageGeneric(obj,fn)
        end
        
        function set.Center(obj,in)
            obj.ROI.coordsCenter = in;
            notify(obj,'NewCenter')
            obj.cbUpdateROIcenter
        end
        
        function out = get.Center(obj)
            out = obj.ROI.coordsCenter;
        end
        
        function set.Extent(obj,in)
            obj.ROI.Extent.Position = in;
            obj.ROI.reshape()
        end
        
        function out = get.Extent(obj)
            out = obj.ROI.Extent.Position;
        end
        
        function out = get.Line(obj)
            out.XData = obj.ROI.coordsLine(:,1);
            out.YData = obj.ROI.coordsLine(:,2);
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