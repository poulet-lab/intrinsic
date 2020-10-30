classdef (Abstract) settingsContainer < handle
        
    properties
        Handle
    end
    
    properties (Abstract)
        Padding
    end
    
    properties (Access = protected)
        Children
    end
    
    properties (Dependent, Access = protected)
        LabelWidth
    end
        
    properties (Dependent)
        Width
    end

    methods
        function varargout = addOKCancel(obj,varargin)
            child = settingsOKCancel(obj,varargin{:});
            obj.addChild(child)
            if nargout > 0
                varargout{1} = child.Control(1);
            end
            if nargout > 1
                varargout{2} = child.Control(2);
            end
        end
        
        function varargout = addPopupmenu(obj,varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            addParameter(p,'String',{''});
            parse(p,varargin{:});
            unmatched = [fieldnames(p.Unmatched) struct2cell(p.Unmatched)]';
            child = settingsUIControl(obj,unmatched{:},...
                'String',   p.Results.String, ...
                'Style',    'popupmenu');
            obj.addChild(child)
            if nargout == 1
                varargout{1} = child.Control;
            end
        end
        
        function varargout = addEdit(obj,varargin)
            child = settingsUIControl(obj,varargin{:},'Style','edit');
            obj.addChild(child)
            if nargout == 1
                varargout{1} = child.Control;
            end
        end
        
        function varargout = addButton(obj,varargin)
            child = settingsUIControl(obj,varargin{:},'Style','pushbutton');
            obj.addChild(child)
            if nargout == 1
                varargout{1} = child.Control;
            end
        end
        
        function varargout = addEditXY(obj,varargin)
            child = settingsEditXY(obj,varargin{:});
            obj.addChild(child)
            if nargout == 1
                varargout{1} = child.Control;
            end
        end
        
        function varargout = addPopupEdit(obj,varargin)
            child = settingsPopupEdit(obj,varargin{:});
            obj.addChild(child)
            if nargout == 1
                varargout{1} = child.Control;
            end
        end

        function value = get.Width(obj)
            value = obj.Handle.Position(3);
        end
        
        function set.Width(obj,value)
            obj.Handle.Position(3) = value;
        end
        
        function set.LabelWidth(obj,value)
            children = obj.Children(arrayfun(@(x) ...
                isa(x,'settingsLabelControl'),obj.Children));
            for child = reshape(children,1,[])
                child.LabelWidth = value;
            end
        end
        
        function value = get.LabelWidth(obj)
            children = obj.Children(arrayfun(@(x) ...
                isa(x,'settingsLabelControl'),obj.Children));
            value = max([0; arrayfun(@(x) x.LabelWidth,children)]);
        end
    end
    
    methods (Access = protected)
        function addChild(obj,child)
            obj.Children = [obj.Children; child];
            if obj.Visible
                obj.resize()
            end
        end
        
        function resizeChildren(obj,correction)
            x = obj.Padding + 1;
            w = obj.Width - 2 * obj.Padding + correction;
            for ii = numel(obj.Children):-1:1
                if ii == numel(obj.Children)
                    y = obj.Padding + 1;
                else
                    y = sum(obj.Children(ii+1).Position([2 4])) + obj.Padding;
                end
                obj.Children(ii).Position(1:3) = [x y w];
            end
        end
    end
    
    methods (Abstract)
        resize(obj)
    end
end