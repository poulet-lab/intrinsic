classdef settingsPanel < settingsContainer & settingsControl
    
    methods
        function obj = settingsPanel(parent,varargin)
            obj.Parent = parent;
        	obj.Panel = uipanel(parent,...
                'Units', 	'pixels', ...
                'HitTest', 	'off', varargin{:});
            obj.Handle = obj.Panel;
        end
        
        function resize(obj)
            if ~numel(obj.Children)
                return
            end
            obj.resizeChildren(-4)

            if isempty(obj.Handle.Title)
                obj.Handle.Position(4) = sum(obj.Children(1).Position([2 4])) + obj.Padding + 3;
            else
                obj.Handle.Position(4) = sum(obj.Children(1).Position([2 4])) + obj.Padding + 10;
            end
        end
    end
end

