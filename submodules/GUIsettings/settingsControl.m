classdef (Abstract) settingsControl < settingsChild
        
    properties
        Control
        Panel
    end
    
    properties (Dependent)
        Position
    end

    methods
        function createPanel(obj)
            obj.Panel = uipanel(obj.Parent.Handle,...
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
    end
    
    methods (Abstract)
        resize(obj)
    end
end