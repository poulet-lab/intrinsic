classdef settingsEditXY < settingsLabelControl
    
    properties
        X
    end
    
    methods
        function obj = settingsEditXY(varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.FunctionName  = mfilename;
            addOptional(p,'Parent',gcf,@(x) validateattributes(x,...
                {'matlab.ui.container.Panel','matlab.ui.Figure'},...
                {'scalar'}));
            addParameter(p,'Label','',@ischar);
            parse(p,varargin{:});
            unmatched = [fieldnames(p.Unmatched) struct2cell(p.Unmatched)]';
                        
            obj.Parent = p.Results.Parent;
            obj.createPanel();
            obj.createControl(unmatched{:})
            obj.createLabel(p.Results.Label)
            obj.resize()
        end
        
        function createControl(obj,varargin)
            obj.Control    = matlab.ui.control.UIControl.empty(0,2);
            obj.Control(1) = uicontrol(obj.Panel,'Style','edit');
            obj.Control(2) = uicontrol(obj.Panel,'Style','edit');
            
            obj.Control(1).Position(1:2) = 1;
            obj.Control(2).Position(2)   = 1;
            obj.Panel.Position(4) = obj.Control(1).Position(4);
            
            obj.X = uicontrol(obj.Panel, ...
                'Style',                'text', ...
                'String',               'x', ...
                'HorizontalAlignment',  'center');
            obj.X.Position(2) = 1;
            obj.X.Position(3) = obj.X.Extent(3);
            obj.X.Position(4) = obj.Control(1).Position(4) - 3;
        end
        
     	function resize(obj)
            w = round((obj.Panel.Position(3)-obj.Control(1).Position(1)-obj.X.Extent(3))/2);
            h = obj.Panel.Position(4);
            obj.Control(1).Position(1) = obj.Label.Position(3) + obj.Padding + 1;
            obj.Control(2).Position(1) = obj.Panel.Position(3) - w + 1;
            obj.Control(1).Position(3) = w;
            obj.Control(2).Position(3) = w;
            obj.Control(1).Position(4) = h;
            obj.Control(2).Position(4) = h;
            obj.X.Position(1) = sum(obj.Control(1).Position([1 3]));
            obj.Label.Position(4) = obj.Control(1).Position(4) - 3;
        end
    end
end