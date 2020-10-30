classdef imageGreen < imageGeneric
    
    properties (SetAccess = immutable)
        Mode
    end
    
    properties (SetAccess = private)
        Time
        BitDepth
        DeviceProperties
    end
    
    methods
        function obj = imageGreen(varargin)
            % check arguments
            narginchk(2,2)
            
            % call constructor of superclass
            obj = obj@imageGeneric(varargin{:});
            
            % save mode of Video Input Object "Green"
            obj.Mode = obj.Camera.Input.Green.VideoFormat;
                        
            % Take picture
            obj.takeImage()
            
            % Create GUI
            obj.Visible = 'on';
        end

        function takeImage(obj)
            % Snap a picture
            [frame, meta] = getsnapshot(obj.Camera.Input.Green);

            % save image data / scale to 16 bit
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
            	'XResolution',         obj.Scale, ...
            	'YResolution',         obj.Scale, ...
            	'Software',            'Intrinsic Imaging', ...
            	'Make',                obj.Adaptor, ...
            	'Model',               obj.DeviceName, ...
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
            uicontrol(obj.Toolbar, ...
                'Style', 	'Checkbox', ...
                'Value',  	1, ...
                'Position',	[0 3 100 18], ...
                'String',  	'Auto Contrast', ...
                'Callback',	@obj.callbackCheckContrast);
            obj.Figure.Name = 'Green Image';
        end
    end
    
    methods (Access = private)
        function callbackCheckContrast(obj,hCtrl,~)
            if hCtrl.Value
                obj.CLim = [min(obj.CData(:)) max(obj.CData(:))];
            else
                obj.CLim = [0 2^obj.BitDepth-1];
            end
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