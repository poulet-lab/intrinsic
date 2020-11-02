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
        matPrefix = 'scale_'
    end
    
    events
        Update
    end
    
    methods
        function obj = scale(varargin)
            % parse input arguments
            narginchk(2,2)
            p = inputParser;
            addRequired(p,'MatFile',@(n)validateattributes(n,...
                {'matlab.io.MatFile'},{'scalar'}))
            addRequired(p,'Camera',@(n)validateattributes(n,...
                {'camera'},{'scalar'}))
            parse(p,varargin{:})
            obj.mat            = p.Results.MatFile;
            obj.Camera         = p.Results.Camera;
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
            % load variable from matfile / return default if non-existant
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
            % save variables to matfile
            obj.mat.([obj.matPrefix varName]) = data;
        end

        % callbacks and some helper functions are in separate files
        cbCalibrate(obj,~,~)
        cbMagnification(obj,~,~)
        cbOkay(obj,~,~)
    end
end

