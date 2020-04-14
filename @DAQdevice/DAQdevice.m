classdef DAQdevice < handle
   
    properties
        
    end
    
    properties (Constant = true, Access = private)
        % is the Data Acquisition Toolbox both installed and licensed?
        toolbox = ~isempty(ver('DAQ')) && license('test','data_acq_toolbox');
        % matfile for storage of settings
        mat     = matfile([mfilename('fullpath') '.mat'],'Writable',true)
    end
    
    properties %(Dependent = true, Access = private)
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
            
            % check for supported DAQ vendors
            if isempty(obj.vendors)
                warning(['No supported DAQ vendors available. Use ' ...
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
            disableVendorDiagnostics
            tmp = daqlist;
            
            if isempty(obj.vendors)
                out = {};
                return
            end
            out = eval('daqlist');
            enableVendorDiagnostics
        end
        
        function out = get.vendors(~)
            % get list of vendors
            vendorlist  = daq.getVendors;
            if isempty(vendorlist)
                out = {};
                return
            end
            
            % limit to supported and operational vendors
            tmp         = vendorlist.IsOperational;
            [~,tmp,~]   = intersect({vendorlist(tmp).ID},{'ni'});
            vendorlist  = vendorlist(tmp);
            if isempty(vendorlist)
                out = {};
            else
                out = {vendorlist.ID};
            end
        end
    end
end