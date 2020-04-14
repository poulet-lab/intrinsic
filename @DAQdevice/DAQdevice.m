classdef DAQdevice < handle
   
    properties
        
    end
    
    properties (Constant = true, Access = private)
        % is the Data Acquisition Toolbox both installed and licensed?
        toolbox = ~isempty(ver('DAQ')) && license('test','data_acq_toolbox');
        % matfile for storage of settings
        mat     = matfile([mfilename('fullpath') '.mat'],'Writable',true)
    end
    
    methods
        function obj = DAQdevice(varargin)

        end        
    end
end