classdef imageGreen < imageGeneric
    
    properties (SetAccess = immutable)
        Mode
    end
    
    properties (SetAccess = private)
        Time
        BitDepth
        DeviceProperties
    end
    
    properties %(Access = private)
        PopupMagnification
        Center
    end
    
    methods
        function obj = imageGreen(varargin)
            % check arguments
            narginchk(1,1)
            
            % call constructor of superclass
            obj = obj@imageGeneric(varargin{:});
            
            % save mode of Video Input Object "Green"
            obj.Mode = obj.Camera.Input.Green.VideoFormat;
                        
            % Take picture
            obj.takeImage()
            
            % Create Center marker
            obj.Center = images.roi.Point(obj.Axes, ...
                'Color',  	'r', ...
                'Deletable', false);
            
            % Create GUI
            obj.Visible = 'on';
            
            % Listen for unsaved changes
            addlistener(obj.Parent.Data,'Unsaved','PostSet',@obj.callbackUnsaved);
            addlistener(obj.Parent.Red,'NewCenter',@obj.callbackCenter);
        end

        function takeImage(obj)
            % Snap a picture
            [frame, meta] = getsnapshot(obj.Camera.Input.Green);

            % Copy scale from parent
            %obj.Scale = copy(obj.Parent.Scale);
            obj.Scale = obj.Parent.Scale;
            obj.scaleChanged();
            
            % Save image data / scale to 16 bit
            if obj.Camera.BitDepth == 12
                obj.CData    = frame(:,:,1) .* 16;
                obj.BitDepth = 16;
            else
                obj.CData	 = frame(:,:,1);
                obj.BitDepth = obj.Camera.BitDepth;
            end
            
            % Save meta data to object
            obj.Time        = meta.AbsTime;
            
            % save properties of Video Input Object
            src   = obj.Camera.Input.Green.Source;
            props = get(src);
            tmp   = fieldnames(props);
            tmp(structfun(@(x) x.DeviceSpecific,propinfo(src))) = [];
            obj.DeviceProperties = rmfield(props,tmp);
            
            % show figure
            obj.Visible = 'on';
        end

        function saveTIFF(obj,dirname)
            % validate attributes
            validateattributes(dirname,{'char'},{'row'})
            if ~exist(dirname,'dir')
                error('"%s" is not a valid directory.',dirname)
            end

            % save TIFF image
            t = Tiff(fullfile(dirname,'green.tif'),'w');
            options = struct( ...
            	'ImageWidth',          obj.Size(1), ...
            	'ImageLength',         obj.Size(2), ...
            	'Photometric',         Tiff.Photometric.MinIsBlack, ...
            	'Compression',         Tiff.Compression.AdobeDeflate, ...
            	'PlanarConfiguration', Tiff.PlanarConfiguration.Chunky, ...
            	'BitsPerSample',       obj.BitDepth, ...
            	'SamplesPerPixel',     1, ...
            	'ResolutionUnit',      Tiff.ResolutionUnit.Centimeter, ...
            	'XResolution',         round(obj.Scale.PxPerCm), ...
            	'YResolution',         round(obj.Scale.PxPerCm), ...
            	'Software',            'Intrinsic Imaging', ...
            	'Make',                obj.Camera.Adaptor, ...
            	'Model',               obj.Camera.DeviceName, ...
            	'DateTime',            datestr(obj.Time,'yyyy:mm:dd HH:MM:SS'), ...
            	'RowsPerStrip',        512);
            t.setTag(options)
            t.write(obj.CData)
            t.close()
        end
        
        function obj = loadTIFF(obj,filename)
            % validate inputs
            validateattributes(filename,{'char'},{'row'})
            if ~exist(filename,'file')
                error('"%s" does not exist.',filename)
            end
            
            % check if we're loading the correct image
            info = imfinfo(filename);
            if ~isequal(datevec(info.DateTime,'yyyy:mm:dd HH:MM:SS'),...
                    round(obj.Time))||~isequal([info.Width info.Height],...
                    obj.Size)||~contains(info.Software,...
                    'Intrinsic Imaging')
                error('Image file "%s" does not fit metadata.',filename)
            end
            
            % save image data to object
            obj.CData = imread(filename);
        end
    end
    
    methods (Access = protected)
        function createFigure(obj)
            createFigure@imageGeneric(obj)
            colormap(obj.Figure,'gray')
            tmp = uicontrol(obj.Toolbar, ...
                'Style', 	'checkbox', ...
                'Value',  	1, ...
                'Position',	[0 2 90 20], ...
                'String',  	'Auto Contrast', ...
                'Callback',	@callbackCheckContrast);
            tmp = uicontrol(obj.Toolbar, ...
                'Style',       	'Text', ...
                'String',    	'Magnification:', ...
                'Position',    	[sum(tmp.Position([1 3]))+10 -1 0 0], ...
                'Horizontal',  	'right');
            tmp.Position(3:4) = tmp.Extent(3:4);
            obj.PopupMagnification = uicontrol(obj.Toolbar, ...
                'Style', 	'popupmenu', ...
                'Value',  	find(ismember(obj.Scale.Magnifications,obj.Scale.Magnification)), ...
                'String',  	obj.Scale.Magnifications, ...    
                'Position',	[sum(tmp.Position([1 3]))+3 3 50 20], ...
                'Callback',	@callbackPopupScale);
            obj.Figure.Name = 'Green Image';
            
            function callbackCheckContrast(hCtrl,~)
                if hCtrl.Value
                    obj.CLim = [min(obj.CData(:))-1 max(obj.CData(:))+1];
                else
                    obj.CLim = [0 2^obj.BitDepth-1];
                end
            end
            
            function callbackPopupScale(hCtrl,~)
                obj.Scale.Magnification = hCtrl.String{hCtrl.Value};
            end
        end
        
        function callbackUnsaved(obj,~,~)
            if obj.Parent.Data.Unsaved
                obj.PopupMagnification.Enable = 'off';
            else
                obj.PopupMagnification.Enable = 'on';
            end
        end
        
        function callbackCenter(obj,~,~)
            obj.Center.Position = obj.Parent.Red.Center;
        end
        
        function scaleChanged(obj,~,~)
            scaleChanged@imageGeneric(obj)
            obj.PopupMagnification.String = obj.Scale.Magnifications;
            obj.PopupMagnification.Value = ...
                find(ismember(obj.Scale.Magnifications,obj.Scale.Magnification));
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