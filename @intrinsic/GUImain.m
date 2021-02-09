function GUImain(obj)

% Color definitions
c.mainBg =       [1 1 1] * .98;
c.winBaseline =  [.95 .95 1];
c.winControl =   [.95 1 .95];
c.winResponse =  [1 .95 .95];
c.edgeResponse = [1 .75 .75];

hDrag  = [];
xStart = NaN;

obj.h.fig.main = figure( ...
    'Visible',              'off', ...
    'Menu',                 'none', ...
    'NumberTitle',          'off', ...
    'Resize',               'on', ...
    'DockControls',         'off', ...
    'HandleVisibility',     'off', ...
    'Name',                 'Intrinsic Imaging', ...
    'Color',                c.mainBg, ...
    'Units',                'pixels', ...
    'Position',             [30 30 500 300], ...
    'CloseRequestFcn',      @obj.close, ...
    'SizeChangedFcn',       @figureResize, ...
    'WindowButtonUpFcn',    @temporalDrop, ...
    'WindowButtonMotionFcn',@temporalMove);

%% Listen for changes in temporal windows
addlistener(obj.Data,{'IdxResponse','UseControl'},'PostSet',...
    @updatedTemporalWindow);
addlistener(obj.Data,'UseControl','PostSet',@updatedUseControl);
addlistener(obj.DAQ,'tLive','PostSet',@updatedtLive);

%% Toolbar
obj.h.toolbar = uitoolbar(obj.h.fig.main);
obj.h.push.new = uipushtool(obj.h.toolbar, ...
    'CData',            icon('file_new.png'), ...
    'TooltipString',    'New File', ...
    'ClickedCallback',  @obj.fileNew);
obj.h.push.open = uipushtool(obj.h.toolbar, ...
    'CData',            icon('file_open.png'), ...
    'TooltipString',    'Open File', ...
    'ClickedCallback',  @obj.fileOpen);
obj.h.push.save = uipushtool(obj.h.toolbar, ...
    'CData',            icon('file_save.png'), ...
    'TooltipString',    'Save File',...
    'Enable',           'on', ...
    'ClickedCallback',  @(~,~) obj.Data.saveData);
obj.h.push.liveGreen = uipushtool(obj.h.toolbar, ...
    'CData',            icon('green_live.png'), ...
    'TooltipString',    'Preview Green', ...
    'ClickedCallback',  @obj.GUIpreview, ...
    'Tag',              'Green', ...
    'Separator',        'on');
obj.h.push.capture = uipushtool(obj.h.toolbar, ...
    'CData',            icon('green_capture.png'), ...
    'TooltipString',    'Capture Green', ...
    'ClickedCallback',  @obj.greenCapture);
obj.h.push.liveRed = uipushtool(obj.h.toolbar, ...
    'CData',            icon('red_live.png'), ...
    'TooltipString',    'Preview Red', ...
    'ClickedCallback',  @obj.GUIpreview, ...
    'Tag',              'Red', ...
    'Separator',        'on');
obj.h.push.start = uipushtool(obj.h.toolbar, ...
    'CData',            icon('red_start.png'), ...
    'TooltipString',    'Start Protocol', ...
    'ClickedCallback',  {@(~,~,obj) obj.Data.start,obj});
obj.h.push.stop = uipushtool(obj.h.toolbar, ...
    'CData',            icon('red_stop.png'), ...
    'TooltipString',    'Stop Protocol', ...
    'ClickedCallback',  {@(~,~,obj) obj.Data.stop,obj});

%% Menu
obj.h.menu.file = uimenu(obj.h.fig.main, ...
    'Label',            '&File', ...
    'Accelerator',      'F');
obj.h.menu.fileNew = uimenu(obj.h.menu.file, ...
    'Label',            '&New', ...
    'Accelerator',      'N', ...
    'Callback',         @obj.fileNew);
obj.h.menu.fileOpen = uimenu(obj.h.menu.file, ...
    'Label',            '&Open...', ...
    'Accelerator',      'O', ...
    'Callback',         @obj.fileOpen);
obj.h.menu.fileSave = uimenu(obj.h.menu.file, ...
    'Label',            '&Save...', ...
    'Accelerator',      'S', ...
    'Callback',         @(~,~) obj.Data.saveData);
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
obj.h.menu.settingsGeneral = uimenu(obj.h.menu.settings, ...
    'Label',            'General', ...
    'Callback',         {@obj.settingsGeneral});
obj.h.menu.settingsVideo = uimenu(obj.h.menu.settings, ...
    'Label',            'Camera', ...
    'Callback',         {@(~,~,~) uiwait(obj.Camera.setup)});
obj.h.menu.settingsDAQ = uimenu(obj.h.menu.settings, ...
    'Label',            'Data Acquisition', ...
    'Callback',         {@(~,~,~) uiwait(obj.DAQ.setup)});
obj.h.menu.settingsStimulus = uimenu(obj.h.menu.settings, ...
    'Label',            'Stimulus', ...
    'Callback',         {@(~,~,~) uiwait(obj.Stimulus.setup)});
obj.h.menu.settingsMagnification = uimenu(obj.h.menu.settings, ...
    'Label',            'Scale', ...
    'Callback',         {@(~,~,~) uiwait(obj.Scale.setup)});
obj.h.menu.winPos = uimenu(obj.h.menu.settings, ...
    'Label',            'Save Window Positions', ...
    'Separator',        'on', ...
    'Callback',         {@obj.saveWindowPositions});

% obj.h.menu.view = uimenu(obj.h.fig.main, ...
%     'Label',            '&View', ...
%     'Accelerator',      'V', ...
%     'Callback',         {@obj.updateMenuView});

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
    'Callback',         {@obj.generateTestData});

%% Menu Icons
setIcon = @(h,fn) setMenuIcon(obj.h.menu.(h),fullfile(obj.DirBase,'icons',fn));
setIcon('fileNew',                  'file_new.png')
setIcon('fileOpen',                 'file_open.png')
setIcon('fileSave',                 'file_save.png')
setIcon('filePrint',                'file_print.png')
setIcon('fileExit',                 'file_exit.png')
setIcon('settingsGeneral',          'settings_general.png')
setIcon('settingsVideo',            'settings_video.png')
setIcon('settingsDAQ',              'settings_daq.png')
setIcon('settingsStimulus',         'settings_stimulus.png')
setIcon('settingsMagnification',  	'settings_magnification.png')
setIcon('winPos',                   'settings_windowpos.png')
setIcon('debugKeyboard',            'debug_keyboard.png')
setIcon('debugTestdata',            'debug_testdata.png')


%% Prepare Axes & plots
obj.h.axes.temporalBg = axes(...
    'Parent',           obj.h.fig.main, ...
    'Units',            'pixels', ...
    'NextPlot',         'add', ...
    'ClippingStyle',    'rectangle', ...
    'XTick',            [], ...
    'YTick',            [], ...
	'YLim',             [0 1]);
obj.h.axes.stimulus = axes(...
    'Parent',           obj.h.fig.main, ...
    'Units',            'pixels', ...
    'Visible',          'on', ...
    'YAxisLocation',    'right', ...
    'XColor',           'none', ...
    'YColor',           'r', ...
    'NextPlot',         'add', ...
    'TickDir',          'out', ...
    'Color',            'none', ...
    'ClippingStyle',    'rectangle', ...
    'PickableParts',    'none');
obj.h.axes.temporal = axes(...
    'OuterPosition',  	[0 .02 .5 .96], ...
    'Units',            'pixels', ...
    'FontSize',         9, ...
    'Parent',           obj.h.fig.main, ...
    'TickDir',          'out', ...
    'Layer',            'top', ...
    'ClippingStyle',    'rectangle', ...
    'NextPlot',         'add', ...
    'Color',            'none', ...
    'PickableParts',    'none');
obj.h.axes.colorbar = axes(obj.h.fig.main, ...
    'Units',            'pixels',...
    'Color',            'none', ...
    'Visible',          'off', ...
    'PickableParts',    'none');
obj.h.axes.spatial = axes(obj.h.fig.main, ...
    'Units',            'pixels', ...
    'FontSize',         9, ...
    'Parent',           obj.h.fig.main, ...
    'TickDir',          'out', ...
    'Layer',            'top', ...
    'ClippingStyle',    'rectangle', ...
    'NextPlot',         'add', ...
    'PickableParts',    'none');

linkaxes([obj.h.axes.temporal obj.h.axes.stimulus obj.h.axes.temporalBg],'x')
linkaxes([obj.h.axes.temporal obj.h.axes.spatial obj.h.axes.colorbar],'y')
linkprop([obj.h.axes.temporal obj.h.axes.temporalBg],{'Position','InnerPosition'});

%% Temporal Response

% indicate temporal windows
obj.h.patch.winBaseline = patch(obj.h.axes.temporalBg, ...
    'YData',            [1 0 0 1], ...
    'FaceColor',        c.winBaseline, ...
    'EdgeColor',        'none');
obj.h.patch.winControl = patch(obj.h.axes.temporalBg, ...
    'YData',            [1 0 0 1], ...
    'FaceColor',        c.winControl, ...
    'EdgeColor',        'none');
obj.h.patch.winResponse = patch(obj.h.axes.temporalBg, ...
    'YData',            [1 0 0 1], ...
    'FaceColor',        c.winResponse, ...
    'EdgeColor',        'none', ...
    'ButtonDownFcn',	@temporalDrag);
obj.h.xline.winResponse(1) = xline(obj.h.axes.temporalBg,0);
obj.h.xline.winResponse(2) = xline(obj.h.axes.temporalBg,0);
set(obj.h.xline.winResponse, ...
    'Color',          	c.edgeResponse, ...
    'ButtonDownFcn',  	@temporalDrag)

% pointer manager for temporal windows
pb(1).enterFcn    = @pointerEnterTemporalROIborder;
pb(2).enterFcn    = @pointerEnterTemporalROIarea;
pb(1).exitFcn     = @pointerExitTemporalROI;
pb(2).exitFcn     = @pointerExitTemporalROI;
pb(2).traverseFcn = @pointerEnterTemporalROIarea;
pb(3).traverseFcn = @pointerExitTemporalROI;
iptSetPointerBehavior(obj.h.xline.winResponse,pb(1));
iptSetPointerBehavior(obj.h.patch.winResponse,pb(2));
iptSetPointerBehavior(obj.h.fig.main,pb(3));
iptPointerManager(obj.h.fig.main,'enable')

% indicate t=0
obj.h.xline.tZero = xline(obj.h.axes.temporalBg,0, ...
    'Color',            [.8 .8 .8], ...
    'PickableParts',  	'none');
obj.h.xline.timeCursor = xline(obj.h.axes.temporal,0, ...
    'PickableParts',  	'none', ...
    'Visible',          'off');

% indicate camera triggers
obj.h.plot.grid = plot(obj.h.axes.temporalBg,NaN,NaN,'k',...
    'PickableParts',        'none', ...
    'AlignVertexCenters',   'on');
obj.plotCameraTrigger()

% stimulus plot
obj.h.plot.stimulus = area(obj.h.axes.stimulus,NaN,NaN, ...
    'FaceColor',        'r', ...
    'EdgeColor',        'none', ...
    'PickableParts',    'none');
ylabel(obj.h.axes.stimulus,'Stimulus (V)')
obj.plotStimulus()

% response plot
title(obj.h.axes.temporal,'Temporal Response')
xlabel(obj.h.axes.temporal,'Time (s)')
ylabel(obj.h.axes.temporal,'\DeltaF/F (%)')
obj.h.plot.temporal = plot(obj.h.axes.temporal,NaN,NaN,'k', ...
    'LineWidth',        1, ...
    'PickableParts',    'none');
yline(obj.h.axes.temporal,0, ...
    'Color',            [.8 .8 .8], ...
    'pickableparts',    'none');

% Spatial response
xline(obj.h.axes.spatial,0, ...
    'Color',                [.8 .8 .8], ...
    'PickableParts',        'none');
yline(obj.h.axes.spatial,0, ...
    'Color',            [.8 .8 .8], ...
    'pickableparts',    'none');
obj.h.plot.spatialAverage = plot(obj.h.axes.spatial,NaN,NaN, ...
    'Color',            'k', ...
    'LineWidth',        1);
obj.h.plot.spatialControl = plot(obj.h.axes.spatial,NaN,NaN,...
    'Color',            [1 1 1] * .75);

title(obj.h.axes.spatial,'Spatial Cross-Section')
xlabel(obj.h.axes.spatial,'Distance (µm)')
ylabel(obj.h.axes.spatial,'\DeltaF/F (%)')

obj.h.image.colorbar = imagesc(obj.h.axes.colorbar,...
    'CData',ind2rgb(rot90(1:256),brewermap(256,'PuOr')),'XData',[0 1],'YData',linspace(-1,1,256),'Visible',0);
obj.h.axes.colorbar.InnerPosition = obj.h.axes.spatial.InnerPosition;

% legend
obj.h.legend.temporal = legend(obj.h.axes.temporal, ...
    [obj.h.plot.temporal obj.h.plot.stimulus obj.h.patch.winBaseline obj.h.patch.winControl obj.h.patch.winResponse], ...
    {'Signal', 'Stimulus', 'Baseline Window', 'Control Window', 'Response Window'},'Color','w','HitTest','off');
obj.h.legend.spatial = legend(obj.h.axes.spatial, ...
    [obj.h.plot.spatialAverage obj.h.plot.spatialControl], ...
    {'Response', 'Control'},'Color','w','HitTest','off');

%% Restore position and make visible
obj.restoreWindowPositions('main')
obj.updateEnabled()
updatedUseControl()
updatedTemporalWindow()
obj.h.fig.main.Visible = 'on';





    %% Local functions for controlling drag & drop of temporal ROI
    function pointerEnterTemporalROIborder(~,~)
        if ~isempty(hDrag)
            return
        end
        set(obj.h.fig.main,'Pointer','left')
        set(obj.h.xline.winResponse,'Color',c.edgeResponse);
    end

    function pointerEnterTemporalROIarea(~,~)
        if ~isempty(hDrag)
            return
        end
        set(obj.h.fig.main,'Pointer','hand')
        set(obj.h.xline.winResponse,'Color',c.edgeResponse);
    end

    function pointerExitTemporalROI(~,~)
        if ~isempty(hDrag)
            return
        end
        set(obj.h.fig.main,'Pointer','arrow')
        set(obj.h.xline.winResponse,'Color',c.winResponse);
    end

    function temporalDrag(hObject,~)
        if ~strcmp(obj.h.fig.main.SelectionType,'normal')
            return
        end
        xStart = obj.h.axes.temporalBg.CurrentPoint(1);
        hDrag  = hObject;
    end

    function temporalDrop(~,~)
        if isempty(hDrag)
            return
        end
        hDrag = [];
        obj.Data.WinResponse = [obj.h.xline.winResponse.Value];
        
        % TODO:
        % obj.update_redImage
        % obj.update_plots
        % obj.redView(obj.h.popup.redView);
        % figure(obj.h.fig.red)
    end

    function temporalMove(~,~)
        if isempty(hDrag)
            return
        end
        
        mouseX = obj.h.axes.temporalBg.CurrentPoint(1);
        if isequal(hDrag,obj.h.xline.winResponse(1))
            newX = obj.Data.forceWinResponse([mouseX obj.Data.WinResponse(2)]);
            obj.h.patch.winResponse.XData(1:2) = newX(1);
            hDrag.Value = newX(1);
        elseif isequal(hDrag,obj.h.xline.winResponse(2))
            newX = obj.Data.forceWinResponse([obj.Data.WinResponse(1) mouseX]);
            obj.h.patch.winResponse.XData(3:4) = newX(2);
            hDrag.Value = newX(2);
        else
            newX = obj.Data.forceWinResponse(obj.Data.WinResponse + diff([xStart mouseX]));
            obj.h.patch.winResponse.XData = reshape(newX.*[1 1]',1,[]);
            obj.h.xline.winResponse(1).Value = newX(1); 
            obj.h.xline.winResponse(2).Value = newX(2);
        end
        
        if obj.Data.UseControl
            obj.h.patch.winControl.XData = reshape([-diff(newX) 0].*[1 1]',1,[]);
            obj.h.patch.winBaseline.XData = reshape([obj.Data.P.DAQ.tFrameTrigger(1) -diff(newX)].*[1 1]',1,[]);
        end
    end

    function updatedTemporalWindow(~,~)
        obj.h.patch.winBaseline.XData = ...
            reshape(obj.Data.WinBaseline.*[1 1]',1,[]);
        obj.h.patch.winControl.XData = ...
            reshape(obj.Data.WinControl.*[1 1]',1,[]);
        obj.h.patch.winResponse.XData = ...
            reshape(obj.Data.WinResponse.*[1 1]',1,[]);
        obj.h.xline.winResponse(1).Value = obj.Data.WinResponse(1);
        obj.h.xline.winResponse(2).Value = obj.Data.WinResponse(2);
    end

    function updatedUseControl(~,~)
        delete(obj.h.legend.temporal);
        hObj = [obj.h.plot.temporal obj.h.plot.stimulus ...
            obj.h.patch.winBaseline obj.h.patch.winControl ...
            obj.h.patch.winResponse];
        str = {'Signal', 'Stimulus', 'Baseline Window', ...
            'Control Window', 'Response Window'};
        if ~obj.Data.UseControl
            hObj(4) = [];
            str(4) = [];
        end
        obj.h.legend.temporal = legend(obj.h.axes.temporal,hObj,str,...
            'Color',        'w', ...
            'PickableParts','none');
    end

    function updatedtLive(~,~)
        tmp = obj.DAQ.tLive;
        if ~isnan(tmp)
            obj.h.xline.timeCursor.Value = obj.DAQ.tLive;
            obj.h.xline.timeCursor.Visible = 'on';
        else
            obj.h.xline.timeCursor.Visible = 'off';
            obj.h.xline.timeCursor.Value = 0;
        end
    end

    function figureResize(~,~,~)
        m = 60;
        hTemp = obj.h.axes.temporal;
        hSpat = obj.h.axes.spatial;
        hStim = obj.h.axes.stimulus;
        hClrb = obj.h.axes.colorbar;
        
        fSize = obj.h.fig.main.InnerPosition;
        
        hTemp.InnerPosition = [m m fSize(3:4).*[0.5 1]-[2 2].*m];
        hStim.InnerPosition = hTemp.InnerPosition ./ [1 1 1 5];
        hSpat.InnerPosition = hTemp.InnerPosition + [fSize(3)*.5 0 0 0];
        
        hClrb.InnerPosition    = hSpat.InnerPosition;
        hClrb.InnerPosition(3) = max(hSpat.InnerPosition(3:4)) * hSpat.TickLength(1);
        hClrb.InnerPosition(1) = hClrb.InnerPosition(1) - hClrb.InnerPosition(3);
    end

    function img = icon(filename)
        % read image, convert to double
        iconpath = fullfile(obj.DirBase,'icons');
        [img,~,alpha] = imread(fullfile(iconpath,filename));
        img     = double(img) / 255;
        alpha   = repmat(double(alpha) / 255,[1 1 3]);

        % create background, multiply with alpha
        bg      = repmat(240/255,size(img));
        img     = immultiply(img,alpha);
        bg      = immultiply(bg,1-alpha);

        % merge background and image
        img     = imadd(img,bg);

        % remove completely transparent areas
        img(~alpha) = NaN;
    end
end
