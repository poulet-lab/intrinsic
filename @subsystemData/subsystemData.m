classdef subsystemData < subsystemGeneric
    
    properties (Constant = true, Access = protected)
        MatPrefix = 'data_'
        DataType = 'double'
    end

    properties (GetAccess = private, SetAccess = immutable)
        DirTemp
    end
    
    properties (SetAccess = private, SetObservable, AbortSet)
        n = 0;
        Mean
        Var
        Trials
        Baseline
        Control
        Stimulus
        Running = false;
        Unsaved = false;
    end
    
    properties (Access = private)
        P
    end

    properties
        idxBaseline
        idxControl
        idxStimulus
    end
    
    methods
        function obj = subsystemData(varargin)
            obj = obj@subsystemGeneric(varargin{:});
            
            % Set directory for temporary data
            obj.DirTemp = fullfile(obj.Parent.DirBase,'tempdata');
            if ~exist(obj.DirTemp,'dir')
                mkdir(obj.DirTemp)
            end
            
            %addlistener(obj,'Mean','PostSet',@obj.cbUpdatedMean);
        end
    end
    
    methods (Access = {?intrinsic})
        clearData(obj,force)
    end
    
    methods (Access = private)
        function varargout = save2tiff(obj,data,timestamp)
            
            % Filename
            fn = sprintf('%03d_%s.tif',obj.n,...
                datestr(timestamp,'yymmdd_HHMMSS'));
            obj.Parent.message('Saving image data to disk: %s',fn)
            
            % TIFF options
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
                'Software',            sprintf('Intrinsic Imaging %s',intrinsic.version'), ...
                'Make',                obj.P.Camera.Adaptor, ...
                'Model',               obj.P.Camera.DeviceName, ...
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
                size(data,4),size(data,4),1/obj.P.Camera.FrameRate, ...
                obj.P.Camera.FrameRate), ...
                'SampleFormat',        Tiff.SampleFormat.UInt, ...
                'RowsPerStrip',        512);
            
            % Save to TIFF
            tiff = Tiff(fullfile(obj.DirTemp,fn),'w');
            for frame = 1:size(data,4)
                tiff.setTag(options);
                tiff.write(data(:, :, :, frame));
                if frame < size(data,4)
                    tiff.writeDirectory();
                end
            end
            tiff.close()
            
            % Return filename (optionally)
            if nargout > 0
                varargout{1} = fn;
            end
        end
        
        function cbUpdatedMean(obj,~,~)
%             tic
%             base = mean(obj.Mean(:,:,1,obj.Parent.DAQ.tTrigger<0),4);
%             %stim = mean(stack(:,:,obj.Time>=0 & obj.Time < obj.WinResponse(2)),3);
%             toc
        end
        
        getDataFromCamera(obj)
        checkDirTemp(obj)
    end
    
    methods (Access = {?intrinsic})
       start(obj,~,~)
       stop(obj,~,~)
    end
end