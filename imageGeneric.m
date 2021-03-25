classdef imageGeneric < handle
   
    properties (Transient, Access = protected, SetObservable)
        CData
    end

    properties (Transient, SetAccess = immutable, GetAccess = protected)
        Camera
    end
    
    properties (SetAccess = immutable)
        Adaptor
        DeviceName
    end
    
    properties (Transient, Access = protected)
        Figure
    end
    
    properties (SetAccess = protected)
        Size = [512 512]
    end
    
    properties (Transient, Access = private)
        PanelAxes
        PanelZoom
        BottomPx = 22
        EditZoom
        LabelZoom
    end
    
    properties (Transient, Access = protected)
        Parent
        Toolbar
        Axes
        Image
        MarginPx = 6
        Scalebar
    end
    
    properties (Dependent, SetObservable)
        Position
        Visible
        Zoom
        CLim
    end
    
    properties (Access = private)
        PrivatePosition = [100 100 200 200]
        PrivateVisible  = 'off'
        PrivateZoom     = 1
        ScaleListener
        CDataListener
    end
    
    properties (Access = protected)
        Scale (1,:) subsystemScale
    end
    
    methods
        
        function obj = imageGeneric(parent)
            % validate input arguments
            validateattributes(parent,{'intrinsic'},{'scalar'});

            obj.Parent          = parent;
            obj.Scale           = parent.Scale;
            obj.Camera          = parent.Camera;
%             obj.Adaptor         = parent.Camera.Adaptor;
%             obj.DeviceName      = parent.Camera.DeviceName;
            
            obj.ScaleListener = ...
                addlistener(parent.Scale,'Update',@obj.scaleChanged);
            obj.CDataListener = ...
                addlistener(obj,'CData','PostSet',@obj.scaleChanged);
            
            obj.dummyCData;
        end

        function delete(obj)
            if ishandle(obj.Figure)
                delete(obj.Figure)
            end
            delete(obj)
        end
        
        function set.CData(obj,value)
            obj.CData = value(:,:,1);
            obj.Size  = fliplr(size(obj.CData));
            if ~isempty(obj.Image) && isvalid(obj.Image)
                obj.Image.CData = obj.CData;
                obj.resizeFigure();
            end
        end

        function value = get.CLim(obj)
            value = obj.Axes.CLim;
        end
        
        function value = get.Position(obj)
            if ~isempty(obj.Figure) && isvalid(obj.Figure)
                value = obj.Figure.Position;
                obj.PrivatePosition = value;
            else
                value = obj.PrivatePosition;
            end
        end
        
        function value = get.Visible(obj)
            value = obj.PrivateVisible;
        end
        
        function value = get.Zoom(obj)
            value = obj.PrivateZoom;
        end
        
        function set.CLim(obj,value)
            if ~diff(value)
                value = value(1) + [-1 1];
            end
            obj.Axes.CLim = value;
        end
        
        function set.Position(obj,value)
            validateattributes(value,{'numeric'},{'row','numel',4,...
                'positive','real','finite'},mfilename,'Position')
            if ~isempty(obj.Figure) && isvalid(obj.Figure)
                obj.Figure.Position(1:2) = value(1:2);
                obj.PrivatePosition = obj.Figure.Position;
            else
                obj.PrivatePosition(1:2) = value(1:2);
            end
        end
        
        function set.Visible(obj,value)
            value = matlab.lang.OnOffSwitchState(value);
            if (isempty(obj.Figure) || ~isvalid(obj.Figure)) && strcmp(value,'on')
                obj.createFigure()
            end
            if ~(isempty(obj.Figure) || ~isvalid(obj.Figure))
                set(obj.Figure,'Visible',value);
                obj.Zoom = obj.Zoom;
            end
            obj.PrivateVisible = value;
        end
        
        function out = RGB(obj)
            cmap = obj.Figure.Colormap;
            clim = obj.CLim;
            out  = obj.CData;
            out  = round((out-clim(1)) ./ (diff(clim)/(size(cmap,1)-1)));
            out(out<0) = 0;
            out(out>(size(cmap,1)-1)) = (size(cmap,1)-1);
            out  = ind2rgb(out,cmap);
        end
        
        function savePNG(obj,fn)
            F = getframe(obj.Axes);
            imwrite(F.cdata,fn,'png')
        end
        
        function set.Zoom(obj,value)
            % calculate limits of zoom value
            upper = get(0,'ScreenSize');
            upper = upper(3:4) - [0 80];
            lower = [400 400];
            calc  = @(size) min((size - 4 - 2*obj.MarginPx - ...
                [0 1] * (obj.MarginPx + obj.BottomPx)) ./ obj.Size(1:2));
            
            % enforce limits
            value = min([value floor(calc(upper)*100)/100]);
            value = max([value ceil(calc(lower)*100)/100]);
            
            % take shortcut
            if isequal(obj.PrivateZoom,value)
                return
            end
            
            obj.PrivateZoom = value;
            if ~isempty(obj.EditZoom) && isvalid(obj.EditZoom)
                obj.EditZoom.String = sprintf('%d%%',round(value*100));
                obj.resizeFigure()
            end
        end
        
        function focus(obj)
            obj.Visible = 'on';
            figure(obj.Figure)
        end
    end
    
    methods (Access = protected)
        function createFigure(obj)
           	obj.Figure = figure(...
                'Visible',          obj.Visible, ...
                'Toolbar',          'none', ...
                'Menu',             'none', ...
                'NumberTitle',      'off', ...
                'Resize',           'off', ...
                'Position',         obj.Position, ...
                'HandleVisibility', 'off', ...
                'DockControls',     'off', ...
                'CloseRequestFcn',  @obj.closeFigure);
            obj.PanelAxes = uipanel(obj.Figure, ...
                'Units',            'Pixels', ...
                'BorderType',       'beveledin', ...
                'HandleVisibility', 'off');
            obj.Axes = axes(obj.PanelAxes,...
                'DataAspectRatio',  [1 1 1], ...
                'Position',         [0 0 1 1], ...
                'Visible',          'off', ...
                'HandleVisibility', 'off', ...
                'YDir',             'reverse', ...
                'View',             [0 90]);
            obj.Image = image(obj.Axes,...
                'CData',            obj.CData, ...
                'CDataMapping',     'scaled');
            obj.PanelZoom = uipanel(obj.Figure, ...
                'Units',            'pixels', ...
                'Position',         [1 1 70 obj.BottomPx], ...
                'BorderType',       'none');
            obj.LabelZoom = uicontrol(obj.PanelZoom, ...
                'Style',                'text', ...
                'String',               'Zoom: ', ...
                'Position',             [1 1 35 17], ...
                'HorizontalAlignment',  'right');
            obj.EditZoom = uicontrol(obj.PanelZoom, ...
                'Style',            'edit', ...
                'String',           sprintf('%d%%',round(obj.Zoom*100)),...
                'Callback',         @obj.callbackEditZoom, ...
                'Position',         [obj.PanelZoom.Position(3)-34 1 35 20]);
            obj.Toolbar = uipanel(obj.Figure, ...
                'Units',            'Pixels', ...
                'BorderType',       'none');
            obj.resizeFigure()
            obj.Scalebar = scalebar(obj.Axes,obj.Scale.PxPerCm);
        end
        
        function callbackEditZoom(obj,hCtrl,~)
            value = str2double(regexp(hCtrl.String,...
                '^ *([\d\.]*)(?: %|%)? *$','tokens','once')) / 100;
            if ~isempty(value)
                obj.Zoom = value;
            end
            hCtrl.String = sprintf('%d%%',round(obj.Zoom*100));
        end
        
        function scaleChanged(obj,~,~)
            obj.Scalebar.Scale = obj.Scale.PxPerCm;
        end
    end
       
    methods (Access = private)
        function resizeFigure(obj,varargin)
            panelSize  = obj.Size(1:2) .* obj.Zoom + 4;
            figureSize = panelSize + 2*obj.MarginPx + ...
                [0 1] * (obj.MarginPx+obj.BottomPx);
            panelPos   = [obj.MarginPx+1 ...
                figureSize(2)-panelSize(2)-obj.MarginPx];
            obj.Figure.Position(3:4) = figureSize;
            obj.PanelAxes.Position = [panelPos panelSize];
            obj.PanelZoom.Position(1:2) = [obj.Figure.Position(3)-...
                obj.PanelZoom.Position(3)-obj.MarginPx obj.MarginPx];
            obj.Toolbar.Position = [obj.MarginPx+1 obj.MarginPx...
                figureSize(1)-(3*obj.MarginPx)-obj.PanelZoom.Position(3)...
                obj.BottomPx];
            obj.Axes.XLim = [0.5 obj.Size(1)+0.5];
            obj.Axes.YLim = [0.5 obj.Size(2)+0.5];
            movegui(obj.Figure,'onscreen')
        end
        
        function closeFigure(obj,~,~)
            obj.Visible = 'off';
            obj.PrivatePosition = obj.Position;
        end
        
        function dummyCData(obj)
            % create dummy CData indicating that data has not been loaded
            tmp       = checkerboard(max(ceil(obj.Size(1:2)/8)));
            tmp       = tmp(1:obj.Size(1),1:obj.Size(2)) > .5;
            obj.CData = tmp + randn(size(tmp));
        end
    end
    
    methods (Static)
        function obj = saveobj(obj)
            obj.PrivatePosition = obj.Position;
        end
        
        function obj = loadobj(obj)
            obj.dummyCData;
            obj.Visible = obj.PrivateVisible;
        end
    end
end