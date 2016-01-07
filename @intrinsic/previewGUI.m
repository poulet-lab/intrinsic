function previewGUI(obj,hbutton,~)

hbutton.Enable = 'off';

% In case the requested preview window already exists, bring it to focus.
% If the current preview window is of a different type (e.g., 'red' instead
% of 'green'), delete it.
if isfield(obj.h.fig,'preview')
    if ishandle(obj.h.fig.preview)
        if isempty(regexpi(obj.h.fig.preview.Name,hbutton.Tag))
            obj.VideoPreview.Preview = false;
            delete(obj.h.fig.preview)
        else
            obj.VideoPreview.Visible = 'on';
            hbutton.Enable           = 'on';
            return
        end
    end
end

if regexpi(hbutton.TooltipString,'green')
    obj.VideoPreview = ...
        video_preview(obj.VideoInputGreen,obj.Scale/obj.Binning,true);
    obj.VideoPreview.Figure.Name    = ...
        [obj.VideoPreview.Figure.Name ' Green'];
    obj.VideoPreview.Point = obj.PointCoords * obj.Binning;
else
    obj.VideoPreview = ...
        video_preview(obj.VideoInputRed,obj.Scale,true);
    obj.VideoPreview.Figure.Name    = ...
        [obj.VideoPreview.Figure.Name ' Red'];
    obj.VideoPreview.Point = obj.PointCoords;
end

obj.h.fig.preview       	= obj.VideoPreview.Figure;
obj.restoreWindowPositions('preview')
obj.VideoPreview.Visible    = 'on';

hbutton.Enable = 'on';