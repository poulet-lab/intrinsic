function toggleCtrls(obj,state)
% toggle controls

persistent wasOn

if isempty(ishandle(obj.fig))
    return
end

h = findobj(obj.fig,'Enable','on','-or','Enable','off');
if strcmp(state,'off')
    wasOn = strcmp({h.Enable},'on');
end
set(h(wasOn),'Enable',state);
