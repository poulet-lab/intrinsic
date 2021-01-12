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
        Baseline
        Control
        Stimulus
        Running = false;
    end

    properties (Dependent)
        idxBaseline
        idxControl
        idxStimulus
    end
    
    properties %(Access = private)
        TimestampsCamera
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