classdef settingsWindow < settingsContainer

    properties
        Padding
    end
    
    properties (Dependent)
        Visible
    end
    
    methods
        function obj = settingsWindow(varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.FunctionName  = mfilename;
            addParameter(p,'Width',250,@(x) validateattributes(x,...
                {'numeric'},{'scalar','positive','real','finite'}));
            addParameter(p,'Padding',8,@(x) validateattributes(x,...
                {'numeric'},{'scalar','nonnegative','real','finite'}));
            parse(p,varargin{:});
            unmatched = [fieldnames(p.Unmatched) struct2cell(p.Unmatched)]';
            
            obj.Handle = figure(...
                'Position',         [100 100 p.Results.Width 100], ...
                'Resize',           'off', ...
                'Visible',          'off', ...
                'WindowStyle',      'modal', ...
                'NumberTitle',      'off', ...
                'ToolBar',          'none', ...
                'MenuBar',          'none', ...
                'Units',            'pixels', ...
                'SizeChangedFcn',   @(src,evn) obj.resize(), ...
                unmatched{:});
            obj.Padding = p.Results.Padding;
        end
        
        function varargout = addPanel(obj,varargin)
            child = settingsPanel(obj,varargin{:});
            obj.addChild(child)
            if nargout == 1
                varargout{1} = child;
            end
        end
        
        function resize(obj)
            if ~numel(obj.Children)
                return
            end
            
            tmp = arrayfun(@(x) isa(x,'settingsPanel'),obj.Children);
            w   = max([0; arrayfun(@(x) x.LabelWidth,obj.Children(tmp))]);
            for ii = reshape(find(tmp),1,[])
                obj.Children(ii).LabelWidth = w;
            end
            obj.LabelWidth = w + obj.Padding + 2;
            
            obj.resizeChildren(0)
            obj.Handle.Position(4) = sum(obj.Children(1).Position([2 4])) + obj.Padding - 1;
        end
        
        function set.Visible(obj,value)
            if isequal(value,true) || strcmp(value,'on')
                movegui(obj.Handle,'center')
                obj.resize()
            end
            obj.Handle.Visible = value;
        end
        
        function value = get.Visible(obj)
            value = obj.Handle.Visible;
        end
    end
end

