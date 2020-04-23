classdef camera < handle

    properties (Dependent = true, SetAccess = private)
        adaptor     % Specifies the selected IMAQ adaptor
        deviceID    % Identifies a specific device avaiable through ADAPTOR
        deviceName  % Name of the selected device
        videoMode   % Selected video mode
        dataType    % Data type returned by the imaging adaptor
        videoBits   % Bit depth of captured images
        resolution  % Width and height of captured images
        ROI         % Width and height of the current region of interest
        binning     % Level of hardware binning (only on supported devices)
        available   % Is the selected device available?
        supported   % Is the selected device supported?
    end
    
    properties (SetAccess = private)
        inputR  = []            % Video input object (red channel)
        inputG  = []            % Video input object (green channel)
        scale   = 1             % Scale of image when displayed on screen
        rate    = 1             % Frame rate during image acquisition
        oversampling(1,1) = 1   % Averaging of N consecutive frames
    end

    properties (Constant = true, Access = private)
        % is the Image Acquisition Toolbox both installed and licensed?
        toolbox = ~isempty(ver('IMAQ')) && ...
            license('test','image_acquisition_toolbox');
        
        % prefix for variables in matfile
        matPrefix = 'DAQ_'
    end
    
    properties (SetAccess = immutable, GetAccess = private)
        mat         % matfile for storage of settings
    end

    properties (Access = private)
        fig
    end

    properties (Dependent = true, Access = private)
        adaptors
        devices
    end

    % good
    methods
     	function out = get.videoMode(obj)
            % return video mode
            if obj.available
                out = obj.inputG.VideoFormat;
            else
                out = '';
            end
        end

        function out = get.resolution(obj)
            % return resolution
            if obj.available
                out = obj.inputG.VideoResolution;
            else
                out = [NaN NaN];
            end
        end

        function out = get.ROI(obj)
            % return ROI
            if obj.available
                out = obj.inputG.ROIPosition;
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
                out = imaqhwinfo(obj.inputG).NativeDataType;
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
            if isa(obj.inputG,'videoinput') && isa(obj.inputR,'videoinput')
                out = isvalid(obj.inputG) && isvalid(obj.inputR);
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

            % disconnect and delete all image acquisition objects
            disp('Disconnecting and deleting all IMAQ objects ...')
            imaqreset
            pause(1)

            % check for installed adapters
            if isempty(obj.adaptors)
                warning('No IMAQ adapters available.')
            end

            % only proceed if the matfile contains all necessary variables
            doLoad = {'adaptor','deviceID','deviceName','videoMode','ROI'};
            if ~all(cellfun(@(x) any(strcmp(x,who(obj.mat))),doLoad))
                warning('No camera device has been configured.')
                return
            end

            % if the previously saved adaptor exists and both device ID and
            % device name match up: create the video input objects
            if any(strcmp(obj.adaptor,obj.adaptors))
                IDs = [imaqhwinfo(obj.adaptor).DeviceIDs{:}];
                if ismember(obj.deviceID,IDs)
                    d = imaqhwinfo(obj.adaptor,obj.deviceID);
                    if strcmp(obj.deviceName,d.DeviceName) && any(...
                            strcmp(obj.mat.videoMode,d.SupportedFormats))
                        obj.inputR = videoinput(obj.adaptor,...
                            obj.deviceID,obj.mat.videoMode,...
                            'ROIPosition',obj.mat.ROI);
                        obj.inputG = videoinput(obj.adaptor,...
                            obj.deviceID,obj.mat.videoMode,...
                            'ROIPosition',obj.mat.ROI);
                    end
                else
                    warning(['Cannot find device ''%s'' for the ''%s'' ' ...
                        'adaptor - did you forget to switch it on?'],...
                        obj.mat.deviceName,obj.adaptor)
                end
            end
        end
    end

    % public methods (defined in separate files)
    methods
        setup(obj)

        function out = get.adaptors(~)
            % returns a cell of installed IMAQ adaptors
            out = eval('imaqhwinfo').InstalledAdaptors;
        end

        function out = get.devices(obj)
            % returns a struct of available IMAQ devices with the following
            % details: IMAQ adaptor, device name and device ID
            out = struct([]);
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

        % GET methods related to matfile
        function out = get.adaptor(obj)
            out = loadvar(obj,'adaptor',[]);
        end
        function out = get.deviceName(obj)
            out = loadvar(obj,'deviceName','');
        end
        function out = get.deviceID(obj)
            out = loadvar(obj,'deviceID',[]);
        end

        % SET methods related to matfile
        function set.adaptor(obj,val)
            obj.mat.adaptor = val;
        end
        function set.deviceName(obj,val)
            obj.mat.deviceName = val;
        end
        function set.deviceID(obj,val)
            obj.mat.deviceID = val;
        end
    end

    % private methods (defined in separate files)
    methods (Access = private)

        toggleCtrls(obj,state)
        cbAdapt(obj,~,~)
        cbDevice(obj,~,~)
        cbMode(obj,~,~)
        cbROI(obj,~,~)
        cbFPS(obj,~,~)
        cbOkay(obj,~,~)
        

        function cbAbort(obj,~,~)
            close(obj.fig)
        end

        function cbOVS(obj, hCtrl, ~)
            ovs = max([1 real(round(str2double(hCtrl.String)))]);
            hCtrl.String = ovs;
            setappdata(obj.fig,'oversampling',ovs);
            obj.bitrate
        end

        function bitrate(obj)

            % try to obtain bitdepth from mode name
            h   = getappdata(obj.fig,'controls');
            m   = getappdata(obj.fig,'mode');
            if ~isempty(regexpi(m,'^MONO(\d+)_.*'))
                bitdepth = str2double(...
                    regexpi(m,'^MONO(\d+)_.*','tokens','once'));
            elseif ~isempty(regexpi(m,'^YUY2_.*'))
                bitdepth = 8;
            else
                h.bitRate.String = '';
                return
            end

            h.bitDepth.String = bitdepth;
            %bitdepth

            a   = getappdata(obj.fig,'adaptor');
            id  = getappdata(obj.fig,'deviceID');
            %imaqhwinfo(a,id)

            roi = getappdata(obj.fig,'roi');
            fps = getappdata(obj.fig,'rate');
            ovs = getappdata(obj.fig,'oversampling');

            h.bitRate.String = sprintf('%0.1f',...
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
