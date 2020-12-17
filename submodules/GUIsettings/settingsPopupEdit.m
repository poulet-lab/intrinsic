classdef settingsPopupEdit < settingsLabelControl
    
    properties
        Button
        Validation
    end
    
    methods
        function obj = settingsPopupEdit(varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.FunctionName  = mfilename;
            addOptional(p,'Parent',gcf,@(x) validateattributes(x,...
                {'settingsContainer'},{'scalar'}));
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
            obj.Control   = uicontrol(obj.Panel,'Style','popup',varargin{:});
            obj.Button    = matlab.ui.control.UIControl.empty(0,2);
            obj.Button(1) = uicontrol(obj.Panel, ...
                'Style',    'pushbutton', ...
                'String',   '+', ...
                'Callback', @obj.cb_add);
            obj.Button(2) = uicontrol(obj.Panel, ...
                'Style',    'pushbutton', ...
                'String',   '-', ...
                'Callback', @obj.cb_remove);

            obj.Control.Position(1:2) = 1;
            obj.Button(1).Position(2) = 0;
            obj.Button(2).Position(2) = 0;
            obj.Panel.Position(4) = obj.Control.Position(4) + 2;
            
            % Deal with empty strings
            if ~iscell(obj.Control.String)
                obj.Control.String = {obj.Control.String};
            end
            if isequal(obj.Control.String,{''})
                obj.Control.Enable = 'off';
            end
        end
        
        function resize(obj)
            h = obj.Panel.Position(4);
            w = obj.Panel.Position(3) - obj.Control.Position(1) - obj.Parent.Padding - 2 * h;
            obj.Control.Position(1) = obj.Label.Position(3) + obj.Parent.Padding + 1;
            obj.Control.Position(3) = w;
            obj.Control.Position(4) = h;
            
            obj.Button(1).Position(1)   = sum(obj.Control.Position([1 3])) + obj.Parent.Padding;
            obj.Button(1).Position(3:4) = [h+1 h+2];
            
            obj.Button(2).Position(1)   = sum(obj.Button(1).Position([1 3]));
            obj.Button(2).Position(3:4) = [h+1 h+2];
            
            obj.Label.Position(4) = obj.Control.Position(4) - 5;
        end
        
        function cb_add(obj,~,~)
            
            % get user input
            while true
                val = inputdlg('Add value:','');
                if isempty(val)
                    return
                elseif isempty(val{1})
                    uiwait(errordlg('Value cannot be empty.'))
                elseif ismember(val,obj.Control.String)
                    uiwait(errordlg('Value must be unique.'))
                else
                    break
                end
            end
            
            % make sure we're dealing with a cell array, add element
            if ~iscell(obj.Control.String)
                obj.Control.String = {obj.Control.String};
            end
            if isequal(obj.Control.String,{''})
                obj.Control.String = val;
                obj.Control.Enable = 'on';
            else
                obj.Control.String = sort([obj.Control.String{:} val]);
                obj.Control.Value  = find(ismember(obj.Control.String,val));
            end
            
            % execute control's callback
            if ~isempty(obj.Control.Callback)
                obj.Control.Callback(obj.Control,[])
            end
        end
        
        function cb_remove(obj,~,~)
            % make sure we're dealing with a cell array, get value
            if ~iscell(obj.Control.String)
                obj.Control.String = {obj.Control.String};
            end
            value = obj.Control.String{obj.Control.Value};
            
            % if there is nothing to remove: return
            if isempty(value)
                return
            end
            
            % get confirmation from user
            opts.Interpreter = 'tex';
            opts.Default = 'No';
            answer = questdlg(sprintf(...
                'Do you really want to remove the value \\it%s\\rm?',...
                value),'Are you sure?','Yes','No',opts);
            if ~strcmp(answer,'Yes')
                return
            end
            
            % remove string from cell
            if numel(obj.Control.String) == 1
                obj.Control.String = {''};
                obj.Control.Enable = 'off';
            else
                obj.Control.String(obj.Control.Value) = [];
            end
            obj.Control.Value = 1;
            
            % execute control's callback
            if ~isempty(obj.Control.Callback)
                obj.Control.Callback(obj.Control,[])
            end
        end
    end
end