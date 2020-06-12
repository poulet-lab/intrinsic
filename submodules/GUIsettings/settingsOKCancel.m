classdef settingsOKCancel < settingsControl

    methods
        function obj = settingsOKCancel(varargin)
            p = inputParser;
            p.FunctionName  = mfilename;
            addOptional(p,'Parent',gcf,@(x) validateattributes(x,...
                {'settingsWindow'},{'scalar'}));
            addParameter(p,'Callback',[],@(x) validateattributes(x,...
                {'function_handle'},{'scalar'}));
            parse(p,varargin{:});
            obj.Parent = p.Results.Parent;
            obj.createPanel()
            
            obj.Control    = matlab.ui.control.UIControl.empty(0,2);
            obj.Control(1) = uicontrol(obj.Panel,'String','OK',...
                'Callback',p.Results.Callback);
            obj.Control(2) = uicontrol(obj.Panel,'String','Cancel',...
                'Callback',@(x,y) close(obj.Parent.Handle));
            obj.Control(1).Position(1:2) = 0;
            obj.Control(2).Position(2)   = 0;
            obj.Panel.Position(4) = obj.Control(1).Position(4) - 2;
            
            obj.resize()
        end

     	function resize(obj)
            w = round((obj.Panel.Position(3)-obj.Parent.Padding)/2) + 1;
            h = obj.Panel.Position(4) + 2;
            obj.Control(2).Position(1)   = obj.Panel.Position(3) - w + 2;
            obj.Control(1).Position(3:4) = [w h];
            obj.Control(2).Position(3:4) = [w h];
        end
    end
end