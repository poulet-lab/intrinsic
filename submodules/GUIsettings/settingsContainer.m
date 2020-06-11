classdef (Abstract) settingsContainer < handle
        
    properties
        Handle
        Children
        Margin = 8
    end
    
    properties (Dependent)
        LabelWidth
        Width
        Visible
    end

    methods
        function varargout = addUIControl(obj,varargin)
            ctrl = settingsUIControl(obj.Handle,varargin{:});
            obj.Children = [obj.Children; ctrl];
            if nargout == 1
                varargout{1} = ctrl.Control;
            end
            obj.resize()
        end
        
        function varargout = addOKCancel(obj,varargin)
            ctrl = settingsOKCancel(obj.Handle,varargin{:});
            obj.Children = [obj.Children; ctrl];
            if nargout > 0
                varargout{1} = ctrl.Control(1);
            end
            if nargout > 1
                varargout{2} = ctrl.Control(2);
            end
            obj.resize()
        end
        
        function varargout = addEditXY(obj,varargin)
            ctrl = settingsEditXY(obj.Handle,varargin{:});
            obj.Children = [obj.Children; ctrl];
            if nargout == 1
                varargout{1} = ctrl.Control;
            end
            obj.resize()
        end
        
        function value = get.Width(obj)
            value = obj.Handle.Position(3);
        end
        
        function set.Width(obj,value)
            obj.Handle.Position(3) = value;
            obj.resize();
        end
        
        function set.Margin(obj,value)
            obj.Margin = value;
            obj.resize();
        end
        
        function set.Visible(obj,value)
            obj.Handle.Visible = value;
        end
        
        function value = get.Visible(obj)
            value = obj.Handle.Visible;
        end
        
        function resizeChildren(obj,correction)
            [obj.Children.Padding] = deal(obj.Margin);
            widthControl = obj.Width - 2 * obj.Margin + correction;
            
            for ii = fliplr(1:numel(obj.Children))
                control = obj.Children(ii);
                
                x = obj.Margin + 1;
                if ii == numel(obj.Children)
                    y = obj.Margin + 1;
                else
                    y = sum(obj.Children(ii+1).Position([2 4])) + obj.Margin;
                end
                control.Position = [x y widthControl control.Position(4)];
            end
        end
        
        function set.LabelWidth(obj,value)
            children = obj.Children(isprop(obj.Children,'Label'));
            for child = reshape(children,1,[])
                try
                child.Label.Position(3) = value;
                catch
                    keyboard
                end
            end
        end
        
        function value = get.LabelWidth(obj)
            children = obj.Children(isprop(obj.Children,'LabelWidth'));
            value    = max([NaN; arrayfun(@(x) x.LabelWidth,children)]);
        end
    end
    
    methods (Abstract)
        resize(obj)
    end
end