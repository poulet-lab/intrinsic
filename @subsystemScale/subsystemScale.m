classdef subsystemScale < subsystemGeneric & matlab.mixin.Copyable

    properties (Access = private)
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
        Camera
        MagnificationPriv
        Data
    end

    properties (Constant = true, Access = protected)
        MatPrefix = 'scale_';
    end

    methods
        function obj = subsystemScale(varargin)
            obj = obj@subsystemGeneric(varargin{:});
            
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
            if ~isempty(obj.Magnification)
                out = obj.Data.(obj.DeviceString).(obj.Magnification);
            else
                out = NaN;
            end
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
        cbCalibrate(obj,~,~)
        cbMagnification(obj,~,~)
        cbOkay(obj,~,~)
    end
    
    methods (Access = protected)
        function cp = copyElement(obj)
            cp = subsystemScale(obj.Parent);
        end
    end
    
    methods (Static)
        function obj = saveobj(obj)
            
        end
        
        function obj = loadobj(obj)
            
        end
    end
end
