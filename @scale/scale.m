classdef scale < handle
    
    properties
        Magnifications
    end
    
    properties (Dependent)
        Magnification
        PxPerCm
    end
    
    properties (Dependent, Access = private)
        DeviceData
        DeviceString
    end
    
    properties (Access = private)
        Figure
        mat
        Camera
        MagnificationPriv
        Data
    end
    
    properties (Constant = true, Access = private)
        MatPrefix = 'scale_'
    end
    
    events
        Update
    end
    
    methods
        function obj = scale(parent)
            narginchk(1,1)
            validateattributes(parent,{'intrinsic'},{'scalar'});
            obj.Parent         = parent;
            obj.Camera         = obj.Parent.Camera;
            obj.Data           = obj.loadVar('Data',struct);
            obj.Magnifications = obj.loadVar('Magnifications',{''});
            obj.Magnification  = obj.loadVar('Magnification','');
            
            % create data structure
            if ~isfield(obj.Data,obj.DeviceString)
                tmp = [genvarname(obj.Magnifications) ...
                    repmat({NaN},size(obj.Magnifications))]';
                obj.DeviceData = struct(tmp{:});
            end
        end
        
        varargout = setup(obj)
    end
    
    methods
        function out = get.Magnification(obj)
            out = obj.MagnificationPriv;
        end
        
        function set.Magnification(obj,magnification)
            obj.MagnificationPriv = ...
                validatestring(magnification,obj.Magnifications);
            notify(obj,'Update')
        end
        
        function out = get.PxPerCm(obj)
            out = obj.Data.(obj.DeviceString).(obj.Magnification);
        end
        
        function out = get.DeviceData(obj)
            out = obj.Data.(obj.DeviceString);
        end
        
        function set.DeviceData(obj,in)
            validateattributes(in,{'struct'},{'scalar'})
            obj.Data.(obj.DeviceString) = in;
        end
        
        function out = get.DeviceString(obj)
            out = genvarname(sprintf('%s_%s',obj.Camera.Adaptor, ...
                obj.Camera.DeviceName));
        end
    end
    
    methods (Access = private)
        function out = loadVar(obj,var,default)
            out = obj.Parent.loadVar([obj.MatPrefix var],default);
        end

        function saveVar(obj,varName,data)
            obj.Parent.saveVar([obj.MatPrefix varName],data);
        end

        % callbacks and some helper functions are in separate files
        cbCalibrate(obj,~,~)
        cbMagnification(obj,~,~)
        cbOkay(obj,~,~)
    end
end

