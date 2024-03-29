function GUIgreen(obj)

margin = 6;
obj.GUIgeneric('Green',margin,20)
hold(obj.h.axes.green,'on')

% load settings
greenContrast = obj.loadVar('greenContrast',0);
greenLog      = obj.loadVar('greenLog',0);

obj.h.point.green = plot(obj.h.axes.green, ...
    obj.PointCoords(1)*obj.Binning,obj.PointCoords(2)*obj.Binning,...
    'pickableparts',    'none', ...
    'marker',           'o', ...
    'markerfacecolor',  'r', ...
    'markeredgecolor',  'w', ...
    'markersize',       5, ...
    'linewidth',        1);
obj.h.check.greenContrast = uicontrol(obj.h.fig.green, ...
    'Style',            'Checkbox', ...
    'Value',            greenContrast, ...
    'Position',         [margin margin 100 20], ...
    'String',           'Auto Contrast', ...
    'Callback',         @obj.greenContrast);
obj.h.check.greenLog = uicontrol(obj.h.fig.green, ...
    'Style',            'Checkbox', ...
    'Value',            greenLog, ...
    'Position',         ...
    [sum(obj.h.check.greenContrast.Position([1 3]))+margin margin 100 20], ...
    'String',           'Log Scale', ...
    'Callback',         @obj.greenContrast);

obj.restoreWindowPositions('green')