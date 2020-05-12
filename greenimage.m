classdef greenimage < handle

    properties (Transient, SetAccess = private)
        Data
    end
        
    properties (SetAccess = immutable)
        Time
        Scale
        Adaptor
        DeviceName
        Mode
        BitDepth
        Resolution
        ROIPosition
        DeviceProperties
    end
    
    properties
        Scalebar
        Figure
    end
    
    methods
        function obj = greenimage(varargin)
            % validate input arguments
            p = inputParser;
            addRequired(p,'camera',@(x) validateattributes(x, ...
                {'camera'},{'scalar'}));
            addRequired(p,'scale',@(x) validateattributes(x, ...
                {'numeric'},{'scalar','real','finite'}));
            parse(p,varargin{:});
            camera = p.Results.camera;

            % Snap a picture
            [frame, meta] = getsnapshot(camera.Input.Green);

            % save image data / scale to 16 bit
            if camera.BitDepth == 12
                obj.Data     = frame(:,:,1) .* 16;
                obj.BitDepth = 16;
            else
                obj.Data     = frame(:,:,1);
                obj.BitDepth = camera.BitDepth;
            end

            % Save meta data to object
            obj.Time        = meta.AbsTime;
            obj.Adaptor     = camera.Adaptor;
            obj.DeviceName  = camera.DeviceName;
            obj.Mode        = camera.Input.Green.VideoFormat;
            obj.Resolution  = camera.Input.Green.VideoResolution;
            obj.ROIPosition = camera.Input.Green.ROIPosition;
            obj.Scale       = p.Results.scale;

            % Save device specific meta data
            src   = camera.Input.Green.Source;
            props = get(src);
            tmp   = fieldnames(props);
            tmp(structfun(@(x) x.DeviceSpecific,propinfo(src))) = [];
            obj.DeviceProperties = rmfield(props,tmp);
        end
        
        function show(obj)
            nargoutchk(0,1)
            obj.Figure = figure('Visible','off');
            hax  = axes(obj.Figure);
            image(hax,obj.Data, ...
                'CDataMapping', 'scaled')            
            colormap(obj.Figure,'gray')
            obj.Figure.Visible = 'on';
            
            title(hax,datestr(obj.Time,0))
            axis(hax,'equal')
            axis(hax,'tight')
            set(hax,...
                'Box',          'off', ...
                'TickDir',      'out', ...
                'Clim',         [min(obj.Data(:)) max(obj.Data(:))])

            obj.Scalebar = scalebar(hax,obj.Scale);
%             obj.Figure.SizeChangedFcn = {@resize};
%             
%             function resize(~,~,~)
%                 if isvalid(obj.Scalebar)
%                     obj.Scalebar.update
%                 end
%             end
        end
        
        function saveImage(obj,dirname)
            % validate attributes
            validateattributes(dirname,{'char'},{'row'})
            if ~exist(dirname,'dir')
                error('"%s" is not a valid directory.',dirname)
            end

            % save TIFF image
            t = Tiff(fullfile(dirname,'green.tif'),'w');
            options = struct( ...
            	'ImageWidth',          obj.ROIPosition(3), ...
            	'ImageLength',         obj.ROIPosition(4), ...
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
            t.write(obj.Data)
            t.close()
            
%             options = struct(...
%                 'overwrite',    true, ...
%                 'compress',     'adobe', ...
%                 'message',      false, ...
%                 'color',        false);
%             saveastiff(obj.Data,fullfile(dirname,'green.tif'),options);
        end
        
        function obj = loadImage(obj,filename)
            % image data is already present
            if ~isempty(obj.Data)
                error('Image data is already present.')
            end
            
            % validate inputs
            validateattributes(filename,{'char'},{'row'})
            if ~exist(filename,'file')
                error('"%s" does not exist.',filename)
            end
            
            % check if we're loading the correct image
            info = imfinfo(filename);
            if ~isequal(datevec(info.DateTime,'yyyy:mm:dd HH:MM:SS'),...
                    round(obj.Time))||~isequal([info.Width info.Height],...
                    obj.ROIPosition([3 4]))||~contains(info.Software,...
                    'Intrinsic Imaging')
                error('Image file "%s" does not fit metadata.',filename)
            end
            
            % save image data to object
            obj.Data = imread(filename);
        end
    end
end