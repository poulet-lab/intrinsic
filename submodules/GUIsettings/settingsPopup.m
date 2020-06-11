classdef settingsLabelControl < settingsControl
    methods
        function obj = settingsPopup(parent,type,label,varargin)
            switch type
                case 'edit'
                    obj.LabelShift = -5;
                case 'popupmenu'
                    obj.LabelShift = -7;
            end
            obj.Parent = parent;
            obj.createPanel();
            obj.createControl(type,varargin{:})
            obj.createLabel(label)
            obj.resize()
        end
    end
end

