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
    'WindowButtonMotionFcn',@temporalMove, ...
    'KeyPressFcn',          @keypress);

%% Listen for changes in temporal windows
addlistener(obj.Data,{'IdxResponse','UseControl'},'PostSet',...
    @updatedTemporalWindow);
addlistener(obj.Data,'UseControl','PostSet',@updatedUseControl);
addlistener(obj.DAQ,'tLive','PostSet',@updatedtLive);
addlistener(obj.Red,{'TransectResponse','CLim'},...
    'PostSet',@updatedSpatial);

%% Toolbar
obj.h.toolbar = uitoolbar(obj.h.fig.main);
obj.h.push.new = uipushtool(obj.h.toolbar, ...
    'CData',            icon('file_new.png'), ...
    'TooltipString',    'New File', ...
    'ClickedCallback',  @obj.fileNew);
obj.h.push.open = uipushtool(obj.h.toolbar, ...
    'CData',            icon('file_open.png'), ...
    'TooltipString',    'Open File', ...
    'ClickedCallback',  @(~,~) obj.Data.loadData);
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
    'Callback',         @(~,~) obj.Data.loadData);
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
    'FontSize',         9, ...
    'NextPlot',         'add', ...
    'ClippingStyle',    'rectangle', ...
    'Layer',            'top', ...
    'XColor',           'none', ...
    'XTick',            [], ...
    'YTick',            [], ...
    'XColor',           'k', ...
    'YColor',           'none', ...
	'YLim',             [0 1]);
obj.h.axes.temporal = axes(...
    'OuterPosition',  	[0 .02 .5 .96], ...
    'Units',            'pixels', ...
    'FontSize',         9, ...
    'Parent',           obj.h.fig.main, ...
    'TickDir',          'out', ...
    'Layer',            'bottom', ...
    'ClippingStyle',    'rectangle', ...
    'NextPlot',         'add', ...
    'Color',            'none', ...
    'PickableParts',    'none', ...
    'XTickLabel',       {}, ...
	'YLim',             [-1 1]);
title(obj.h.axes.temporal,'Temporal Response')
ylabel(obj.h.axes.temporal,'\DeltaF/F (%)')

obj.h.axes.stimulus = axes(...
    'Parent',           obj.h.fig.main, ...
    'Units',            'pixels', ...
    'FontSize',         9, ...
    'Visible',          'on', ...
    'NextPlot',         'add', ...
    'TickDir',          'out', ...
    'ClippingStyle',    'rectangle', ...
    'PickableParts',    'none');
xlabel(obj.h.axes.stimulus,'Time (s)')
ylabel(obj.h.axes.stimulus,'Stimulus (V)')

obj.h.axes.colorbar = axes(obj.h.fig.main, ...
    'Units',            'pixels',...
    'FontSize',         9, ...
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
    'PickableParts',    'none', ...
	'XLim',             [-1000 1000]);
title(obj.h.axes.spatial,'Spatial Cross-Section')
xlabel(obj.h.axes.spatial,'Distance (µm)')
ylabel(obj.h.axes.spatial,'\DeltaF/F (%)')

linkaxes([obj.h.axes.temporal obj.h.axes.stimulus obj.h.axes.temporalBg],'x')
linkaxes([obj.h.axes.spatial obj.h.axes.colorbar],'y')
linkprop([obj.h.axes.temporal obj.h.axes.temporalBg],{'Position','InnerPosition'});


%% Temporal Response

% indicate temporal windows
obj.h.patch.winBaseline = patch(obj.h.axes.temporalBg, ...
    'YData',            [1 0 0 1], ...
    'FaceColor',        c.winBaseline, ...
    'EdgeColor',        'none', ...
    'ButtonDownFcn',	@useControl);
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
pb(4).enterFcn    = @pointerEnterTemporalBaselineROI;
pb(1).exitFcn     = @pointerExitTemporalROI;
pb(2).exitFcn     = @pointerExitTemporalROI;
pb(4).exitFcn     = @pointerExitTemporalBaselineROI;
pb(2).traverseFcn = @pointerEnterTemporalROIarea;
pb(3).traverseFcn = @pointerExitTemporalROI;
pb(4).enterFcn    = @pointerEnterTemporalBaselineROI;
iptSetPointerBehavior(obj.h.xline.winResponse,pb(1));
iptSetPointerBehavior(obj.h.patch.winResponse,pb(2));
iptSetPointerBehavior(obj.h.fig.main,pb(3));
iptSetPointerBehavior(obj.h.patch.winBaseline,pb(4));
iptPointerManager(obj.h.fig.main,'enable')

% indicate t=0
obj.h.xline.tZero = xline(obj.h.axes.temporalBg,0,'-k', ...
    'Alpha',            0.2, ...
    'PickableParts', 	'none');
obj.h.xline.timeCursor(1) = xline(obj.h.axes.temporalBg,0,'-k', ...
    'Alpha',            0.2, ...
    'PickableParts',   	'none', ...
    'Visible',        	'off');

% indicate camera triggers
obj.h.plot.grid = plot(obj.h.axes.temporalBg,NaN,NaN,...
    'Color',                [.8 .8 .8], ...
    'PickableParts',        'none', ...
    'AlignVertexCenters',   'on');
obj.plotCameraTrigger()

% stimulus plot
obj.h.xline.tZero = xline(obj.h.axes.stimulus,0,'-k', ...
    'Alpha',            0.2, ...
    'PickableParts',  	'none');
obj.h.xline.timeCursor(2) = xline(obj.h.axes.stimulus,0,'-k', ...
    'Alpha',            0.2, ...
    'PickableParts',   	'none', ...
    'Visible',        	'off');
obj.h.plot.stimulus = area(obj.h.axes.stimulus,NaN,NaN, ...
    'FaceColor',        'k', ...
    'EdgeColor',        'none', ...
    'PickableParts',    'none');
obj.plotStimulus()

% response plot
obj.h.yline.zeroTemporal = yline(obj.h.axes.temporal,0,'-k', ...
    'Alpha',            0.2, ...
    'PickableParts',    'none');
obj.h.yline.stdTemporal(1) = yline(obj.h.axes.temporal,0,'--k', ...
    'Alpha',            0.2, ...
    'PickableParts',    'none', ...
    'Label',            '\color[rgb]{0.6,0.6,0.6}3\sigma', ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'bottom');
obj.h.yline.stdTemporal(2) = yline(obj.h.axes.temporal,0,'--k', ...
    'Alpha',            0.2, ...
    'PickableParts',    'none', ...
    'Label',            '\color[rgb]{0.6,0.6,0.6}3\sigma', ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'top');
obj.h.plot.temporal = plot(obj.h.axes.temporal,NaN,NaN,'k', ...
    'LineWidth',        1, ...
    'PickableParts',    'none');

% Spatial response
xline(obj.h.axes.spatial,0,'-k', ...
    'Alpha',            0.2, ...
    'PickableParts',  	'none');
yline(obj.h.axes.spatial,0,'-k', ...
    'Alpha',            0.2, ...
    'pickableparts',    'none');
obj.h.plot.spatialControl = plot(obj.h.axes.spatial,NaN,NaN,...
    'Color',            [1 1 1] * .75);
obj.h.plot.spatialAverage = plot(obj.h.axes.spatial,NaN,NaN, ...
    'Color',            'k', ...
    'LineWidth',        1);

obj.h.image.colorbar = imagesc(obj.h.axes.colorbar,...
    'CData',ind2rgb(rot90(1:256),brewermap(256,'PuOr')),'XData',[0 1],'YData',linspace(-1,1,256),'Visible',0);
obj.h.axes.colorbar.InnerPosition = obj.h.axes.spatial.InnerPosition;

% legend
obj.h.legend.temporal = legend(obj.h.axes.temporal, ...
    [obj.h.patch.winBaseline obj.h.patch.winControl obj.h.patch.winResponse], ...
    {'Baseline', 'Control', 'Response'},'Color','w','HitTest','off');
obj.h.legend.spatial = legend(obj.h.axes.spatial, ...
    [obj.h.plot.spatialAverage obj.h.plot.spatialControl], ...
    {'Response', 'Control'},'Color','w','HitTest','off');

%% Restore position and make visible
obj.restoreWindowPositions('main')
obj.updateEnabled()
updatedUseControl()
updatedTemporalWindow()
obj.h.fig.main.Visible = 'on';

%% Set minimum window size
try
    warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved')
    jFrame = get(handle(obj.h.fig.main), 'JavaFrame'); %#ok<JAVFM>
    jWindow = jFrame.fHG2Client.getWindow;
    while isempty(jWindow)
        drawnow;
        pause(0.02);
        jWindow = jFrame.fHG2Client.getWindow;
    end
    jWindow.setMinimumSize(java.awt.Dimension(800, 500));
catch
end




    function useControl(~,~)
        obj.Data.UseControl  = ~obj.Data.UseControl;
        obj.Data.WinResponse = obj.Data.WinResponse;
        updatedTemporalWindow()
    end

    function pointerEnterTemporalBaselineROI(~,~)
        set(obj.h.fig.main,'Pointer','hand')
    end

    function pointerExitTemporalBaselineROI(~,~)
        set(obj.h.fig.main,'Pointer','arrow')
    end

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
        hObj = [obj.h.patch.winBaseline obj.h.patch.winControl obj.h.patch.winResponse];
        str = {'Baseline', 'Control', 'Response'};
        if ~obj.Data.UseControl
            hObj(2) = [];
            str(2) = [];
        end
        obj.h.legend.temporal = legend(obj.h.axes.temporal,hObj,str,...
            'Color',        'w', ...
            'PickableParts','none');
    end

    function updatedtLive(~,~)
        tmp = obj.DAQ.tLive;
        if ~isnan(tmp)
            obj.h.xline.timeCursor(1).Value = obj.DAQ.tLive;
            obj.h.xline.timeCursor(2).Value = obj.DAQ.tLive;
            obj.h.xline.timeCursor(1).Visible = 'on';
            obj.h.xline.timeCursor(2).Visible = 'on';
        else
            obj.h.xline.timeCursor(1).Visible = 'off';
            obj.h.xline.timeCursor(2).Visible = 'off';
            obj.h.xline.timeCursor(1).Value = 0;
            obj.h.xline.timeCursor(2).Value = 0;
        end
    end

    function updatedSpatial(~,~)
        obj.h.plot.spatialAverage.XData = obj.Red.TransectResponse.XData;
        obj.h.plot.spatialAverage.YData = obj.Red.TransectResponse.YData;
        obj.h.plot.spatialControl.XData = obj.Red.TransectControl.XData;
        obj.h.plot.spatialControl.YData = obj.Red.TransectControl.YData;
        if ~isempty(obj.Red.TransectResponse.XData)
            obj.h.axes.spatial.XLim = obj.h.plot.spatialAverage.XData([1 end]);
            obj.h.axes.spatial.YLim = obj.Red.CLim;
            obj.h.image.colorbar.YData = ...
                linspace(obj.Red.CLim(1),obj.Red.CLim(2),256);
        else
            obj.h.axes.spatial.XLim = [-1000 1000];
            obj.h.axes.spatial.YLim = [-1 1];
        end
        
    end

    function keypress(~,data)
        if strcmp(data.Key,'rightarrow')
            obj.Data.WinResponse = obj.Data.WinResponse + ...
                obj.Data.P.DAQ.pFrameTrigger;
        elseif strcmp(data.Key,'leftarrow')
            obj.Data.WinResponse = obj.Data.WinResponse - ...
                obj.Data.P.DAQ.pFrameTrigger;
        elseif strcmp(data.Key,'uparrow')
            obj.Data.WinResponse(2) = obj.Data.WinResponse(2) + ...
                obj.Data.P.DAQ.pFrameTrigger;
        elseif strcmp(data.Key,'downarrow')
            obj.Data.WinResponse(2) = obj.Data.WinResponse(2) - ...
                obj.Data.P.DAQ.pFrameTrigger;
        else
            return
        end
    end

    function figureResize(~,~,~)
        m = 60;
        hTemp = obj.h.axes.temporal;
        hSpat = obj.h.axes.spatial;
        hStim = obj.h.axes.stimulus;
        hClrb = obj.h.axes.colorbar;
        
%         minSz = [600 400];
        fSize = obj.h.fig.main.InnerPosition;
%         if any(fSize(3:4)<minSz)
%             fSize(3:4) = minSz;
%             obj.h.fig.main.InnerPosition = fSize;
%         end
            
        
%         hTemp.InnerPosition = [m m fSize(3:4).*[0.5 1]-[2 2].*m];
%         hStim.InnerPosition = hTemp.InnerPosition ./ [1 1 1 5];
        hTemp.InnerPosition = [m m+80 fSize(3:4).*[0.5 1]-[2 2].*m-[0 80]];
        hStim.InnerPosition = [m m fSize(3).*0.5-2*m 60];
        
        hSpat.InnerPosition = [m m fSize(3:4).*[0.5 1]-[2 2].*m] + [fSize(3)*.5 0 0 0];
        
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
