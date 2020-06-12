classdef (Abstract) settingsLabelControl < settingsControl
    
    properties (Access = protected)
        Label
    end
    
    properties (Dependent)
        LabelWidth
    end
    
    methods
        function createLabel(obj,string)
            obj.Label = uicontrol(obj.Panel, ...
                'Style',                'text', ...
                'String',               string, ...
                'HorizontalAlignment',  'right');
            obj.Label.Position(1:2) = 1;
            obj.LabelWidth = obj.Label.Extent(3);
        end
        
        function value = get.LabelWidth(obj)
            value = obj.Label.Position(3);
        end
        
        function set.LabelWidth(obj,value)
            obj.Label.Position(3) = value;
        end
    end
end