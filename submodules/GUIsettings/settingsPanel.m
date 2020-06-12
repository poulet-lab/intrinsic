classdef settingsPanel < settingsContainer & settingsChild
    
    properties
        Panel
    end
    
    properties (Dependent)
        Padding
        Position
        Visible
    end
    
    methods
        function obj = settingsPanel(parent,varargin)
            obj.Parent = parent;
        	obj.Panel  = uipanel(parent.Handle,...
                'Units', 	'pixels', ...
                'HitTest', 	'off', varargin{:});
            obj.Handle = obj.Panel;
        end
        
        function resize(obj)
            if ~numel(obj.Children)
                obj.Handle.Position(4) = 50;
                return
            end
            obj.resizeChildren(-4)

            if isempty(obj.Handle.Title)
                obj.Handle.Position(4) = sum(obj.Children(1).Position([2 4])) + obj.Parent.Padding + 3;
            else
                obj.Handle.Position(4) = sum(obj.Children(1).Position([2 4])) + obj.Parent.Padding + 10;
            end
        end
        
        function value = get.Position(obj)
            value = obj.Panel.Position;
        end
        
        function set.Position(obj,value)
            obj.Panel.Position = value;
            obj.resize();
        end
        
    	function value = get.Visible(obj)
            value = obj.Parent.Visible;
        end
        
        function value = get.Padding(obj)
            value = obj.Parent.Padding;
        end
    end
end

