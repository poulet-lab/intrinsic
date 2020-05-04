function toggleCtrls(obj,state)
% toggle controls

persistent wasOn

if isempty(ishandle(obj.fig))
    return
end

h = getappdata(obj.fig,'handles');
c = structfun(@(x) x.findobj,h);
if strcmp(state,'off')
    wasOn = strcmp({c.Enable},'on');
end
set(c(wasOn),'Enable',state);
