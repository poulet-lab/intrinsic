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
        imaq    = ~isempty(ver('IMAQ')) && ...
            license('test','image_acquisition_toolbox');
        % matfile for storage of settings
        mat     = matfile([mfilename('fullpath') '.mat'],'Writable',true)
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
            if ~obj.imaq    
                return
            end
            if isa(obj.inputG,'videoinput') && isa(obj.inputR,'videoinput')
                out = isvalid(obj.inputG) && isvalid(obj.inputR);
            end
        end
    end
    
    
    methods
        function obj = camera(varargin)
            % CAMERA  handle camera settings for INTRINSIC
               
            % check for IMAQ toolbox
            if ~obj.imaq
                warning('Image Acquisition Toolbox is not available.')
                return
            end
            
            % disconnect and delete all image acquisition objects
            imaqreset
            
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
            if ~obj.imaq
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
        cbOkay(obj,~,~)
        
        function cbAbort(obj,~,~)
            close(obj.fig)
        end
        
        function cbDev(obj,~,~)
            
            % get currently selected value from UI control
            h       = getappdata(obj.fig,'controls');
            hCtrl   = h.device;
            value   = hCtrl.String{hCtrl.Value};
            
            % compare with previously selected value (return if identical)
            if isequal(hCtrl.UserData,value)
                return
            end
            hCtrl.UserData = value;
            
            % manage UI control for mode selection
            if isempty(hCtrl.UserData)
                % disable mode selection
                h.mode.Enable = 'off';
                h.mode.String = {''};
                h.mode.Value  = 1;
            else
                % enable mode selection
                h.mode.Enable = 'on';
                
                % get some variables
                hw      = getappdata(obj.fig,'deviceInfo');
                hw      = hw(hCtrl.Value);
                devID   = hw.DeviceID;
                devName = hw.DeviceName;
                modes   = hw.SupportedFormats(:);
                adapt   = h.adaptor.UserData;
                                
                % restrict modes to 16bit MONO (supported devices only)
                if ~isempty(regexpi(devName,'^QICam'))
                    modes(cellfun(@isempty,regexpi(modes,'^MONO16'))) = [];
                end
                
                % sort modes by resolution (if obtainable through regexp)
                tmp = regexpi(modes,'^(\w*)_(\d)*x(\d)*$','tokens','once');
                if all(cellfun(@numel,tmp)==3)
                    tmp = cat(1,tmp{:});
                    tmp(:,2:3) = cellfun(@(x) {str2double(x)},tmp(:,2:3));
                    [~,idx] = sortrows(tmp);
                    modes = modes(idx);
                end
                
                % fill modes, save to appdata for later use
                setappdata(obj.fig,'modes',modes);
                h.mode.String = modes;
                
                % select previously used mode if adaptor & device ID match
                if strcmp(adapt,obj.adaptor) && devID==obj.deviceID
                    h.mode.Value = max([find(strcmp(modes,...
                        obj.loadvar('videoMode',''))) 1]);
                elseif ~isempty(devID)
                    h.mode.Value = find(strcmp(modes,hw.DefaultFormat));
                else
                    h.mode.Value = 1;
                end
            end
            h.mode.UserData = 'needs to be processed by obj.cbMode';
            
            %obj.cbMode(h.mode)
        end
        
        function cbMode(obj, hCtrl, ~)
            % read value from control
            m   = hCtrl.String{hCtrl.Value};
            setappdata(obj.fig,'mode',m);
            
            % find some more variables
            d   = getappdata(obj.fig,'deviceName');
            a 	= getappdata(obj.fig,'adaptor');
            id  = getappdata(obj.fig,'deviceID');
            
            % fill video resolution and ROI
            h   = getappdata(obj.fig,'controls');
            if isempty(m)
                h.res(1).String = '';
                h.res(2).String = '';
                h.ROI(1).String = '';
                h.ROI(2).String = '';
                res = [NaN NaN];
            else
                % Try to get the resolution of the selected mode via regex.
                % In case of a non-standard name create a temporary video
                % input object and get the resolution from there.
                regex = regexpi(m,'^\w*_(\d)*x(\d)*$','tokens','once');
                if ~isempty(regex)
                    res = str2double(regex);
                else
                    obj.toggleCtrls('off')
                    tmp = videoinput(a,id,m);
                    res = tmp.VideoResolution;
                    delete(tmp)
                    obj.toggleCtrls('on')
                end
                h.res(1).String = num2str(res(1));
                h.res(2).String = num2str(res(2));
                h.ROI(1).String = num2str(res(1));
                h.ROI(2).String = num2str(res(2));
            end
            setappdata(obj.fig,'resolution',res);
            obj.cbROI()
            
            % fill binning (only on supported cameras)
            if ~isempty(m)
                if ismember(a,{'qimaging'}) && ismember(d,{'QICam B'})
                     tmp = getappdata(obj.fig,'modes');
                     tmp = regexpi(tmp,'^\w*_(\d)*x\d*$','tokens','once');
                     bin = max(cellfun(@str2double,[tmp{:}])) / res(1);
                end
            else
                bin = [];
            end
            set([h.binning(1) h.binning(2)],'String',bin);
            
            % toggle OK button
            tmp = {'on','off'};
            h.btnOk.Enable =  tmp{isempty(m)+1};
            
            % check framerate
            obj.cbFPS(h.FPS)
        end
        
        function cbROI(obj, ~, ~)
            h   = getappdata(obj.fig,'controls');
            h   = findobj([h.ROI(1) h.ROI(2)])';
            roi = round(str2double({h.String}));
            if isequal(getappdata(obj.fig,'roi'),roi)
                return
            end
                
            res = getappdata(obj.fig,'resolution');
            if isempty(res) || any(isnan(res))
                roi = [NaN NaN];
                set(h,'String','','Enable','Off')
            else
                idx = isnan(roi) | (roi > res) | (roi < 0);
                roi(idx) = res(idx);
                arrayfun(@(x,y) set(x,'String',num2str(y)),h,roi)
                set(h,'Enable','On')
            end
            setappdata(obj.fig,'roi',roi);
            obj.bitrate
        end
        
        function cbFPS(obj, hCtrl, ~)
            fps = round(str2double(hCtrl.String));
            a   = getappdata(obj.fig,'adaptor');
            d   = getappdata(obj.fig,'deviceName');
            
            % limit rates for qimaing QICam B
            if strcmpi([a d],'qimagingQICam B')
                res = getappdata(obj.fig,'resolution');
                switch res(2)
                    case 130
                        lims = [1 59];
                    case 260
                        lims = [1 36];
                    case 520
                        lims = [1 19];
                    case 1040
                        lims = [1 6];
                end
            else
                lims = [1 60];
            end
            
            fps = max([fps min(lims)]);
            fps = min([fps max(lims)]);
            
            hCtrl.String = num2str(fps);
            setappdata(obj.fig,'rate',fps);
            obj.bitrate
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
        
        function out = loadvar(obj,var,default)
            % load variable from matfile or return default if non-existant
            out = default;
            if ~exist(obj.mat.Properties.Source,'file')
                return
            elseif ~isempty(who('-file',obj.mat.Properties.Source,var))
                out = obj.mat.(var);
            end
        end
    end
end