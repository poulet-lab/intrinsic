classdef video_preview < handle & matlab.mixin.CustomDisplay & dynamicprops
    
    properties (Access = private)
        hFigure = []
        hPoint = []
        Axes
        Panels
        Histogram
        Image
        PointCoords = [];
        PanelPosition
        FigurePosition
        Settings
        SettingsFields
        SettingsConstraints
        SettingsDefaults
        SettingsUI
    end
    
    properties (SetAccess = private)
        VideoInput
    end
    
    properties (Dependent = true)
        VideoSource
        Figure
        ROISize
        Visible
        Enable
        Preview
        Point
        Resolution
    end
    
    properties
        Dependent
        Scale
    end
    
    methods
        
        % Constructor
        function obj = video_preview(varargin)
            
            % parse input arguments
            p = inputParser;
            addRequired(p,'VideoInput',@(x) isa(x,'videoinput'));
            addOptional(p,'Scale',false,@isnumeric);
            addOptional(p,'Dependent',false,@islogical);
            parse(p,varargin{:});

            obj.VideoInput	= p.Results.VideoInput;
            obj.Scale       = p.Results.Scale;
            obj.Dependent   = p.Results.Dependent;

            % all adjustable properties of the camera
            prop_cam	= fieldnames(obj.VideoSource.propinfo);
            prop_cam	= prop_cam(structfun(@(x) ...
                strcmp(x.Constraint,'bounded'),obj.VideoSource.propinfo));
            
            % settings we would like to manipulate via sliders
            obj.Settings = {'Exposure','Gain','Offset'};
            tmp          = cellfun(@(x) ...
                any(cell2mat(regexpi(prop_cam,x))),obj.Settings);
            obj.Settings = obj.Settings(tmp);
            
            
            for setting = obj.Settings
                
                % add a dynamic property to OBJ & assign GET/SET methods
                h = obj.addprop(setting{:});
                switch setting{:}
                    case 'Exposure'
                        h.SetMethod = @obj.set_Exposure;
                        h.GetMethod = @obj.get_Exposure;
                    case 'Gain'
                        h.SetMethod = @obj.set_Gain;
                        h.GetMethod = @obj.get_Gain;
                    case 'Offset'
                        h.SetMethod = @obj.set_Offset;
                        h.GetMethod = @obj.get_Offset;
                end
                
                % get fieldnames and constraints for camera settings
                obj.SettingsFields.(setting{:}) = ...
                    prop_cam(~cellfun(@isempty,regexpi(prop_cam,setting{:})));
                obj.SettingsConstraints.(setting{:}) = ...
                    obj.VideoSource.propinfo ...
                    (obj.SettingsFields.(setting{:}){1}).ConstraintValue;
                obj.SettingsDefaults.(setting{:}) = ...
                    obj.VideoSource.propinfo ...
                    (obj.SettingsFields.(setting{:}){1}).DefaultValue;
            end
 
            % work around an issue with the QiCam minimum gain setting
            %obj.SettingsConstraints.Gain(1) = .601;
            
            % Initialize point coordinates
            obj.PointCoords.x = NaN;
            obj.PointCoords.y = NaN;
            
            obj.createFigure
        end
        
        % Set Scale
        function set.Scale(obj,value)
            validateattributes(value,{'numeric'},{'scalar','real','positive'})
            obj.Scale = value;
            obj.resizeFigure
            drawnow
        end
        
        % Get/set ROISize
        function value = get.ROISize(obj)
            tmp     = obj.VideoInput.ROIPosition;
            value   = tmp(3:4);
        end
        function set.ROISize(obj,value)
            validateattributes(value,{'numeric'},{'2d','numel',2,...
                'positive','row','integer'})
            if any(obj.Resolution<value)
                error('ROISize must not exceed Resolution.')
            end
            obj.VideoInput.ROIPosition = ...
                [floor((obj.Resolution-value)/2) value];
            obj.resizeFigure;
        end
        
        % Get Resolution
        function out = get.Resolution(obj)
            out = obj.VideoInput.VideoResolution;
        end
        
        % Get VideoSource
        function out = get.VideoSource(obj)
            out = obj.VideoInput.source;
        end
        
        % Set VideoInput
        function set.VideoInput(obj,vid)
            validateattributes(vid,{'videoinput'},{'scalar'})
            obj.VideoInput = vid;
        end
        
        % Get/set figure handle
        function out = get.Figure(obj)
            if isempty(obj.hFigure) || ~ishandle(obj.hFigure)
                obj.hFigure = [];
            end
            out = obj.hFigure;
        end
        function set.Figure(obj,value)
            obj.hFigure = value;
        end
        
        function out = get.Visible(obj)
            % Get visibility of GUI
            if isempty(obj.Figure)
                out = matlab.lang.OnOffSwitchState(0);
                return
            end
            out = obj.Figure.Visible;
        end
        
        function set.Visible(obj,value)
            % Set visibility of GUI
            value = matlab.lang.OnOffSwitchState(value);
            if isempty(obj.Figure) && value
                obj.createFigure()
            end
            obj.Figure.Visible = value;
            obj.Preview = value;
        end
        
        % Get/set enabled state of UI controls
        function out = get.Enable(obj)
            out = strcmp(obj.Panels.Settings.Children(1).Enable,'on');
        end
        function set.Enable(obj,enable)
            validateattributes(logical(enable),{'logical'},{'scalar'})
            if enable
                set(obj.Panels.Settings.Children,'Enable','on')
            else
                set(obj.Panels.Settings.Children,'Enable','off')
            end
        end
        
    end
    
    methods
       
        % Get/set status of preview
        function out = get.Preview(obj)
            out = strcmp(obj.VideoInput.Previewing,'on');
        end
        function set.Preview(obj,value)
            validateattributes(logical(value),{'logical'},{'scalar'})
            if value
                preview(obj.VideoInput,obj.Image);
                axis(obj.Axes.Image,'tight')
            else
                stoppreview(obj.VideoInput)
            end
        end
        
        % Get/set position of point
        function out = get.Point(obj)
            out = [obj.PointCoords.x obj.PointCoords.y];
        end
        function set.Point(obj,value)
            if isempty(value)
                obj.PointCoords.x = [];
                obj.PointCoords.y = [];
                if ~isempty(obj.Figure)
                    obj.hPoint.XData	= [];
                    obj.hPoint.YData	= [];
                end
            else
                validateattributes(value,{'numeric'},{'2d',...
                    'numel',2,'positive','row'})
                if any(value>obj.ROISize)
                    error('Point coordinates must be within ROI')
                end
                obj.PointCoords.x	= value(1);
                obj.PointCoords.y	= value(2);
                if ~isempty(obj.Figure)
                    obj.hPoint.XData = value(1);
                    obj.hPoint.YData = value(2);
                end
            end
        end
    end
    
    methods (Access = protected)
        function propgrp = getPropertyGroups(obj)
            propList1 = struct( ...
                'Figure',       obj.Figure, ...
                'Visible',      obj.Visible);
            propList2 = struct( ...
                'Resolution',   obj.Resolution, ...
                'ROISize',      obj.ROISize, ...
                'Scale',        obj.Scale);
            propgrp(1) = matlab.mixin.util.PropertyGroup(propList1,'Figure Settings');
            propgrp(2) = matlab.mixin.util.PropertyGroup(propList2,'Image Dimensions');
        end
    end
    
    methods (Access = private)
        

        % Get/set Exposure
        function out = get_Exposure(obj,~)
            out = obj.VideoSource.(obj.SettingsFields.Exposure{1});
        end
        function set_Exposure(obj,~,value)
            validateattributes(value,{'numeric'},{'scalar',...
                '>=',obj.SettingsConstraints.Exposure(1),...
                '<=',obj.SettingsConstraints.Exposure(2)})
            
            value   = double(value);
            D       = 10^(3-ceil(log10(abs(value))));  % round to three ...
            value	= round(value*D)/D;                % significant digits
            
            for ii = 1:length(obj.SettingsFields.Exposure)
                obj.VideoSource.(obj.SettingsFields.Exposure{ii}) = value;
            end
            obj.updateUI
        end
        
        % Get/set Gain
        function out = get_Gain(obj,~)
            out = obj.VideoSource.(obj.SettingsFields.Gain{1});
        end
        function set_Gain(obj,~,value)
            validateattributes(value,{'numeric'},{'scalar',...
                '>=',obj.SettingsConstraints.Gain(1),...
                '<=',obj.SettingsConstraints.Gain(2)})
            
            value   = double(value);
            D       = 10^(3-ceil(log10(abs(value))));  % round to three ...
            value   = round(value*D)/D;                % significant digits
                
            obj.VideoSource.(obj.SettingsFields.Gain{1}) = value;
            obj.updateUI
        end
        
        % Get/set Offset
        function out = get_Offset(obj,~)
            out = obj.VideoSource.(obj.SettingsFields.Offset{1});
        end
        function set_Offset(obj,~,value)
            if isempty(obj.SettingsFields.Offset)
                return
            end
            
            validateattributes(value,{'numeric'},{'scalar',...
                '>=',obj.SettingsConstraints.Offset(1),...
                '<=',obj.SettingsConstraints.Offset(2)})
            obj.VideoSource.(obj.SettingsFields.Offset{1}) = value;
            obj.updateUI
        end

        
        % Create GUI
        function createFigure(obj)
            
            if ~isempty(obj.Figure) % If there is an existing GUI window,
                obj.resizeFigure    % (1) resize to match image,
                obj.updateUI        % (2) update UI controls,
                figure(obj.Figure)  % (3) bring figure into focus,
                return              % (4) return to calling function
            end
            
            obj.hFigure = figure( ...
                'Visible',          'off', ...
                'Toolbar',          'none', ...
                'Menu',             'none', ...
                'NumberTitle',      'off', ...
                'Resize',           'off', ...
                'Name',             'Video Preview', ...
                'CloseRequestFcn',  @obj.close);
            
            % Create Panels
            obj.Panels.Image = uipanel(obj.Figure, ...
                'Units',            'Pixels', ...
                'BorderType',       'beveledin', ...
                'BackgroundColor',  'black');
            obj.Panels.Histogram = uipanel(obj.Figure,...
                'Units',            'Pixels', ...
                'Title',            'Live Histogram');
            obj.Panels.Settings = uipanel(obj.Figure,...
                'Units',            'Pixels', ...
                'Title',            'Camera Settings');
            
            % Create axes for image display, create dummy image
            obj.Axes.Image = axes(...
                'Parent',           obj.Panels.Image, ...
                'Position',         [0 0 1 1], ...
                'DataAspectRatio',  [1 1 1]);
            obj.Image = imshow(zeros(obj.ROISize), ...
                'Parent',           obj.Axes.Image);
            set(obj.Image,'ButtonDownFcn',@obj.toggleFullscreen)
            setappdata(obj.Image,'UpdatePreviewWindowFcn',@obj.updatePreview);
            hold on
            obj.hPoint = plot(obj.PointCoords.x,obj.PointCoords.y,...
            	'pickableparts',    'none', ...
                'marker',           'o', ...
                'markerfacecolor',  'r', ...
                'markeredgecolor',  'w', ...
                'markersize',       5, ...
                'linewidth',        1);
            
            % Create axes for live histogram
            obj.Axes.Histogram = axes(...
                'Parent',           obj.Panels.Histogram, ...
                'Units',            'normalized', ...
                'Position',         [0 0 1 1]);
            obj.Histogram = histogram(obj.Axes.Histogram, ...
                zeros(obj.Resolution),0:255,...
                'LineStyle',        'none', ...
                'facecolor',        'k', ...
                'facealpha',        1);
            set(obj.Axes.Histogram,...
                'visible',          'off', ...
                'xlim',             [0 255])
            
            % Create UI controls for camera settings
            ButtonString = {'Auto Exposure','Reset Gain','Reset Offset'};
            for ii = 1:length(obj.Settings)
                active = ~isempty(obj.SettingsFields.(obj.Settings{ii}));
                enable = {'on' 'off'};
                enable = enable{~active+1};
                obj.SettingsUI.(obj.Settings{ii}).LabelName = uicontrol( ...
                    'Style',  	'text', ...
                    'String',	[obj.Settings{ii} ':'], ...
                    'Horiz',    'right', ...
                    'Parent',   obj.Panels.Settings,...
                    'Enable',   enable);
                obj.SettingsUI.(obj.Settings{ii}).Edit = uicontrol( ...
                    'Style',    'edit', ...
                    'Horiz',    'left', ...
                    'String',   obj.(obj.Settings{ii}), ...
                    'Parent',   obj.Panels.Settings, ...
                    'Tag',      obj.Settings{ii}, ...
                    'Callback', {@obj.EditCallback},...
                    'Enable',   enable);
                obj.SettingsUI.(obj.Settings{ii}).Slider = uicontrol( ...
                    'Style',    'slider', ...
                    'Min',      obj.SettingsConstraints.(obj.Settings{ii})(1), ...
                    'Max',      obj.SettingsConstraints.(obj.Settings{ii})(2), ...
                    'Value',    obj.(obj.Settings{ii}), ...
                    'Backgr',   'white', ...
                    'Parent',   obj.Panels.Settings, ...
                    'Tag',      obj.Settings{ii}, ...
                    'Callback', {@obj.SliderCallback},...
                    'Enable',   enable);
                if strcmp(obj.Settings{ii},'Exposure')
                    if obj.SettingsConstraints.(obj.Settings{ii})(2) < 0
                        set(obj.SettingsUI.(obj.Settings{ii}).Slider, ...
                            'Value',	obj.(obj.Settings{ii}), ...
                            'Min',      obj.SettingsConstraints.(obj.Settings{ii})(1), ...
                            'Max',      obj.SettingsConstraints.(obj.Settings{ii})(2));                        
                    else
                        set(obj.SettingsUI.(obj.Settings{ii}).Slider, ...
                            'Value',	log(obj.(obj.Settings{ii})), ...
                            'Min',      log(obj.SettingsConstraints.(obj.Settings{ii})(1)), ...
                            'Max',      log(obj.SettingsConstraints.(obj.Settings{ii})(2)));
                    end
                end
                obj.SettingsUI.(obj.Settings{ii}).LabelMin = uicontrol( ...
                    'Style',    'text', ...
                    'String',   obj.SettingsConstraints.(obj.Settings{ii})(1), ...
                    'Horiz',    'left', ...
                    'Foregr', 	[.5 .5 .5], ...
                    'Parent',   obj.Panels.Settings);
                obj.SettingsUI.(obj.Settings{ii}).LabelMax = uicontrol( ...
                    'Style',    'text', ...
                    'String',   obj.SettingsConstraints.(obj.Settings{ii})(2), ...
                    'Horiz',    'right', ...
                    'Foregr', 	[.5 .5 .5], ...
                    'Parent',   obj.Panels.Settings);
                obj.SettingsUI.(obj.Settings{ii}).Button = uicontrol( ...
                    'String',   ButtonString{ii}, ...
                    'Parent',   obj.Panels.Settings, ...
                    'Tag',      obj.Settings{ii}, ...
                    'Callback', {@obj.ButtonCallback},...
                    'Enable',   enable);
            end
            
            obj.resizeFigure                        % position UI elements
            movegui(obj.Figure,'center')            % center the GUI
            if ~obj.Dependent
                obj.Preview = true;                 % start live preview
                obj.Visible = 'on';                 % make figure visible
            end
        end
        
        % Update image and histogram
        function updatePreview(obj,~,event,hImage)
            set(hImage,'CData',event.Data);         % show current frame
            obj.Histogram.Data = event.Data;     	% replace hist data
            set(obj.Axes.Histogram,'ylim',...      	% set Y limits
                [0 1.05*max(obj.Histogram.Values)])
            drawnow nocallbacks                  	% refresh display
        end 
        
        % Resize the main figure and its UI elements
        function resizeFigure(obj)
            if isempty(obj.Figure)
                return
            end
            margin  = 8;                          	% figure margin [px]
            pwidth  = obj.ROISize(1)*obj.Scale+4; 	% panel width [px]
            if pwidth < 300, pwidth = 300; end      % minimum panel width
            
            vsize  	= 40;           % height of UI controls [px]
            voffset	= -4;         	% vertical offset of UI controls [px]
            hpad   	= 5;          	% padding of UI controls [px]
            hsizes 	= [51 70 0 85];	% width of UI controls [px]
            hsizes(3) 	= pwidth-sum(hsizes([1 2 4]))-5*hpad-4;
            
            % Calculate positions of panels and figure
            obj.PanelPosition.Settings = [...
                margin ...
                margin ...
                pwidth ...
                40*length(obj.Settings)+20];
            obj.PanelPosition.Histogram = [...
                margin ...
                sum(obj.PanelPosition.Settings([2 4])) ...
                pwidth ...
                150];
            obj.PanelPosition.Image = [...
                margin ...
                sum(obj.PanelPosition.Histogram([2 4])) ...
                pwidth ...
                obj.ROISize(2)*obj.Scale+4];
            obj.FigurePosition = ...
                [obj.Figure.Position(1:2) ...
                pwidth+2*margin-3 ...
                sum(structfun(@(x) x(4),obj.PanelPosition))+2*margin-2];
            
            was_visible = obj.Figure.Visible;
            obj.Figure.Visible = 'off';
            
            % Set positions of panels and figure
            obj.Panels.Image.Position       = obj.PanelPosition.Image;
            obj.Panels.Histogram.Position	= obj.PanelPosition.Histogram;
            obj.Panels.Settings.Position	= obj.PanelPosition.Settings;
            obj.Figure.Position             = obj.FigurePosition;
            
            % Set positions of UI controls
            for ii = 1:length(obj.Settings)
                vpos = obj.PanelPosition.Settings(4)-vsize*(ii)+voffset;
                set(obj.SettingsUI.(obj.Settings{ii}).LabelName,...
                    'Pos', [hpad,vpos,hsizes(1),20]);
                set(obj.SettingsUI.(obj.Settings{ii}).Edit, ...
                    'Pos', [2*hpad+hsizes(1),vpos+3,hsizes(2),20]);
                set(obj.SettingsUI.(obj.Settings{ii}).Slider, ...
                    'Pos', [3*hpad+sum(hsizes(1:2)),vpos+3,hsizes(3),20]);
                set(obj.SettingsUI.(obj.Settings{ii}).LabelMin, ...
                    'Pos', [3*hpad+sum(hsizes(1:2)),vpos+3-20,75,20]);
                set(obj.SettingsUI.(obj.Settings{ii}).LabelMax, ...
                    'Pos', [3*hpad+sum(hsizes(1:3))-75,vpos+3-20,75,20]);
                set(obj.SettingsUI.(obj.Settings{ii}).Button, ...
                    'Pos', [4*hpad+sum(hsizes(1:3)),vpos+2,hsizes(4),22]);
            end
            
            obj.Figure.Visible = was_visible;
        end
        
        % Update the values of UI controls
        function updateUI(obj)
            if isempty(obj.Figure)
                return
            end
            for setting = obj.Settings
                obj.SettingsUI.(setting{:}).Edit.String = ...
                    obj.(setting{:});
                if strcmp(setting{:},'Exposure') && ...
                         obj.SettingsConstraints.(setting{:})(1) > 0
                    obj.SettingsUI.(setting{:}).Slider.Value = ...
                        log(obj.(setting{:}));
                else
                    obj.SettingsUI.(setting{:}).Slider.Value = ...
                        obj.(setting{:});
                end
            end
            drawnow
        end
        
        % Callback function for textfields
        function EditCallback(obj,source,~)
            new_val = str2double(source.String);
            if new_val < obj.SettingsConstraints.(source.Tag)(1)
                new_val = obj.SettingsConstraints.(source.Tag)(1);
            end
            if new_val > obj.SettingsConstraints.(source.Tag)(2)
                new_val = obj.SettingsConstraints.(source.Tag)(2);
            end
            obj.(source.Tag) = new_val;
        end
        
        % Callback function for sliders
        function SliderCallback(obj,source,~)
            new_val = source.Value;
            if strcmp(source.Tag,'Exposure') && obj.SettingsConstraints.(source.Tag)(1) > 0
                new_val = exp(new_val);
            end
            if new_val < obj.SettingsConstraints.(source.Tag)(1)
                new_val = obj.SettingsConstraints.(source.Tag)(1);
            end
            if new_val > obj.SettingsConstraints.(source.Tag)(2)
                new_val = obj.SettingsConstraints.(source.Tag)(2);
            end
            obj.(source.Tag) = new_val;
        end
        
        % Callback function for buttons
        function ButtonCallback(obj,source,~)
            if regexpi(source.String,'Auto')
                obj.AutoExpose(source.Tag)
            elseif regexpi(source.String,'Reset')
                obj.(source.Tag) = obj.SettingsDefaults.(source.Tag);
            end
        end
        
        % Try to find an ideal exposure value
        function AutoExpose(obj,setting)
            was_enabled = obj.Enable;
            bits  = 12;
            lower = obj.SettingsConstraints.(setting)(1);
            upper = min([obj.SettingsConstraints.(setting)(2) 1]);
            
            tmp   = getsnapshot(obj.VideoInput);
            under = sum(tmp(:)==0);        % number of underexposed pixels
            over  = sum(tmp(:)==2^bits-1); % number of overexposed pixels
            
            %% try to balance the number of under- and overexposed pixels
            if any(over) || any(under)
                obj.Enable = false;
                for ii = 1:50
                    tmp     = getsnapshot(obj.VideoInput);
                    under   = sum(tmp(:)==0);     	 % underexposed pixels
                    over    = sum(tmp(:)==2^bits-1); % overexposed pixels
                    current = obj.(setting);
                    
                    if      under > over     	% image is under-exposed
                        lower = current;
                        obj.(setting) = exp(mean([log(current) log(upper)]));
                    elseif  over  > under     	% image is over-exposed
                        upper = current;
                        obj.(setting) = exp(mean([log(current) log(lower)]));
                    elseif  over == under       % balanced
                        break
                    end
                end
            end
            
            %% if all pixels in dynamic range, try to center histogram
            target 	= 2^(bits-1);
            tol     = 2^5;

            if ~over && ~under
                tmp	= getsnapshot(obj.VideoInput);
                avg	= mean([min(tmp(:)) max(tmp(:))]);   	% average brightness
                
                obj.Enable = false;
                for ii = 1:100
                    current = obj.(setting);
                    if      avg > target+tol 	% image is over-exposed
                        upper = current;
                        obj.(setting) = exp(mean([log(current) log(lower)]));
                    elseif  avg < target-tol  	% image is under-exposed
                        lower = current;
                        obj.(setting) = exp(mean([log(current) log(upper)]));
                    else
                        break
                    end
                    tmp     = getsnapshot(obj.VideoInput);
                    avg     = mean([min(tmp(:)) max(tmp(:))]);   	% average brightness
                end
            end
            
            obj.Enable = was_enabled;
            drawnow
        end
        
        % Toggle fullscreen mode of preview image
        function toggleFullscreen(obj,~,~,~)
            % fullscreen is only supported from version 2018a
            if isempty(obj.Figure) || verLessThan('matlab','9.4')
                return
            end
            
            % depopulate figure & maximize
            set(obj.Panels.Image,...
                'Units',        'Normalized', ...
                'Position',     [0 0 1 1], ...
                'BorderType', 	'none')
            set([obj.Panels.Histogram obj.Panels.Settings], ...
                'Visible',      'off')
            set(obj.Figure,...
                'WindowStyle',  'modal', ...
                'WindowState',  'fullscreen')
            
            % save old position
            position = obj.Figure.Position;
            
            % wait for user interaction
            waitforbuttonpress
            
            % repopulate figure & return to normal state
            set(obj.Panels.Image,...
                'Units',     	'pixels', ...
                'Position',     obj.PanelPosition.Image, ...
                'BorderType', 	'beveledin')
            set([obj.Panels.Histogram obj.Panels.Settings], ...
                'Visible',      'on')
            set(obj.Figure,...
                'WindowStyle',  'normal', ...
                'WindowState',  'normal', ...
                'Position',     position)
        end
        
        % Close the app
        function close(obj,~,~)
            obj.Preview = false;        % stop preview
            if obj.Dependent
                obj.Visible = 'off';    % hide figure
            else
                delete(obj.hFigure)   	% delete figure
            end
        end
    end
    
end