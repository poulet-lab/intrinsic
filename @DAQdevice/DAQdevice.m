classdef DAQdevice < handle
   
    properties
        
    end
    
    properties (Constant = true, Access = private)
        % is the Image Acquisition Toolbox both installed and licensed?
        daq     = ~isempty(ver('IMAQ')) && ...
            license('test','image_acquisition_toolbox');
        % matfile for storage of settings
        mat     = matfile([mfilename('fullpath') '.mat'],'Writable',true)
    end
    
    methods
        function obj = DAQdevice(varargin)
            
        end        
    end
end