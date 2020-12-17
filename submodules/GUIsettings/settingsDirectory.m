classdef settingsDirectory < settingsLabelControl
    
    properties
        Directory
    end
    
    properties (Dependent)
        ButtonString
    end
    
    methods
        function obj = settingsDirectory(varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.FunctionName  = mfilename;
            addOptional(p,'Parent',gcf,@(x) validateattributes(x,...
                {'settingsContainer'},{'scalar'}));
            addParameter(p,'ButtonString','Browse', ...
                @(x) validateattributes(x,{'char'},{'row'}));
            addParameter(p,'String',pwd, ...
                @(x) validateattributes(x,{'char'},{'row'}));
            addParameter(p,'Label','',@ischar);
            parse(p,varargin{:});
            unmatched = [fieldnames(p.Unmatched) struct2cell(p.Unmatched)]';

            obj.Parent = p.Results.Parent;
            obj.createPanel();
            obj.createControl(unmatched{:})
            obj.createLabel(p.Results.Label)
            obj.ButtonString = p.Results.ButtonString;
            obj.Directory = p.Results.String;
            obj.resize()
        end
        
        function createControl(obj,varargin)
            obj.Control    = matlab.ui.control.UIControl.empty(0,2);
            obj.Control(1) = uicontrol(obj.Panel, ...
                'Style', 'edit',...
                'Enable', 'off', ...
                'HorizontalAlignment', 'left', ...
                'String', obj.Directory,varargin{:});
            obj.Control(2) = uicontrol(obj.Panel, ...
                'Style', 'pushbutton', ...
                'Callback', @obj.browse);
            
            obj.Control(1).Position(1:2) = 1;
            obj.Control(2).Position(2)   = 0;
            obj.Panel.Position(4) = obj.Control(1).Position(4);
        end
        
     	function resize(obj)
            obj.Control(2).Position(3) = obj.Control(2).Extent(3) + 6;
            w = round((obj.Panel.Position(3)-obj.Control(1).Position(1)) - obj.Control(2).Position(3)) - obj.Parent.Padding + 2;
            h = obj.Panel.Position(4);
            obj.Control(1).Position(1) = obj.Label.Position(3) + obj.Parent.Padding + 1;
            obj.Control(1).Position(3) = w;
            obj.Control(1).Position(4) = h;
            obj.Control(2).Position(1) = sum(obj.Control(1).Position([1 3])) + obj.Parent.Padding;
            obj.Control(2).Position(4) = h + 2;
            obj.Label.Position(4) = obj.Control(1).Position(4) - 3;
        end
        
        function browse(obj,~,~)
            tmp = uigetdir(obj.Directory);
            if tmp
                obj.Directory = tmp;
            end
        end
        
        function set.Directory(obj,in)
            if ~exist(in,'dir')
                error('Directory not found: %s',in)
            end
            obj.Directory = in;
            obj.Control(1).String = in;
            obj.Control(1).Callback(obj,[])
        end
        
        function set.ButtonString(obj,in)
            obj.Control(2).String = in;
            obj.resize()
        end
        
        function out = get.ButtonString(obj)
            out = obj.Control(2).String;
        end
    end
end