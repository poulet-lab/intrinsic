classdef DAQdevice < handle

    properties (SetAccess = private)
        session
    end

    properties (Access = private)
        fig
    end

    properties (Constant = true, Access = private)
        % is the Data Acquisition Toolbox both installed and licensed?
        toolbox = ~isempty(ver('DAQ')) && license('test','data_acq_toolbox');

        % supported vendors
        supportedVendors = {'ni'};

        % supported channel types
        channelTypesOut  = {'AnalogOutput','DigitalIO'};
        channelTypesIn   = {'AnalogInput','DigitalIO'};

        % prefix for variables in matfile
        matPrefix = 'DAQ_'
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

    properties (Dependent = true, GetAccess = private)
        vendors
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
                warning('Data Acquisition Toolbox is not available.')
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

            % try to create DAQ session
            obj.createSession
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

        function out = get.vendors(obj)
            out = daq.getVendors;
            out(~[out.IsOperational]) = [];
            out(~ismember({out.ID},obj.supportedVendors)) = [];
        end

        setup(obj)
    end

    methods (Access = private)

        % callbacks and some helper functions are in separate files
        cbVendor(obj,~,~)
        cbDevice(obj,~,~)
        cbChannel(obj,~,~)
        cbRate(obj,~,~)
        cbTriggerAmp(obj,~,~)
        toggleCtrls(obj,state)
        createSession(obj)

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

        function d = devices(obj,vendorID,deviceID)
            % get list of devices
            disableVendorDiagnostics
            d = daq.getDevices;
            enableVendorDiagnostics
            if isempty(d)
                return
            end

            % filter for vendor ID
            if nargin < 2
                vendorID = obj.supportedVendors;
            else
                vendorID = intersect(vendorID,obj.supportedVendors);
            end
            d(~matches(arrayfun(@(x) {x.ID},[d.Vendor]),vendorID)) = [];

            % filter for deviceID argument
            if nargin > 2
                d(~ismember({d.ID},deviceID)) = [];
            end

            % limit to devices with sufficient number of channels
            nIn	 = arrayfun(@(x) numel(obj.channelNames(x, ...
                obj.channelTypesIn)), d);
            nOut = arrayfun(@(x) numel(obj.channelNames(x, ...
                obj.channelTypesOut)),d);
            d(nIn < obj.nChannelsIn | nOut < obj.nChannelsOut) = [];
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
