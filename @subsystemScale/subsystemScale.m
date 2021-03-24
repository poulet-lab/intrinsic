classdef subsystemScale < subsystemGeneric & matlab.mixin.Copyable

    properties (Dependent)
        Magnification
        PxPerCm
    end

    properties (Dependent, Access = {?imageGeneric})
        Magnifications
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
    
    properties
        UseBinning (1,:) logical = false
    end

    properties (Constant = true, Access = protected)
        MatPrefix = 'scale_';
    end

    methods
        function obj = subsystemScale(varargin)
            obj = obj@subsystemGeneric(varargin{:});
            obj.Camera         = obj.Parent.Camera;
            obj.Data           = obj.loadVar('Data',struct);
            obj.Magnification  = obj.loadVar('Magnification','');
        end

        varargout = setup(obj)
    end

    methods
        function out = get.Magnifications(obj)
            out = {obj.DeviceData.Name};
        end
        
        function out = get.Magnification(obj)
            out = obj.MagnificationPriv;
        end

        function set.Magnification(obj,magnification)
            if isfield(obj.Data,obj.DeviceString)
                obj.MagnificationPriv = ...
                    validatestring(magnification,obj.Magnifications);
                notify(obj,'Update')
            end
        end

        function out = get.PxPerCm(obj)
            tmp = find(strcmp(obj.Magnification,{obj.DeviceData.Name}),1);
            if ~isempty(tmp)
                out = obj.DeviceData(tmp).PxPerCm;
                if obj.UseBinning
                    out = out / obj.Camera.Binning;
                end
            else
                out = NaN;
            end
        end

        function out = get.DeviceData(obj)
            if isfield(obj.Data,obj.DeviceString)
                out = obj.Data.(obj.DeviceString);
            else
                out = struct('Name',{},'PxPerCm',{});
            end
        end

        function set.DeviceData(obj,in)
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
