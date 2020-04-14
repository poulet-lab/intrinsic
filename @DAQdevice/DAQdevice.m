classdef DAQdevice < handle

    properties

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
        devices
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

        function out = get.devices(obj)
            % get list of devices
            disableVendorDiagnostics
            tmp = daqlist('all');
            enableVendorDiagnostics

            % limit to supported vendors
            if isempty(tmp)
                out = table('Size',[0 0]);
            else
                out = tmp(tmp.VendorID.matches(obj.supportedVendors),:);
            end
        end

        function out = get.vendors(obj)
            % get list of vendors
            [~,vendorlist] = daqvendorlist;
            if isempty(vendorlist)
                out = {};
                return
            end

            % limit to supported and operational vendors
            operational = [vendorlist.IsOperational] == true;
            supported   = matches({vendorlist.ID},obj.supportedVendors);
            vendorlist  = vendorlist(operational && supported);
            if isempty(vendorlist)
                out = {};
            else
                out = {vendorlist.ID};
            end
        end
    end
end
