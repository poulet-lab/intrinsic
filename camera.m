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
        
        function setup(obj)
            % Open GUI to change camera settings.
            
            % some size parameters
            p   = 7;                     	% padding
            wF  = 254;                      % width of figure
            hF  = 370;                    	% height of figure
            wL  = round((wF-3*p)*.4);      	% width of label
            wD  = round((wF-3*p)*.6);   	% width of drop
            wE  = round((wD-p*2)/2);     	% width of mini edit
            wB  = (wF-3*p)/2;             	% width of button
            
            % create figure and controls
            obj.fig = figure(...
                'Visible',      'off', ...
            	'Position',     [100 100 wF hF], ...
            	'Name',         'Camera Settings', ...
                'Resize',       'off', ...
                'ToolBar',      'none', ...
                'WindowStyle',  'modal', ...
                'NumberTitle',  'off', ...
                'Units',        'pixels');
            h.popAdapt = createDrop(1,@obj.cbAdapt,'Adaptor',[{'none'} obj.adaptors]);
            h.popDev   = createDrop(2,@obj.cbDev,'Device',{''});
            h.popMode  = createDrop(3,@obj.cbMode,'Mode',{''});
            h.edtRes   = createEditXY(4,'','Resolution (px)');
            h.edtBin   = createEditXY(5,@obj.cbROI,'Hardware Binning');
            h.edtROI   = createEditXY(6,@obj.cbROI,'ROI (px)');
            h.edtFPS   = createEdit(7,0,@obj.cbFPS,'Frame Rate (Hz)');
            h.edtOVS   = createEdit(8,0,@obj.cbOVS,'Oversampling');
            h.edtScale = createEdit(9,0,'','Scale');
            h.edtBits  = createEdit(10,0,'','Bit Depth (bit)');
            h.edtMbps  = createEdit(11,0,'','Bit Rate (Mbit/s)');
            h.btnOk    = createButton(1,'OK',@obj.cbOk);
            h.btnAbort = createButton(2,'Cancel',@obj.cbAbort);
            setappdata(obj.fig,'handles',h);
            
            % disable some of the controls
            set([h.edtRes h.edtBin h.edtBits h.edtMbps],'Enable','Off');
                                    
            % load values from file
            h.popAdapt.Value = max([find(strcmp(h.popAdapt.String,...
                loadvar(obj,'adaptor',''))) 1]);
            
            % run callback functions
            obj.cbAdapt()
            obj.cbDev()
           
            % initialize
            movegui(obj.fig,'center')
            obj.fig.Visible = 'on';
            
            % helper functions for creating UI controls
            function h = createButton(row,string,cb)
                h = uicontrol(obj.fig,'String',string,'Callback',cb,...
                    'Position', round([p+(row-1)*(wB+p) p wB 23]));
            end
            function h = createLabel(row,string)
                h = uicontrol(obj.fig,'Style','text','String',string, ...
                    'Position', [p hF-row*(p+22) wL 18], ...
                    'HorizontalAlignment', 'right');
            end
            function h = createDrop(row,cb,label,string)
                createLabel(row,label);
                h = uicontrol(obj.fig,'Style','popupmenu','String',string,...
                    'Position',	[2*p+wL hF-row*(p+22) wD 23],'Callback',cb);
            end
            function h = createEdit(row,col,cb,label)
                if exist('label','var'), createLabel(row,label); end
                h = uicontrol(obj.fig,'Style','edit','Callback',cb,...
                    'Position',[2*p+wL+col*(wE+2*p) hF-row*(p+22) wE 23]);
            end
            function h = createEditXY(row,cb,label)
                h(1) = createEdit(row,0,cb,label);
                h(2) = createEdit(row,1,cb);
                uicontrol(obj.fig,'Style','text','String','x',...
                    'Position',[2*p+wL+wE hF-row*(p+22) 2*p 18]);
            end
        end
        
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
    
    methods (Access = private)

        function toggleCtrls(obj,state)
            % toggle controls
            persistent wasOn
            if isempty(ishandle(obj.fig))
                return
            end
            h = getappdata(obj.fig,'handles');
            c = structfun(@(x) x.findobj,h);
            if strcmp(state,'off')
                wasOn = strcmp({c.Enable},'on');
            end
            set(c(wasOn),'Enable',state);
        end
        
        function obj = cbOk(obj,~,~)
            obj.toggleCtrls('off')
            
            % get values
            a   = getappdata(obj.fig,'adaptor');
            id  = getappdata(obj.fig,'deviceID');
            m   = getappdata(obj.fig,'mode');
            res = getappdata(obj.fig,'resolution');
            roi = getappdata(obj.fig,'roi');
            roi = [floor((res-roi)/2) roi];

            % create videoinput objects
            if ~isequal({a,id,m,roi(3:4)},{obj.adaptor,obj.deviceID, ...
                    obj.videoMode,obj.ROI}) && ~strcmp(a,'none')
                obj.inputR = videoinput(a,id,m,'ROIPosition',roi);
                obj.inputG = videoinput(a,id,m,'ROIPosition',roi);
            end
            
            % save values to matfile
            obj.mat.adaptor     = a;
            obj.mat.deviceID    = id;
            obj.mat.deviceName  = getappdata(obj.fig,'deviceName');
            obj.mat.videoMode   = m;
            obj.mat.ROI         = roi;
            
            close(obj.fig)
        end
        
        function cbAbort(obj,~,~)
            close(obj.fig)
        end
        
        function cbAdapt(obj,~,~)
            % Callback for adaptor UI control
                        
            % get currently selected value from UI control
            h       = getappdata(obj.fig,'handles');
            hCtrl   = h.popAdapt;
            value   = hCtrl.String{hCtrl.Value};
            
            % compare with previously selected value (return if identical)
            if isequal(hCtrl.UserData,value)
                return
            end
            hCtrl.UserData = value;

            % skip a bunch of callback if user selects no adaptor ('none')
            if strcmpi(value,'none')
                set([h.popDev h.popMode],...
                    'Value',1,'String',{''},'Enable','off');
                set([h.edtRes(1) h.edtRes(2) h.edtBin(1) h.edtBin(2) ...
                    h.edtROI(1) h.edtROI(2) h.edtBits h.edtMbps],...
                    'String','','Enable','off');
                h.btnOk.Enable = 'on';
                return
            end
            
            % run imaqhwinfo (expensive), save results to appdata
            [~,tmp] = evalc('imaqhwinfo(value)');
            hw      = tmp.DeviceInfo;
            setappdata(obj.fig,'deviceInfo',hw);
            
            % manage UI control for device selection
            if isempty(hw)
                % disable device selection
                h.popDev.Enable	= 'off';
                h.popDev.String = {''};
                h.popDev.Value  = 1;
            else
                % enable device selection, fill device IDs and names
                h.popDev.Enable	= 'on';
                h.popDev.String = cellfun(@(x,y) ...
                    {sprintf('Dev %d: %s',x,y)}, ...
                    {hw.DeviceID},{hw.DeviceName});
                
                % select previously used device if adaptor matches
                if strcmp(value,loadvar(obj,'adaptor',''))
                    h.popDev.Value = max([find([hw.DeviceID]==...
                        loadvar(obj,'deviceID',NaN)) 1]);
                else
                    h.popDev.Value = 1;
                end
            end
            h.popDev.UserData = 'needs to be processed by obj.cbDev';
            
            % run dependent callbacks
            if isCallback
                obj.cbDev(h.popDev)
                %obj.cbOVS(h.edtOVS)
            end
        end
        
        function cbDev(obj,~,~)
            
            % get currently selected value from UI control
            h       = getappdata(obj.fig,'handles');
            hCtrl   = h.popDev;
            value   = hCtrl.String{hCtrl.Value};
            
            % compare with previously selected value (return if identical)
            if isequal(hCtrl.UserData,value)
                return
            end
            hCtrl.UserData = value;
            
            % manage UI control for mode selection
            if isempty(hCtrl.UserData)
                % disable mode selection
                h.popMode.Enable = 'off';
                h.popMode.String = {''};
                h.popMode.Value  = 1;
            else
                % enable mode selection
                h.popMode.Enable = 'on';
                
                % get some variables
                hw      = getappdata(obj.fig,'deviceInfo');
                hw      = hw(hCtrl.Value);
                devID   = hw.DeviceID;
                devName = hw.DeviceName;
                modes   = hw.SupportedFormats(:);
                adapt   = h.popAdapt.UserData;
                                
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
                h.popMode.String = modes;
                
                % select previously used mode if adaptor & device ID match
                if strcmp(adapt,obj.adaptor) && devID==obj.deviceID
                    h.popMode.Value = max([find(strcmp(modes,...
                        obj.loadvar('videoMode',''))) 1]);
                elseif ~isempty(devID)
                    h.popMode.Value = find(strcmp(modes,hw.DefaultFormat));
                else
                    h.popMode.Value = 1;
                end
            end
            h.popMode.UserData = 'needs to be processed by obj.cbMode';
            
            %obj.cbMode(h.popMode)
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
            h   = getappdata(obj.fig,'handles');
            if isempty(m)
                h.edtRes(1).String = '';
                h.edtRes(2).String = '';
                h.edtROI(1).String = '';
                h.edtROI(2).String = '';
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
                h.edtRes(1).String = num2str(res(1));
                h.edtRes(2).String = num2str(res(2));
                h.edtROI(1).String = num2str(res(1));
                h.edtROI(2).String = num2str(res(2));
            end
            setappdata(obj.fig,'resolution',res);
            obj.cbROI()
            
            % fill binning (only on supported cameras)
            if ~isempty(m) && ismember(a,{'qimaging'})
                if ismember(d,{'QICam B'})
                     tmp = getappdata(obj.fig,'modes');
                     tmp = regexpi(tmp,'^\w*_(\d)*x\d*$','tokens','once');
                     bin = max(cellfun(@str2double,[tmp{:}])) / res(1);
                end
            else
                bin = [];
            end
            set([h.edtBin(1) h.edtBin(2)],'String',bin);
            
            % toggle OK button
            tmp = {'on','off'};
            h.btnOk.Enable =  tmp{isempty(m)+1};
            
            % check framerate
            obj.cbFPS(h.edtFPS)
        end
        
        function cbROI(obj, ~, ~)
            h   = getappdata(obj.fig,'handles');
            h   = findobj([h.edtROI(1) h.edtROI(2)])';
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
            h   = getappdata(obj.fig,'handles');
            m   = getappdata(obj.fig,'mode');
            if ~isempty(regexpi(m,'^MONO(\d+)_.*'))
                bitdepth = str2double(...
                    regexpi(m,'^MONO(\d+)_.*','tokens','once'));
            elseif ~isempty(regexpi(m,'^YUY2_.*'))
                bitdepth = 8;
            else
                h.edtMbps.String = '';
                return
            end
            
            h.edtBits.String = bitdepth;
            %bitdepth
            
            a   = getappdata(obj.fig,'adaptor');
            id  = getappdata(obj.fig,'deviceID');
            %imaqhwinfo(a,id)
            
            roi = getappdata(obj.fig,'roi');
            fps = getappdata(obj.fig,'rate');
            ovs = getappdata(obj.fig,'oversampling');

            h.edtMbps.String = sprintf('%0.1f',...
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