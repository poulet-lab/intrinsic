classdef settingsWindow < settingsContainer
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = settingsWindow(varargin)
            obj.Handle = figure(...
                'Resize',           'off', ...
                'WindowStyle',      'modal', ...
                'NumberTitle',      'off', ...
                'ToolBar',          'none', ...
                'MenuBar',          'none', ...
                'Units',            'pixels', ...
                'SizeChangedFcn',   @(src,evn) obj.resize(), ...
                varargin{:});
        end
        
        function varargout = addPanel(obj,varargin)
            ctrl = settingsPanel(obj.Handle,varargin{:});
            obj.Children = [obj.Children; ctrl];
            if nargout == 1
                varargout{1} = ctrl;
            end
            obj.resize()
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
            obj.LabelWidth = w + obj.Margin + 2;
            
            obj.resizeChildren(0)
            obj.Handle.Position(4) = sum(obj.Children(1).Position([2 4])) + obj.Margin - 1;
        end
            
    end
end

