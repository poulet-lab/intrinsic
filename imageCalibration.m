classdef imageCalibration < imageGeneric

    properties (Transient, Access = private)
        ButtonOK
        ButtonCancel
        LabelAverage
        LabelDistance
        LabelScale
        EditAverage
        EditDistance
        EditScale
        DistanceLine
        Whiskers
        Pixels = 1
        Centimeters = 1
        Time
        Resolution
    end
    
    properties (GetAccess = public)
        PxPerCm = NaN
    end

    events
        Calibrate
    end
    
    methods
        function obj = imageCalibration(varargin)
            % check arguments
            narginchk(1,1)
            
            % call constructor of superclass
            obj = obj@imageGeneric(varargin{:});
                        
            % save mode of Video Input Object "Green"
            obj.Resolution = obj.Camera.Input.Green.VideoResolution;
            
            % Take picture
            obj.takeImage()
            
            % Create GUI
            obj.Visible = 'on';
        end
    end
        
    methods (Access = protected)
        function createFigure(obj)
            createFigure@imageGeneric(obj)
            
            % JUST FOR TESTING
            tmp = imread('2.0x.png');
            obj.CData = tmp(:,:,1);
            
            colormap(obj.Figure,'gray')
            obj.Figure.Name = 'Calibration';
            obj.Figure.WindowStyle = 'modal';
            obj.ButtonOK = uicontrol(obj.Toolbar, ...
                'Style',    'pushbutton', ...
                'String',   'OK', ...
                'Position', [0 2 50 20], ...
                'Callback', @(~,~) obj.cbOK);
            obj.ButtonCancel = uicontrol(obj.Toolbar, ...
                'Style',    'pushbutton', ...
                'String',   'Cancel', ...
                'Position', [sum(obj.ButtonOK.Position([1 3]))+2 2 50 20], ...
                'Callback', @(~,~) obj.delete);
            obj.LabelDistance = uicontrol(obj.Toolbar, ...
                'Style',   	'text', ...
                'String', 	'Distance (mm): ', ...
                'Position',	...
                    [sum(obj.ButtonCancel.Position([1 3]))+12 1 80 17], ...
                'HorizontalAlignment',  'right');
            obj.EditDistance = uicontrol(obj.Toolbar, ...
                'Style',  	'edit', ...
                'String', 	'1',...
                'Callback',	@obj.cbEditDistance, ...
                'Position',	...
                    [sum(obj.LabelDistance.Position([1 3])) 1 50 20]);
            obj.LabelScale = uicontrol(obj.Toolbar, ...
                'Style',   	'text', ...
                'String', 	'Pixels per cm: ', ...
                'Position',	...
                    [sum(obj.EditDistance.Position([1 3]))+12 1 80 17], ...
                'HorizontalAlignment',  'right');
            obj.EditScale = uicontrol(obj.Toolbar, ...
                'Style',  	'edit', ...
                'String', 	'1',...
                'Enable',   'off', ...
                'Position',	...
                    [sum(obj.LabelScale.Position([1 3])) 1 50 20]);
            
            obj.Whiskers(1)  = line(obj.Axes,[0 0],[0 0],'Color','w');
            obj.Whiskers(2)  = line(obj.Axes,[0 0],[0 0],'Color','w');
            set(obj.Whiskers,...
                'Color',        'w', ...
                'LineWidth',    2)
            obj.DistanceLine = images.roi.Line(obj.Axes, ...
                'Position', ...
                    [[1/3 .5] .* obj.Size; [2/3 .5] .* obj.Size], ...
                'Color',        'k', ...
                'StripeColor',  'w', ...
                'DrawingArea', 'auto', ...
                'Deletable',    false);
            obj.DistanceLine.addlistener('MovingROI',@obj.update);
            
            obj.update()
            movegui(obj.Figure,'center')
            obj.Visible = 'on';
            obj.Zoom = 1;
        end
        
        function takeImage(obj)
            % Snap a picture
            [frame, meta] = getsnapshot(obj.Camera.Input.Green);

            % scale to 8 bit / save CData
            frame     = double(frame);
            frame     = frame - min(frame(:));
            obj.CData = uint8(round(frame ./ max(frame(:)) * 255));
            obj.CLim  = [0 255];
            
            % Save meta data to object
            obj.Time  = meta.AbsTime;
            
            % show figure
            obj.Visible = 'on';
        end
        
        function cbEditDistance(obj,hCtrl,~)
            cm = str2double(hCtrl.String)/10;
            if isfinite(cm) && isscalar(cm)
                obj.Centimeters = min([max([cm 0.001]) 10]);
                obj.update()
            end
            hCtrl.String = strtrim(sprintf('%3.3g',obj.Centimeters*10));
        end
        
        function cbOK(obj,~,~)
            notify(obj,'Calibrate')
            delete(obj)
        end
        
        function update(obj,~,~)
            % set coordinates of whiskers
            d   = max(obj.Size)*1.5;
            dxy = diff(obj.DistanceLine.Position,1);
            m   = atan2(dxy(2),dxy(1))/pi + [-.5 .5];
            x   = obj.DistanceLine.Position(:,1) + d * cospi(m);
            y   = obj.DistanceLine.Position(:,2) + d * sinpi(m);
            set(obj.Whiskers(1),'XData',x(1,:),'YData',y(1,:))
            set(obj.Whiskers(2),'XData',x(2,:),'YData',y(2,:))
            
            % update scale
            obj.Pixels  = sqrt(sum(diff(obj.DistanceLine.Position,1).^2));
            obj.PxPerCm = obj.Pixels / obj.Centimeters;
            obj.EditScale.String = sprintf('%0.1f',obj.PxPerCm);
            obj.Scalebar.Scale   = obj.PxPerCm;
        end
    end
end