classdef (Abstract) settingsControl < handle & matlab.mixin.Heterogeneous
        
    properties
        Control
        Parent
        Panel
        Padding = 8
    end
    
    properties (Dependent)
        Position
    end

    methods
        function createPanel(obj)
            obj.Panel = uipanel(obj.Parent,...
                'BorderType',           'none', ...
                'Units',                'pixels', ...
                'HitTest',              'off');
        end
        
        function value = get.Position(obj)
            value = obj.Panel.Position;
        end
        
        function set.Position(obj,value)
            obj.Panel.Position = value;
            obj.resize();
        end
        
        function set.Padding(obj,value)
            obj.Padding = value;
            obj.resize();
        end
    end
    
    methods (Abstract)
        resize(obj)
    end
end