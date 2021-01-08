classdef subsystemData < subsystemGeneric
    
    properties (Constant = true, Access = protected)
        MatPrefix = 'data_'
    end
    
    properties (SetAccess = private)
        n = 0;
        Mean
        Var
    end
    
    properties %(Access = private)
        DataType = 'double';
        TimestampsCamera;
    end
    
    methods
        function obj = subsystemData(varargin)
            obj = obj@subsystemGeneric(varargin{:});
        end
    end
    
    methods (Access = {?intrinsic})
        function clearData(obj)
            obj.Mean = [];
            obj.Var = [];
            obj.n = 0;
            obj.TimestampsCamera = [];
        end
        
        %function 
    end
    
    methods (Access = private)
        function save2tiff(obj,data,timestamp,adaptor,deviceName)
            obj.Parent.message('Saving image data to disk')
            tiff = Tiff(fn,'w');
            options = struct( ...
                'ImageWidth',          size(data,2), ...
                'ImageLength',         size(data,1), ...
                'Photometric',         Tiff.Photometric.MinIsBlack, ...
                'Compression',         Tiff.Compression.LZW, ...
                'PlanarConfiguration', Tiff.PlanarConfiguration.Chunky, ...
                'BitsPerSample',       16, ...
                'SamplesPerPixel',     size(data,3), ...
                'XResolution',         round(obj.Parent.Scale.PxPerCm), ...
                'YResolution',         round(obj.Parent.Scale.PxPerCm), ...
                'ResolutionUnit',      Tiff.ResolutionUnit.Centimeter, ...
                'Software',            'Intrinsic Imaging', ...
                'Make',                adaptor, ...
                'Model',               deviceName, ...
                'DateTime',            datestr(timestamp,'yyyy:mm:dd HH:MM:SS'), ...
                'ImageDescription',    sprintf([...
                    'ImageJ=\n' ...
                    'images=%d\n' ...
                    'frames=%d\n' ...
                    'slices=1\n' ...
                    'hyperstack=false\n' ... 
                    'unit=cm\n' ...
                    'finterval=%0.5f\n' ...
                    'fps=%0.5f\n'], ...
                size(data,4),size(data,4),1/obj.FrameRate,obj.FrameRate), ...
                'SampleFormat',        Tiff.SampleFormat.UInt, ...
                'RowsPerStrip',        512);
            tic
            for frame = 1:size(obj.Data,4)
                tiff.setTag(options);
                tiff.write(obj.Data(:, :, :, frame));
                if frame < size(obj.Data,4)
                    tiff.writeDirectory();
                end
            end
            tiff.close()
            toc
            
            obj.Data = [];
        end
    end
    
    methods (Access = {?subsystemCamera})
        function addCameraData(obj,data,metadata)
            if obj.n
                validateattributes(data,{'numeric'},{'size',size(obj.Mean)})
            end
            
            % increment n
            obj.n = obj.n + 1;
            
            % TODO: save raw data to TIFF
            obj.save2tiff( ...
                data, ...                       % raw data from camera
                metadata(1).AbsTime, ...        % timestamp of first frame
                obj.Parent.Camera.Adaptor, ...  % name of imaging adaptor
                obj.Parent.Camera.DeviceName)   % name of imaging device)
            
            % Save timestamps
            obj.TimestampsCamera = [obj.TimestampsCamera ...
                datenum(vertcat(metadata.AbsTime))];
            
            % Calculate running mean and average
            obj.Parent.message('Processing data (trial %d)\n',obj.n)
            data = cast(data,obj.DataType);
            if obj.n == 1
                % Initialize Mean and Var
                obj.Mean = data;
                obj.Var  = zeros(size(data),obj.DataType);
            else
                % Update Mean and Var using Welford's online algorithm
                norm     = obj.n - 1;
                mean0    = obj.Mean;
                obj.Mean = mean0 + (data - mean0) / obj.n;
                obj.Var  = (obj.Var .* (norm-1) + (data-mean0) .* ...
                    (data-obj.Mean)) / norm;
            end
        end
    end
end