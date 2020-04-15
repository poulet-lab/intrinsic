classdef DAQdevice < handle

    properties (SetAccess = private)
        interface
    end
    
    properties (Access = private)
        fig
    end

    properties (Constant = true, Access = private)

        % is the Data Acquisition Toolbox both installed and licensed?
        toolbox = ~isempty(ver('DAQ')) && license('test','data_acq_toolbox');

        % matfile for storage of settings
        mat     = matfile([mfilename('fullpath') '.mat'],'Writable',true)

        % list of supported vendors
        supportedVendors = {'ni'};
    end

    properties (SetAccess = immutable, GetAccess = private)
        %devices
        vendors
    end

    methods
        function obj = DAQdevice(varargin)

            % check for Data Acquisition Toolbox
            if ~obj.toolbox
                warning('Image Acquisition Toolbox is not available.')
                return
            end

            % reset Data Acquisition Toolbox
            disp('Resetting Data Acquisition Toolbox ...')
            daqreset

            % check for supported & operational DAQ vendors
            if isempty(obj.vendors)
                warning(['No operational DAQ vendors available. Use ' ...
                    'MATLAB''s Add-On Explorer to install the ' ...
                    'respective support packages.'])
                return
            end

            % check for available devices
            if isempty(obj.devices)
                warning('No supported data acquisition devices found.')
                return
            end

        end

        function out = get.vendors(obj)
            % get list of vendors
            [vendorList,tmp] = daqvendorlist;
            if isempty(tmp)
                out = {};
                return
            end

            % limit to supported and operational vendors
            operational = [tmp.IsOperational] == true;
            supported   = matches({tmp.ID},obj.supportedVendors);
            tmp  = tmp(operational & supported);
            if isempty(tmp)
                out = table('Size',[0 0]);
            else
                out = vendorList(vendorList.ID.matches({tmp.ID}),:);
            end
        end
        
        setup(obj)
    end

    methods (Access = private)
        cbVendor(obj,~,~)
        cbDevice(obj,~,~)
        
        function out = loadvar(obj,var,default)
            % load variable from matfile or return default if non-existant
            out = default;
            if ~exist(obj.mat.Properties.Source,'file')
                return
            elseif ~isempty(who('-file',obj.mat.Properties.Source,var))
                out = obj.mat.(var);
            end
        end
        
        function out = devices(obj,vendorID,deviceID)
            % manage arguments
            if nargin < 2, vendorID = obj.supportedVendors; end
            if nargin < 3, deviceID = ''; end
            
            % get list of devices
            disableVendorDiagnostics
            out = daqlist('all');
            enableVendorDiagnostics

            % limit to supported vendors
            if isempty(out)
                out = table('Size',[0 0]);
            else
                tmp = intersect(obj.supportedVendors,vendorID);
                out = out(out.VendorID.matches(tmp),:);
            end
            
            % limit to specific device
            if ~isempty(out) && ~isempty(deviceID)
                out = out(out.DeviceID.matches(deviceID),:);
            end
        end
        
        function out = subsystems(obj,vendorID,deviceID,types)
            % get device info
            deviceInfo = obj.devices(vendorID,deviceID).DeviceInfo;
            if isempty(deviceInfo)
                out = [];
                return
            end
            
            % limit to clocked subsystems
            out = deviceInfo.Subsystems;
            out = out(arrayfun(@(x) x.RateLimit(2)>0,out));
            
            % limit to specific types
            if nargin > 3 && ~isempty(out)
                out = out(matches({out.SubsystemType},types));
            end
        end
        
        function out = channels(obj,varargin)
            narginchk(3,4)
            subsystems = obj.subsystems(varargin{:});
            if isempty(subsystems)
                out = {};
            else
                out = vertcat(subsystems.ChannelNames);
            end
        end
    end
end
