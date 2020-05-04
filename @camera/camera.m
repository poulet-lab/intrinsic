classdef camera < handle

    properties (Dependent = true, SetAccess = private)
        dataType    % Data type returned by the imaging adaptor
        videoBits   % Bit depth of captured images
        resolution  % Width and height of captured images
        ROI         % Width and height of the current region of interest
        binning     % Level of hardware binning (only on supported devices)
        available   % Is the selected device available?
        supported   % Is the selected device supported?
    end
    
    properties (SetAccess = private)
        adaptor      = 'none';                      % Selected IMAQ adaptor
        deviceName   = '';                          % Name of selected device
        deviceID     = NaN;                         % ID of selected device
        mode         = '';                          % Selected video mode
        input        = struct('green',[],'red',[]); % video input objects
        rate         = NaN                          % configured frame rate
        oversampling = 1                            % Averaging of N consecutive frames
    end

    properties (Constant = true, Access = private)
        % is the Image Acquisition Toolbox both installed and licensed?
        toolbox = ~isempty(ver('IMAQ')) && ...
            license('test','image_acquisition_toolbox');
        
        % prefix for variables in matfile
        matPrefix = 'camera_'
    end
    
    properties (SetAccess = immutable, GetAccess = private)
        mat         % matfile for storage of settings
    end

    properties (Access = private)
        fig
    end

    methods
        function out = get.resolution(obj)
            % return resolution
            if obj.available
                out = obj.input.green.VideoResolution;
            else
                out = [NaN NaN];
            end
        end

        function out = get.ROI(obj)
            % return ROI
            if obj.available
                out = obj.input.green.ROIPosition;
                out = out(3:4);
            else
                out = [NaN NaN];
            end
        end

        function out = get.binning(obj)
            % return binning factor (only supported devices)
            out = NaN;
            if obj.available && strcmp(obj.deviceName,'QICam B')
                tmp = imaqhwinfo(obj.adaptor,obj.deviceID).SupportedFormats;
                tmp = regexpi(tmp,'^\w*_(\d)*x\d*$','tokens','once');
                out = max(cellfun(@str2double,[tmp{:}]))/obj.resolution(1);
            end
        end

        function out = get.dataType(obj)
            % return data type returned from imaging adapter
            if obj.available
                out = imaqhwinfo(obj.input.green).NativeDataType;
            else
                out = NaN;
            end
        end

        function out = get.videoBits(obj)
            % return bitrate of current video mode setting
            if obj.available
                tmp  = ones(1,obj.dataType); %#ok<NASGU>
                out  = whos('tmp').bytes * 8;

                % qimaging QICam delivers 12 bits instead of 16
                if out == 16 && strcmp(obj.deviceName,'QICam B')
                    out = 12;
                end
            end
        end

        function out = get.available(obj)
            % return availability of configured video device
            out = false;
            if ~obj.toolbox
                return
            end
            if all(structfun(@(x) isa(x,'videoinput'),obj.input))
                out = all(structfun(@isvalid,obj.input));
            end
        end
    end


    methods
        function obj = camera(varargin)

            % parse input arguments
            p = inputParser;
            addRequired(p,'MatFile',@(n)validateattributes(n,...
                {'matlab.io.MatFile'},{'scalar'}))
            parse(p,varargin{:})
            obj.mat = p.Results.MatFile;
            
            % check for IMAQ toolbox
            if ~obj.toolbox
                warning('Image Acquisition Toolbox is not available.')
                return
            end

            % check for installed adapters
            if isempty(obj.adaptors)
                warning('No IMAQ adapters installed.')
            end
            
            % disconnect and delete all image acquisition objects
            fprintf('\nDisconnecting and deleting all IMAQ objects ... ')
            imaqreset
            pause(1)
            fprintf('done.\n')

            % try to create DAQ session
            obj.createInputs()
        end
    end

    methods
        varargout = setup(obj)

        function out = adaptors(~)
            % returns a cell of installed IMAQ adaptors
            out = eval('imaqhwinfo').InstalledAdaptors;
        end

        function out = devices(obj)
            % returns a struct of available IMAQ devices with the following
            % details: IMAQ adaptor, device name and device ID
            out    = struct('adaptor',[],'deviceName',[],'deviceID',[]);
            out(1) = [];
            if ~obj.toolbox
                return
            end
            for a = obj.adaptors
                for tmp = imaqhwinfo(a{:}).DeviceInfo
                    ii  = numel(out) + 1;
                    out(ii).adaptor    = a{:};
                    out(ii).deviceName = tmp.DeviceName;
                    out(ii).deviceID   = tmp.DeviceID;
                end
            end
        end

        function out = get.supported(obj)
            % is the combination of adaptor + device tested & "supported"?
            sup = {'qimagingQICam B'};
            out = any(strcmpi(sup,[obj.adaptor obj.deviceName]));
        end

    end

    % private methods (defined in separate files)
    methods (Access = private)

        createInputs(obj)
        toggleCtrls(obj,state)
        cbAdapt(obj,~,~)
        cbDevice(obj,~,~)
        cbMode(obj,~,~)
        cbROI(obj,~,~)
        cbFPS(obj,~,~)
        cbOVS(obj,~,~)
        cbOkay(obj,~,~)

        function cbAbort(obj,~,~)
            close(obj.fig)
        end

        function bitrate(obj)

            % try to obtain bitdepth from mode name
            ctrl = getappdata(obj.fig,'controls');
            mode = getappdata(obj.fig,'mode'); %#ok<*PROP>
            if ~isempty(regexpi(mode,'^MONO(\d+)_.*'))
                bitdepth = str2double(...
                    regexpi(mode,'^MONO(\d+)_.*','tokens','once'));
            elseif ~isempty(regexpi(mode,'^YUY2_.*'))
                bitdepth = 8;
            else
                ctrl.bitRate.String = '';
                return
            end

            roi = getappdata(obj.fig,'roi');
            fps = getappdata(obj.fig,'rate');
            ovs = getappdata(obj.fig,'oversampling');

            ctrl.bitRate.String = sprintf('%0.1f',...
                (bitdepth * prod(roi) * fps) / (ovs * 1E6));
        end

        function out = loadVar(obj,var,default)
            % load variable from matfile or return default if non-existant
            out = default;
            if ~exist(obj.mat.Properties.Source,'file')
                return
            else
                var = [obj.matPrefix var];
                if ~isempty(who('-file',obj.mat.Properties.Source,var))
                    out = obj.mat.(var);
                end
            end
        end
        
        function saveVar(obj,varName,data)
            obj.mat.([obj.matPrefix varName]) = data;
        end
    end
end
