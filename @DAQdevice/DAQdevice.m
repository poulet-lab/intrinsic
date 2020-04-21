classdef DAQdevice < handle

    properties (SetAccess = private)
        interface
    end
    
    properties (Access = private)
        fig
        matPrefix = 'DAQ_'
    end

    properties (Constant = true, Access = private)
        % is the Data Acquisition Toolbox both installed and licensed?
        toolbox = ~isempty(ver('DAQ')) && license('test','data_acq_toolbox');

        % supported vendors
        supportedVendors = {'ni'};
        
        % supported channel types
        channelTypesOut  = {'AnalogOutput','DigitalIO'};
        channelTypesIn   = {'AnalogInput','DigitalIO'};
    end

    properties (SetAccess = immutable, GetAccess = private)
        channelProp
        nChannelsOut
        nChannelsIn
        mat
    end
    
    properties (Dependent = true)
        available
        triggerAmplitude
    end

    methods
        function obj = DAQdevice(varargin)

            % parse input arguments
            p = inputParser;
            addRequired(p,'MatFile',@(n)validateattributes(n,...
                {'matlab.io.MatFile'},{'scalar'}))
            parse(p,varargin{:})
            obj.mat = p.Results.MatFile;
            
            % check for Data Acquisition Toolbox
            if ~obj.toolbox
                warning('Image Acquisition Toolbox is not available.')
                return
            end

            % reset Data Acquisition Toolbox
            disp('Resetting Data Acquisition Toolbox ...')
            daqreset

            % define immutable channel properties
            tmp(1,:) = {'out','out','in'};
            tmp(2,:) = {'Stimulus','Camera Trigger','Camera Sync'};
            tmp{3,1} = {'AnalogOutput'};
            tmp{3,2} = {'AnalogOutput','DigitalIO'};
            tmp{3,3} = {'AnalogInput','DigitalIO'};
            obj.channelProp	 = cell2struct(tmp,{'flow','label','types'});
            obj.nChannelsOut = sum(matches({obj.channelProp.flow},'out'));
            obj.nChannelsIn  = sum(matches({obj.channelProp.flow},'in'));

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

            % try to create DAQ interface
            obj.createInterface
        end

        function out = get.available(obj)
            out = false;
            if isa(obj.interface,'daq.interfaces.DataAcquisition')
                out = numel(obj.interface.Channels) == ...
                        obj.nChannelsOut + obj.nChannelsIn;
            end
        end
        
        function out = get.triggerAmplitude(obj)
            out = obj.loadVar('triggerAmp',[]);
        end
        
        setup(obj)
    end
    
    methods (Access = private)
        
        % callback and helper functions are in separate files
        cbVendor(obj,~,~)
        cbDevice(obj,~,~)
        cbChannel(obj,~,~)
        cbRate(obj,~,~)
        cbTriggerAmp(obj,~,~)
        toggleCtrls(obj,state)
        createInterface(obj)
        
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
        
        function out = vendors(obj)
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
            
            % limit to devices with sufficient number of channels
            nIn	 = arrayfun(@(x) numel(obj.channelNames(x, ...
                obj.channelTypesIn)), out.DeviceInfo);
            nOut = arrayfun(@(x) numel(obj.channelNames(x, ...
                obj.channelTypesOut)),out.DeviceInfo);
            out = out(nIn >= obj.nChannelsIn & nOut >= obj.nChannelsOut,:);
            
            % limit to specific device
            if ~isempty(out) && ~isempty(deviceID)
                out = out(out.DeviceID.matches(deviceID),:);
            end
        end
        
        function out = subsystems(~,deviceInfo,types)
            % limit to clocked subsystems
            out = deviceInfo.Subsystems;
            out = out(arrayfun(@(x) x.RateLimit(2)>0,out));
            
            % limit to specified types
            if nargin > 2 && ~isempty(out)
                out = out(matches({out.SubsystemType},types));
            end
        end
        
        function out = channelNames(obj,varargin)
            subsystems = obj.subsystems(varargin{:});
            if isempty(subsystems)
                out = {};
            else
                out = vertcat(subsystems.ChannelNames);
            end
        end
    end
end
