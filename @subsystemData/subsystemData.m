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
        Running = false;    % is an acquisition running right now?
        Unsaved = false;    % is there unsaved data?
    end
    
    properties %(Access = private)
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
            
            addlistener(obj.Parent.Stimulus,...
                'Parameters','PostSet',@obj.getParameters);
            addlistener(obj.Parent.Camera,...
                'Update',@obj.getParameters);
            addlistener(obj.Parent.DAQ,...
                'Update',@obj.getParameters);
            
            obj.getParameters()
            %addlistener(obj,'Mean','PostSet',@obj.cbUpdatedMean);
        end
    end
    
    methods (Access = {?intrinsic})
        clearData(obj,force)
    end
    
    methods (Access = private)
        
        function getParameters(obj,~,~)
            % Collects relevant parameters from other objects. Used as a
            % callback for listener-functions - see constructor of
            % subsystemData.
            if obj.Unsaved
                return
            end
            obj.P.Camera.Adaptor  	= obj.Parent.Camera.Adaptor;
            obj.P.Camera.DeviceName	= obj.Parent.Camera.DeviceName;
            obj.P.Camera.Mode     	= obj.Parent.Camera.Mode;
            obj.P.Camera.DataType  	= obj.Parent.Camera.DataType;
            obj.P.Camera.Binning  	= obj.Parent.Camera.Binning;
            obj.P.Camera.BitDepth  	= obj.Parent.Camera.BitDepth;
            obj.P.Camera.Resolution	= obj.Parent.Camera.Resolution;
            obj.P.Camera.ROI     	= obj.Parent.Camera.ROI;
            obj.P.Camera.FrameRate	= obj.Parent.Camera.FrameRate;
            obj.P.DAQ.VendorID    	= obj.Parent.DAQ.Session.Vendor.ID;
            obj.P.DAQ.VendorName   	= obj.Parent.DAQ.Session.Vendor.FullName;
            obj.P.DAQ.OutputData  	= obj.Parent.DAQ.OutputData;
            obj.P.DAQ.nTrigger    	= obj.Parent.DAQ.nTrigger;
            obj.P.DAQ.tTrigger   	= obj.Parent.DAQ.tTrigger;
            obj.P.Stimulus      	= obj.Parent.Stimulus.Parameters;
        end
        
        function varargout = save2tiff(obj,filename,data,timestamp)
            % Store DATA to a (multipage) TIFF file
            
            % If no timestamp was supplied use the current time
            if ~exist('timestamp','var')
                timestamp = now;
            end
            
            % TIFF options
            options = struct( ...
                'ImageWidth',          size(data,2), ...
                'ImageLength',         size(data,1), ...
                'Photometric',         Tiff.Photometric.MinIsBlack, ...
                'Compression',         Tiff.Compression.LZW, ...
                'PlanarConfiguration', Tiff.PlanarConfiguration.Chunky, ...
                'BitsPerSample',       16, ...
                'SamplesPerPixel',     size(data,3), ...
                'ResolutionUnit',      Tiff.ResolutionUnit.Centimeter, ...
                'Software',            sprintf('Intrinsic Imaging %s',intrinsic.version'), ...
                'Make',                obj.P.Camera.Adaptor, ...
                'Model',               obj.P.Camera.DeviceName, ...
                'DateTime',            datestr(timestamp,'yyyy:mm:dd HH:MM:SS'), ...
                'SampleFormat',        Tiff.SampleFormat.UInt, ...
                'RowsPerStrip',        512);

            % Add scale if available
            if ~isnan(obj.Parent.Scale.PxPerCm)
                options.XResolution = round(obj.Parent.Scale.PxPerCm);
                options.YResolution = options.XResolution;
            end
            
            % Manage ImageDescription field
            desc = sprintf(['ImageJ=\nimages=%d\nframes=%d\nslices=1\n' ...
                    'hyperstack=false\nunit=cm\n'],size(data,4),size(data,4));
            if size(data,4) > 1
                desc = sprintf('%sfinterval=%0.5f\nfps=%0.5f\n',...
                    desc,1/obj.P.Camera.FrameRate,obj.P.Camera.FrameRate);
            end
            options.ImageDescription = desc;
            
            % Save to TIFF
            tiff = Tiff(fullfile(obj.DirTemp,filename),'w');
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
                varargout{1} = filename;
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