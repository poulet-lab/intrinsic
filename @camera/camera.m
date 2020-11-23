classdef camera < handle

    properties (SetAccess = private)
        Adaptor      = 'none';                      % Selected IMAQ adaptor
        DeviceName   = '';                          % Name of selected device
        DeviceID     = NaN;                         % ID of selected device
        Mode         = '';                          % Selected video mode
        Input        = struct('Green',[],'Red',[]); % Video input objects
        FrameRate    = NaN                          % Frame rate
        Downsample   = 1                            % Averaging of N consecutive frames
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
        MatPrefix = 'camera_'
    end

    properties (Access = private)
        Parent
    end

    properties (Access = private, Transient)
        Figure
    end
    
    events
        SettingsUpdated
    end

    methods
        varargout = setup(obj)

        function obj = camera(parent)
            narginchk(1,1)
            validateattributes(parent,{'intrinsic'},{'scalar'});
            obj.Parent = parent;

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
            sup = {'qimagingQICam B'};
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

        function out = loadVar(obj,var,default)
            out = obj.Parent.loadVar([obj.MatPrefix var],default);
        end

        function saveVar(obj,varName,data)
            obj.Parent.saveVar([obj.MatPrefix varName],data);
        end

        function reset(~)
            % disconnect and delete all image acquisition objects
            fprintf('\nInitializing image acquisition hardware ... ')
            imaqreset
            pause(1)
            fprintf('done.\n')
        end
    end
end
