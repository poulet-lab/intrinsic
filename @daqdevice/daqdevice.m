classdef daqdevice < handle

    properties (SetAccess = private)
        Session
    end

    properties (Access = private)
        Figure
    end

    properties (Constant = true, Access = private)
        % is the Data Acquisition Toolbox both installed and licensed?
        Toolbox = ~isempty(ver('DAQ')) && license('test','data_acq_toolbox');

        % supported vendors
        SupportedVendors = {'ni'};

        % supported channel types
        ChannelTypesOut  = {'AnalogOutput','DigitalIO'};
        ChannelTypesIn   = {'AnalogInput','DigitalIO'};

        % prefix for variables in matfile
        MatPrefix = 'DAQ_'
    end

    properties (SetAccess = immutable, GetAccess = private)
        ChannelProp
        NChannelsOut
        NChannelsIn
        Matfile
    end

    properties (Dependent = true)
        Available
        TriggerAmplitude
    end

    properties (Dependent = true, GetAccess = private)
        Vendors
    end

    methods
        function obj = daqdevice(varargin)

            % parse input arguments
            narginchk(1,1)
            p = inputParser;
            addRequired(p,'MatFile',@(n)validateattributes(n,...
                {'matlab.io.MatFile'},{'scalar'}))
            parse(p,varargin{:})
            obj.Matfile = p.Results.MatFile;

            % check for Data Acquisition Toolbox
            if ~obj.Toolbox
                warning('Data Acquisition Toolbox is not available.')
                return
            end

            % reset Data Acquisition Toolbox
            fprintf('\nResetting Data Acquisition Toolbox ... ')
            daqreset
            fprintf('done.\n')

            % define immutable channel properties
            tmp(1,:) = {'out','out','in'};
            tmp(2,:) = {'Stimulus','Camera Trigger','Camera Sync'};
            tmp{3,1} = {'AnalogOutput'};
            tmp{3,2} = {'AnalogOutput','DigitalIO'};
            tmp{3,3} = {'AnalogInput','DigitalIO'};
            obj.ChannelProp	 = cell2struct(tmp,{'flow','label','types'});
            obj.NChannelsOut = sum(matches({obj.ChannelProp.flow},'out'));
            obj.NChannelsIn  = sum(matches({obj.ChannelProp.flow},'in'));

            % check for supported & operational DAQ vendors
            if isempty(obj.Vendors)
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

        function out = get.Available(obj)
            out = false;
            if isa(obj.Session,'daq.Session')
                out = numel(obj.Session.Channels) == ...
                        obj.NChannelsOut + obj.NChannelsIn;
            end
        end

        function out = get.TriggerAmplitude(obj)
            out = obj.loadVar('triggerAmp',[]);
        end

        function out = get.Vendors(obj)
            out = daq.getVendors;
            out(~[out.IsOperational]) = [];
            out(~ismember({out.ID},obj.SupportedVendors)) = [];
        end

        varargout = setup(obj)
    end

    methods (Access = private)

        % callbacks and some helper functions are in separate files
        cbChannel(obj,~,~)
        cbDevice(obj,~,~)
        cbOkay(obj,~,~)
        cbRate(obj,~,~)
        cbTriggerAmp(obj,~,~)
        cbVendor(obj,~,~)
        createSession(obj)
        toggleCtrls(obj,state)

        function out = loadVar(obj,var,default)
            % load variable from matfile or return default if non-existant
            out = default;
            if ~exist(obj.Matfile.Properties.Source,'file')
                return
            else
                var = [obj.MatPrefix var];
                if ~isempty(who('-file',obj.Matfile.Properties.Source,var))
                    out = obj.Matfile.(var);
                end
            end
        end

        function saveVar(obj,varName,data)
            obj.Matfile.([obj.MatPrefix varName]) = data;
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
                vendorID = obj.SupportedVendors;
            else
                vendorID = intersect(vendorID,obj.SupportedVendors);
            end
            d(~matches(arrayfun(@(x) {x.ID},[d.Vendor]),vendorID)) = [];

            % filter for deviceID argument
            if nargin > 2
                d(~ismember({d.ID},deviceID)) = [];
            end

            % limit to devices with sufficient number of channels
            nIn	 = arrayfun(@(x) numel(obj.channelNames(x, ...
                obj.ChannelTypesIn)), d);
            nOut = arrayfun(@(x) numel(obj.channelNames(x, ...
                obj.ChannelTypesOut)),d);
            d(nIn < obj.NChannelsIn | nOut < obj.NChannelsOut) = [];
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
