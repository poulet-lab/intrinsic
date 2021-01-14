classdef subsystemCamera < subsystemGeneric

    properties (SetAccess = private)
        Adaptor      = 'none';                      % Selected IMAQ adaptor
        DeviceName   = '';                          % Name of selected device
        DeviceID     = NaN;                         % ID of selected device
        Mode         = '';                          % Selected video mode
        Input        = struct('Green',[],'Red',[]); % Video input objects
        FrameRate    = NaN                          % Frame rate
    end

    properties (Dependent = true)
        DataType    % Data type returned by the imaging adaptor
        BitDepth    % Bit depth of captured images
        Resolution  % Width and height of captured images
        ROI         % Width and height of the current region of interest
        Binning     % Level of hardware binning (only on supported devices)
        Available   % Is the selected device available?
        Supported   % Is the selected device supported?
    end

    properties (Constant = true, Access = private)
        toolbox   = ~isempty(ver('IMAQ')) && ...
            license('test','image_acquisition_toolbox');
    end

    properties (Constant = true, Access = protected)
        MatPrefix = 'camera_'
    end
    
    properties (Access = private, Transient)
        Figure
    end
    


    methods
        varargout = setup(obj)

        function obj = subsystemCamera(varargin)
            obj = obj@subsystemGeneric(varargin{:});

            if ~obj.toolbox
                % check for IMAQ toolbox
                warning('Image Acquisition Toolbox is not available.')
            else
                % check for installed adapters
                if isempty(eval('imaqhwinfo').InstalledAdaptors)
                    warning('No IMAQ adapters installed.')
                end
                obj.reset();
            end

            % try to create video input
            obj.createInputs()
        end

        function out = get.Available(obj)
            % return availability of configured video device
            out = false;
            if ~obj.toolbox
                return
            end
            if all(structfun(@(x) isa(x,'videoinput'),obj.Input))
                out = all(structfun(@isvalid,obj.Input));
            end
        end

        function out = get.Binning(obj)
            % return binning factor (only supported devices)
            out = NaN;
            if obj.Available && strcmp(obj.DeviceName,'QICam B')
                tmp = imaqhwinfo(obj.Adaptor,obj.DeviceID).SupportedFormats;
                tmp = regexpi(tmp,'^\w*_(\d)*x\d*$','tokens','once');
                out = max(cellfun(@str2double,[tmp{:}]))/obj.Resolution(1);
            end
        end

        function out = get.DataType(obj)
            % return data type returned from imaging adapter
            if obj.Available
                out = imaqhwinfo(obj.Input.Green).NativeDataType;
            else
                out = NaN;
            end
        end

        function out = get.Resolution(obj)
            % return resolution
            if obj.Available
                out = obj.Input.Green.VideoResolution;
            else
                out = [NaN NaN];
            end
        end

        function out = get.ROI(obj)
            % return ROI
            if obj.Available
                out = obj.Input.Green.ROIPosition;
                out = out(3:4);
            else
                out = [NaN NaN];
            end
        end

        function out = get.Supported(obj)
            % is the combination of adaptor + device tested & "supported"?
            sup = {'qimagingQICam B','mwqimagingimaqQICam B'};
            out = any(strcmpi(sup,[obj.Adaptor obj.DeviceName]));
        end

        function out = get.BitDepth(obj)
            % return bitrate of current video mode setting
            if obj.Available
                tmp  = ones(1,obj.DataType); %#ok<NASGU>
                out  = whos('tmp').bytes * 8;

                % qimaging QICam delivers 12 bits instead of 16
                if out == 16 && strcmp(obj.DeviceName,'QICam B')
                    out = 12;
                end
            end
        end

        function out = modes(obj,varargin)
            % return available modes
            if nargin == 3
                adaptor  = varargin{1};
                deviceID = varargin{2};
            else
                adaptor  = obj.Adaptor;
                deviceID = obj.DeviceID;
            end
            out = imaqhwinfo(adaptor,deviceID).SupportedFormats(:);

            % restrict modes to 16bit MONO (supported devices only)
            if contains(obj.DeviceName,'QICam')
                out  = out(contains(out,'MONO16'));
            end

            % sort modes by resolution (if obtainable through regexp)
            tmp = regexpi(out,'^(\w*)_(\d)*x(\d)*$','tokens','once');
            if all(cellfun(@numel,tmp)==3)
                tmp = cat(1,tmp{:});
                tmp(:,2:3) = cellfun(@(x) {str2double(x)},tmp(:,2:3));
                [~,idx] = sortrows(tmp);
                out = out(idx);
            end
        end
    end
    
    methods (Access = {?intrinsic,?subsystemData})
        function start(obj)
            if isrunning(obj.Input.Red)
                error('Camera is already acquiring data.')
            end

            obj.Parent.message('Arming image acquisition')
            
            % TODO: move trigger configuration to setup
            switch obj.Adaptor
                case {'qimaging','mwqimagingimaq'}
                    triggerconfig(obj.Input.Red,'hardware','risingEdge','TTL')
                case 'hamamatsu'
                    triggerconfig(obj.Input.Red,'hardware','risingEdge','EdgeTrigger')
            end
            
            flushdata(obj.Input.Red)
            obj.Input.Red.TriggerRepeat = Inf;
            obj.Input.Red.FramesPerTrigger = 1;
            obj.Input.Red.FramesAcquiredFcn = @obj.displayFrameCount;
            obj.Input.Red.FramesAcquiredFcnCount = 1;
            start(obj.Input.Red)
        end
        
        function stop(obj)
            stop(obj.Input.Red)
            pause(.1)
        end
        
%         function [data,metadata] = getData(obj)
%             nframes = obj.Input.Red.FramesAvailable;
%             if ~nframes
%                 data = [];
%                 metadata = [];
%                 return
%             end
%             obj.Parent.message('Obtaining %d frames from camera',nframes)
%             [data,~,metadata] = getdata(obj.Input.Red,nframes);
%         end
        
        function save(obj,fn)
            if isempty(obj.Data)
                return
            end
            
            obj.Parent.message('Saving image data to disk')
            tiff = Tiff(fn,'w');
            options = struct( ...
                'ImageWidth',          size(obj.Data,2), ...
                'ImageLength',         size(obj.Data,1), ...
                'Photometric',         Tiff.Photometric.MinIsBlack, ...
                'Compression',         Tiff.Compression.LZW, ...
                'PlanarConfiguration', Tiff.PlanarConfiguration.Chunky, ...
                'BitsPerSample',       16, ...
                'SamplesPerPixel',     size(obj.Data,3), ...
                'XResolution',         round(obj.Parent.Scale.PxPerCm), ...
                'YResolution',         round(obj.Parent.Scale.PxPerCm), ...
                'ResolutionUnit',      Tiff.ResolutionUnit.Centimeter, ...
                'Software',            'Intrinsic Imaging', ...
                'Make',                'adaptor', ...
                'Model',               'device', ...
                'DateTime',            datestr(now,'yyyy:mm:dd HH:MM:SS'), ...
                'ImageDescription',    sprintf(...
                    'ImageJ=\nimages=%d\nframes=%d\nslices=1\nhyperstack=false\nunit=cm\nfinterval=%0.5f\nfps=%0.5f\n', ...
                    size(obj.Data,4),size(obj.Data,4),1/obj.FrameRate,obj.FrameRate), ...
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

    methods (Access = private)
        bitrate(obj)
        cbAbort(obj,~,~)
        cbAdapt(obj,~,~)
        cbDevice(obj,~,~)
        cbFPS(obj,~,~)
        cbMode(obj,~,~)
        cbOkay(obj,~,~)
        cbOVS(obj,~,~)
        cbROI(obj,~,~)
        createInputs(obj)
        toggleCtrls(obj,state)

        function reset(~)
            % disconnect and delete all image acquisition objects
            intrinsic.message('Resetting image acquisition hardware')
            imaqreset
            pause(1)
        end
        
        function displayFrameCount(obj,~,~)
            string = sprintf('Trial %d, acquiring frame %d/%d', ...
                obj.Parent.Data.n+1,obj.Input.Red.FramesAvailable,...
                obj.Parent.DAQ.nTrigger);
            obj.Parent.status(string)
        end
    end
end
