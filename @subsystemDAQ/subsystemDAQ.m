classdef subsystemDAQ < subsystemGeneric

    properties (Access = private)
        Figure
        Session
    end
    
    properties (SetAccess = immutable, GetAccess = private)
        ChannelProp
        NChannelsOut
        NChannelsIn
    end

    properties (Constant = true, Access = protected)
        MatPrefix = 'DAQ_'
    end

    properties (Constant = true, Access = private)
        % is the Data Acquisition Toolbox both installed and licensed?
        Toolbox = ~isempty(ver('DAQ')) && license('test','data_acq_toolbox');

        % supported vendors
        SupportedVendors = {'ni'};

        % supported channel types
        ChannelTypesOut  = {'AnalogOutput','DigitalIO'};
        ChannelTypesIn   = {'AnalogInput','DigitalIO'};
    end
    
    properties (SetAccess = private, GetAccess = {?subsystemData,?intrinsic})
        InputData
        OutputData
    end

    properties (Dependent = true, GetAccess = {?subsystemStimulus})
        MaxStimulusAmplitude
    end
    
    properties (Dependent = true, GetAccess = private)
        TriggerAmplitude
        Vendors
    end

    properties (Dependent = true, SetAccess = private)
        Available
        VendorName
        VendorID
        DeviceName
        DeviceID
        SamplingRate
        nFrameTrigger
        tFrameTrigger
        pFrameTrigger
    end
    
    properties (Access = {?subsystemData})
        tStartTrigger = []
    end

    methods
        function obj = subsystemDAQ(varargin)
            obj = obj@subsystemGeneric(varargin{:});
            
            %
            
            % check for Data Acquisition Toolbox
            if ~obj.Toolbox
                warning('Data Acquisition Toolbox is not available.')
                return
            end

            % reset Data Acquisition Toolbox
            obj.reset()

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
            if isempty(obj.Vendors) || isempty(obj.devices)
                warning('No supported data acquisition devices found.')
                return
            end
            
            % create DAQ session
            obj.createSession
        end

        function out = get.Available(obj)
            if isa(obj.Session,'daq.Session')
                out = numel(obj.Session.Channels) == ...
                        obj.NChannelsOut + obj.NChannelsIn;
            else
                out = false;
            end
        end

        function out = get.TriggerAmplitude(obj)
            out = obj.loadVar('triggerAmp',[]);
        end
        
        function out = get.MaxStimulusAmplitude(obj)
            tmp = find(strcmp({obj.Session.Channels.Name},'Stimulus'),1);
            tmp = obj.Session.Channels(tmp).Range;
            out = [tmp.Min tmp.Max];
        end

        function out = get.Vendors(obj)
            out = daq.getVendors;
            out(~[out.IsOperational]) = [];
            out(~ismember({out.ID},obj.SupportedVendors)) = [];
        end
        
        function out = get.SamplingRate(obj)
            if obj.Available
                out = obj.Session.Rate;
            else
                out = 1000;
            end
        end
        
        function out = get.VendorName(obj)
            if obj.Available
                out = obj.Session.Vendor.FullName;
            else
                out = [];
            end
        end
        
        function out = get.DeviceName(obj)
            if obj.Available
                out = obj.Session.Channels(1).Device.Model;
            else
                out = [];
            end
        end
        
        function out = get.VendorID(obj)
            if obj.Available
                out = obj.Session.Vendor.ID;
            else
                out = [];
            end
        end

    	function out = get.DeviceID(obj)
            if obj.Available
                out = obj.Session.Channels(1).Device.ID;
            else
                out = [];
            end
        end
        
        function out = get.pFrameTrigger(obj)
            if obj.Available
                out = mode(diff(obj.tFrameTrigger));
            else
                out = NaN;
            end
        end
        
        function out = get.nFrameTrigger(obj)
            if obj.Available
                out = numel(obj.tFrameTrigger);
            else
                out = NaN;
            end
        end

        function out = get.tFrameTrigger(obj)
            if obj.Available
                out = obj.OutputData.Trigger.Time(...
                    diff([0; obj.OutputData.Trigger.Data])>0)';
            else
                out = [];
            end
        end
        
        varargout = setup(obj)
    end

    methods (Access = {?intrinsic,?subsystemData})
        queueData(obj)
        
        function start(obj)
            pause(.5)
            intrinsic.message('Starting DAQ session')
            try
                [data,~,obj.tStartTrigger] = obj.Session.startForeground;
            catch ME
                % NOTE: nidaq:ni:DataMissedOutput keeps occuring on a
                % regular basis, for some reason. This only seems to affect
                % the input scans.
                if strcmp(ME.identifier,'nidaq:ni:DataMissedOutput') && ...
                    (obj.Session.ScansOutputByHardware == ...
                    obj.OutputData.Stimulus.Length)
                
                    data = nan(size(obj.OutputData.Stimulus.Time));
                    warning(ME.identifier,[ME.message '\nDAQ input ' ...
                        'data was lost. Output was complete.'])
                else
                    rethrow(ME)
                end
            end
            pause(.5)
            intrinsic.message('Releasing DAQ session')
            release(obj.Session)
            pause(.5)
            obj.InputData = ...
                timeseries(data,obj.OutputData.Stimulus.Time, ...
                'Name','Camera Sync');
        end
        
        function stop(obj)
            if ~obj.Session.IsRunning()
                return
            end
            intrinsic.message('Stopping DAQ session')
            obj.Session.stop()
        end
    end
    
    methods (Access = private)

        % callbacks and some helper functions are in separate files
        cbChannel(obj,~,~)
        cbDevice(obj,~,~)
        cbOkay(obj,~,~)
        cbRate(obj,~,~)
        cbTriggerAmp(obj,~,~)
        cbVendor(obj,~,~)
        toggleCtrls(obj,state)
        createSession(obj)

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
                
        function reset(~)
            intrinsic.message('Resetting Data Acquisition Toolbox')
            daqreset
        end
    end
end
