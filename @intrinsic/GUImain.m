function GUImain(obj)

obj.h.fig.main = figure( ...
    'Visible',          'off', ...
    'Menu',             'none', ...
    'NumberTitle',      'off', ...
    'Resize',           'on', ...
    'DockControls',     'off', ...
    'HandleVisibility', 'off', ...
    'Color',            'w', ...
    'Name',             'Intrinsic Imaging', ...
    'Position',         [30 30 500 300], ...
    'Units',            'normalized', ...
    'CloseRequestFcn',  @obj.close, ...
    'SizeChangedFcn',   @figResize);

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
    'ClickedCallback',  @obj.GUIpreview, ...
    'Tag',              'Green', ...
    'Separator',        'on');
obj.h.push.capture = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('green_capture.png'), ...
    'TooltipString',    'Capture Green', ...
    'ClickedCallback',  @obj.greenCapture);
obj.h.push.liveRed = uipushtool(obj.h.toolbar, ...
    'CData',            obj.icon('red_live.png'), ...
    'TooltipString',    'Preview Red', ...
    'ClickedCallback',  @obj.GUIpreview, ...
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
    'Label',            'Camera Settings', ...
    'Callback',         {@cbSetupCamera});
obj.h.menu.settingsDAQ = uimenu(obj.h.menu.settings, ...
    'Label',            'DAQ Settings', ...
    'Callback',         {@cbSetupDAQ});
obj.h.menu.settingsStimulus = uimenu(obj.h.menu.settings, ...
    'Label',            'Stimulus Settings', ...
    'Callback',         {@obj.settingsStimulus});
obj.h.menu.settingsMagnification = uimenu(obj.h.menu.settings, ...
    'Label',            'Scale Settings', ...
    'Callback',         {@cbSetupScale});
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

%% Menu Icons
setIcon = @(h,fn) setMenuIcon(obj.h.menu.(h),fullfile(obj.DirBase,'icons',fn));
setIcon('fileNew',                  'file_new.png')
setIcon('fileOpen',                 'file_open.png')
setIcon('fileSave',                 'file_save.png')
setIcon('filePrint',                'file_print.png')
setIcon('fileExit',                 'file_exit.png')
setIcon('settingsVideo',            'settings_video.png')
setIcon('settingsDAQ',              'settings_daq.png')
setIcon('settingsStimulus',         'settings_stimulus.png')
setIcon('settingsMagnification',  	'settings_magnification.png')
setIcon('winPos',                   'settings_windowpos.png')
setIcon('debugKeyboard',            'debug_keyboard.png')
setIcon('debugTestdata',            'debug_testdata.png')

%% Prepare Axes & plots
obj.h.axes.stimulus = axes(...
    'Parent',           obj.h.fig.main, ...
    'Visible',          'on', ...
    'YAxisLocation',    'right', ...
    'XColor',           'none', ...
    'YColor',           'r', ...
    'NextPlot',         'add', ...
    'TickDir',          'out', ...
    'Color',            'none', ...
    'ClippingStyle',    'rectangle');
obj.h.axes.temporalBg = axes(...
    'Parent',           obj.h.fig.main, ...
    'Visible',          'off', ...
    'NextPlot',         'add', ...
    'ClippingStyle',    'rectangle', ...
    'YLim',             [0 1], ...
    'NextPlot',         'add');
obj.h.axes.temporal = axes(...
    'OuterPosition',  	[0 .02 .5 .96], ...
    'FontSize',         9, ...
    'Parent',           obj.h.fig.main, ...
    'TickDir',          'out', ...
    'Layer',            'top', ...
    'ClippingStyle',    'rectangle', ...
    'ButtonDownFcn',    @temporalClick, ...
    'NextPlot',         'add', ...
    'Color',            'none');
linkaxes([obj.h.axes.temporal obj.h.axes.stimulus obj.h.axes.temporalBg],'x')
linkprop([obj.h.axes.temporal obj.h.axes.temporalBg],{'Position'});

% Temporal response: stimulus
obj.h.plot.stimulus = plot(obj.h.axes.stimulus,...
    obj.DAQvec.time,obj.DAQvec.stim,'r',...
    'pickableparts',    'none');
ylim(obj.h.axes.stimulus,[0 max(obj.DAQvec.stim)])
ylabel(obj.h.axes.stimulus,'Stim (V)')

% Temporal response: markers for t=0 and camera triggers
obj.h.plot.grid = plot(obj.h.axes.temporalBg,NaN,NaN,'k',...
    'pickableparts',    'none');
xline(obj.h.axes.temporalBg,0,'k', ...
    'PickableParts',    'none')
obj.plotCameraTrigger()

% Temporal response: the actual response
title(obj.h.axes.temporal,'Temporal Response')
xlabel(obj.h.axes.temporal,'Time (s)')
ylabel(obj.h.axes.temporal,'\DeltaF/F')
obj.h.plot.temporalOVS = errorbar(obj.h.axes.temporal,NaN,NaN,NaN,'horizontal', ...
    'Color',            [1 1 1]*.5, ...
    'PickableParts',    'none', ...
    'CapSize',          0);
obj.h.plot.temporal = plot(obj.h.axes.temporal,NaN,NaN,':ko', ...
    'LineWidth',        1, ...
    'PickableParts',    'none', ...
    'MarkerEdgeColor',  'k', ...
    'MarkerFaceColor',  'k', ...
    'MarkerSize',       2);
obj.h.plot.temporalROI = plot(obj.h.axes.temporal,NaN,NaN,'k', ...
    'LineWidth',        1, ...
    'PickableParts',    'none');
yline(obj.h.axes.temporal,0,'k', ...
    'pickableparts',    'none');

% Spatial response
obj.h.axes.spatial = axes(...
    'outerposition',   	[.5 .02 .5 .96], ...
    'fontsize',         9, ...
    'parent',           obj.h.fig.main, ...
    'tickdir',          'out', ...
    'layer',            'top', ...
    'clippingstyle',    'rectangle', ...
    'NextPlot',         'add');
title(obj.h.axes.spatial,'Spatial Cross-Section')
xlabel(obj.h.axes.spatial,'Distance (cm)')
ylabel(obj.h.axes.spatial,'\DeltaF/F')

%% Restore position and make visible
obj.restoreWindowPositions('main')
obj.h.fig.main.Visible = 'on';



    function temporalClick(~,~)

        % get two X/Y pairs that define a rectangle
        pos(1,1:2) = obj.h.axes.temporal.CurrentPoint(1,1:2);
        rbbox;
        pos(2,1:2) = obj.h.axes.temporal.CurrentPoint(1,1:2);
 
        % section of the temporal response that is within the rectangle
        x = sort(pos(:,1));
        y = sort(pos(:,2));
        inBox = inpolygon(obj.ResponseTemporal.x,obj.ResponseTemporal.y,...
            [x(1) x(1) x(2) x(2)],[y(1) y(2) y(2) y(1)]);

        % set the temporal ROI (only positive times are allowed)
        if any(inBox)
            tmp = false(size(obj.Time));
            tmp(find(inBox,1):find(inBox,1,'last')) = true;
            obj.IdxStimROI = obj.Time>=0 & tmp;
        else
            obj.IdxStimROI = obj.Time>=0;
        end

        obj.update_redImage
        obj.update_plots
        obj.redView(obj.h.popup.redView);
        figure(obj.h.fig.red)
    end

    function figResize(~,~,~)
        obj.h.axes.stimulus.Position = obj.h.axes.temporal.Position./[1 1 1 7];
    end

    function cbSetupDAQ(~,~,~)
        h = obj.DAQ.setup;
        uiwait(h)
    end

    function cbSetupCamera(~,~,~)
        h = obj.Camera.setup;
        uiwait(h)
    end

    function cbSetupScale(~,~,~)
        h = obj.Scale.setup;
        uiwait(h)
    end
end
