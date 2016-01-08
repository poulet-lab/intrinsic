function mainGUI(obj)

obj.h.fig.main = figure( ...
    'Visible',          'off', ...
    'Menu',             'none', ...
    'NumberTitle',      'off', ...
    'Resize',           'on', ...
    'DockControls',     'off', ...
    'Color',            'w', ...
    'Name',             'Intrinsic Imaging', ...
    'Position',         [30 30 500 300], ...
    'Units',            'normalized', ...
    'CloseRequestFcn',  @obj.close);

%% Toolbar
obj.h.toolbar = uitoolbar(obj.h.fig.main);
obj.h.push.new = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('file_new.png'), ...
    'TooltipString',    'New File', ...
    'ClickedCallback',  @obj.clearData);
obj.h.push.open = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('file_open.png'), ...
    'TooltipString',    'Open File', ...
    'ClickedCallback',  @obj.fileOpen);
obj.h.push.save = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('file_save.png'), ...
    'TooltipString',    'Save File',...
    'Enable',           'on', ...
    'ClickedCallback',  @obj.fileSave);
obj.h.push.liveGreen = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('green_live.png'), ...
    'TooltipString',    'Preview Green', ...
    'ClickedCallback',  @obj.previewGUI, ...
    'Tag',              'Green', ...
    'Separator',        'on');
obj.h.push.capture = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('green_capture.png'), ...
    'TooltipString',    'Capture Green', ...
    'ClickedCallback',  @obj.greenCapture);
obj.h.push.liveRed = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('red_live.png'), ...
    'TooltipString',    'Preview Red', ...
    'ClickedCallback',  @obj.previewGUI, ...
    'Tag',              'Red', ...
    'Separator',        'on');
obj.h.push.start = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('red_start.png'), ...
    'TooltipString',    'Start Protocol', ...
    'ClickedCallback',  @obj.redStart);
obj.h.push.stop = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('red_stop.png'), ...
    'TooltipString',    'Stop Protocol', ...
    'ClickedCallback',  @obj.redStop);

%% Menu
obj.h.menu.file = uimenu(obj.h.fig.main, ...
    'Label',            '&File', ...
    'Accelerator',      'F');
obj.h.menu.fileNew = uimenu(obj.h.menu.file, ...
    'Label',            '&New', ...
    'Accelerator',      'N', ...
    'Callback',         @obj.clearData);
obj.h.menu.fileOpen = uimenu(obj.h.menu.file, ...
    'Label',            '&Open...', ...
    'Accelerator',      'O', ...
    'Callback',         @obj.fileOpen);
obj.h.menu.fileSave = uimenu(obj.h.menu.file, ...
    'Label',            '&Save...', ...
    'Accelerator',      'S', ...
    'Callback',         @obj.fileSave);
obj.h.menu.filePrint = uimenu(obj.h.menu.file, ...
    'Label',            '&Print...', ...
    'Accelerator',      'P', ...
    'Separator',        'on');
obj.h.menu.fileExit = uimenu(obj.h.menu.file, ...
    'Label',            'Exit', ...
    'Separator',        'on', ...
    'Callback',         @obj.close);

obj.h.menu.settings = uimenu(obj.h.fig.main, ...
    'Label',            '&Settings', ...
    'Accelerator',      'S');
obj.h.menu.settingsVideo = uimenu(obj.h.menu.settings, ...
    'Label',            'Video Settings', ...
    'Callback',         {@obj.settingsVideo});
obj.h.menu.settingsStimulus = uimenu(obj.h.menu.settings, ...
    'Label',            'Stimulus Settings', ...
    'Callback',         {@obj.settingsStimulus});
obj.h.menu.winPos = uimenu(obj.h.menu.settings, ...
    'Label',            'Save Window Positions', ...
    'Callback',         {@obj.saveWindowPositions});

obj.h.menu.view = uimenu(obj.h.fig.main, ...
    'Label',            '&View', ...
    'Accelerator',      'V', ...
    'Callback',         {@obj.updateMenuView});

obj.h.menu.debug = uimenu(obj.h.fig.main, ...
    'Label',            '&Debug', ...
    'Accelerator',      'D');
obj.h.menu.debugKeyboard = uimenu(obj.h.menu.debug, ...
    'Label',            '&Keyboard', ...
    'Accelerator',      'K', ...
    'Callback',         {@(~,~,obj) keyboard,obj});
obj.h.menu.debugTestdata = uimenu(obj.h.menu.debug, ...
    'Label',            'Generate &Test Data', ...
    'Accelerator',      'T', ...
    'Callback',         {@obj.test_data});

%% Axes
obj.h.axes.temporal = axes(...
    'outerposition',  	[0 .02 .5 .96], ...
    'fontsize',         9, ...
    'parent',           obj.h.fig.main, ...
    'tickdir',          'out', ...
    'layer',            'top', ...
    'clippingstyle',    'rectangle');
title(obj.h.axes.temporal,'Temporal Response')
xlabel(obj.h.axes.temporal,'Time [s]')
ylabel(obj.h.axes.temporal,'Intensity')
hold(obj.h.axes.temporal,'on')
obj.h.plot.temporal = plot(obj.h.axes.temporal,NaN,NaN,'k','linewidth',2);
plot(obj.h.axes.temporal,obj.DAQvec.time([1 end]),[0 0],':k');

obj.h.axes.stimulus = axes(...
    'parent',           obj.h.fig.main, ...
    'visible',          'off', ...
    'clippingstyle',    'rectangle');
hold(obj.h.axes.stimulus,'on')
linkaxes([obj.h.axes.temporal obj.h.axes.stimulus],'x')
linkprop([obj.h.axes.temporal obj.h.axes.stimulus],'Position');
obj.h.plot.stimulus = sparsearea(obj.h.axes.stimulus,...
    obj.DAQvec.time,obj.DAQvec.stim,...
    'linestyle',    'none', ...
    'facecolor',    'r');
plot(obj.h.axes.stimulus,[0 0],[0 max(obj.DAQvec.stim)*10],':k')
xlim(obj.h.axes.stimulus,obj.DAQvec.time([1 end]))
ylim(obj.h.axes.stimulus,[0 max(obj.DAQvec.stim)*10])

obj.h.axes.spatial = axes(...
    'outerposition',   	[.5 .02 .5 .96], ...
    'fontsize',         9, ...
    'parent',           obj.h.fig.main, ...
    'tickdir',          'out', ...
    'layer',            'top', ...
    'clippingstyle',    'rectangle');
title('Spatial Cross-Section')
xlabel('Distance [pixels]')
ylabel('Intensity')
hold(obj.h.axes.spatial,'on')

%% Restore position and make visible
obj.restoreWindowPositions('main')
obj.h.fig.main.Visible = 'on';