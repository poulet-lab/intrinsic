classdef settingsUIControl < settingsLabelControl

    methods
        function obj = settingsUIControl(varargin)
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
            obj.Control = uicontrol(obj.Panel,varargin{:});
            obj.Control.Position(2) = 1;
            switch obj.Control.Style
                case 'edit'
                    obj.Panel.Position(4) = obj.Control.Position(4);
                case 'popupmenu'
                    obj.Panel.Position(4) = obj.Control.Position(4) + 2;
            end
        end
        
     	function resize(obj)
            controlPos    = obj.Control.Position;
            controlPos(1) = obj.Label.Position(3) + obj.Padding + 1;
            controlPos(3) = max([0 obj.Panel.Position(3) - controlPos(1) + 1]);
            controlPos(4) = max([0 obj.Panel.Position(4)]);
            obj.Control.Position = controlPos;
            
            switch obj.Control.Style
                case 'edit'
                    obj.Label.Position(4) = controlPos(4) - 3;
                case 'popupmenu'
                    obj.Label.Position(4) = controlPos(4) - 5;
                otherwise
                    obj.Label.Position(4) = controlPos(4);
            end
        end
    end
end