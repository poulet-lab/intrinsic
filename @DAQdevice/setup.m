function setup(obj)
% open GUI to change camera settings.

% some parameters controlling size and appearance of the controls
pad         = 7;                    % padding
hFigure     = 325;                  % height of figure
wFigure     = 290;                  % width of figure
wLabel      = 105;                  % width of labels
hCtrl       = 23;
hPanelHead  = 12;

% create figure
obj.fig = figure(...
    'Visible',      'off', ...
    'Position',     [100 100 wFigure hFigure], ...
    'Name',         'DAQ Settings', ...
    'Resize',       'off', ...
    'WindowStyle',  'modal', ...
    'NumberTitle',  'off', ...
    'Units',        'pixels');

% create UI controls (see helper functions at the bottom)
p(1) = addPanel(2,'Device Selection',hFigure);
p(2) = addPanel(3,'Channel Configuration',p(1).Position(2));
p(3) = addPanel(2,'Output Parameters',p(2).Position(2));
ctrl.vendor   = addPopup(1,@obj.cbVendor,'Vendor',obj.vendors.FullName,p(1));
ctrl.device   = addPopup(2,@obj.cbDevice,'Device',{''},p(1));
ctrl.outStim  = addPopup(1,@obj.cbOutStim,'Stimulus Output',{''},p(2));
ctrl.outCam   = addPopup(2,@obj.cbOutCam,'Camera Trigger',{''},p(2));
ctrl.inCam    = addPopup(3,@obj.cbInCam,'Input from Camera',{''},p(2));
ctrl.rate     = addEdit(1,@obj.cbRate,'Trigger Amplitude (V)',p(3));
ctrl.rate     = addEdit(2,@obj.cbRate,'Sampling Rate (Hz)',p(3));

% create UI buttons
ctrl.okay     = addButton(1,'OK',@obj.cbOkay);
ctrl.cancel   = addButton(2,'Cancel',@obj.cbAbort);

% % disable some of the UI controls
% set([ctrl.res ctrl.binning ctrl.bitDepth ctrl.bitRate],'Enable','Off');

% % load values from file
% ctrl.adaptor.Value = max([find(strcmp(ctrl.adaptor.String,...
%     loadvar(obj,'adaptor',''))) 1]);

% store UI control objects
setappdata(obj.fig,'controls',ctrl);

% run dependent callback functions
obj.cbVendor()

% initialize
movegui(obj.fig,'center')
obj.fig.Visible = 'on';

    function panel = addPanel(nRows,string,top)
        % helper function for creating uipanels
        size     = [wFigure-2*pad nRows*(pad+hCtrl)+hPanelHead+6];
        position = [pad+1 top-pad-size(2)];
        panel    = uipanel(obj.fig, ...
            'Title',    string, ...
            'Units',    'pixels', ...
            'Position', round([position size]));
    end

    function control = addButton(row,string,callback)
        % helper function for creating buttons
        size     = [(wFigure-3*pad)/2 hCtrl];
        position = [pad+(row-1)*((wFigure-3*pad)/2+pad) pad];
        control  = uicontrol(obj.fig, ...
            'String',   string, ...
            'Callback', callback, ...
            'Position', round([position size]));
    end

    function control = addLabel(row,string,parent)
        % helper function for creating control labels
        size     = [wLabel 18];
        position = [pad parent.Position(4)-row*(pad+hCtrl-1)-hPanelHead];
        control  = uicontrol(parent, ...
            'Style',                'text', ...
            'String',               string, ...
            'Position',             round([position size]), ...
            'HorizontalAlignment',  'right');
    end

    function control = addPopup(row,callback,label,string,parent)
        % helper function for creating pop-up menus
        addLabel(row,label,parent);
        size     = [parent.Position(3)-3*pad-wLabel-4 hCtrl];
        position = [2*pad+wLabel parent.Position(4)-row*(pad+hCtrl-1)-hPanelHead];
        control  = uicontrol(parent, ...
            'Style',    'popupmenu', ...
            'String',   string, ...
            'Callback', callback, ...
            'Position', round([position size]));
    end

    function control = addEdit(row,callback,label,parent)
        % helper function for creating text fields
        addLabel(row,label,parent);
        size     = [(parent.Position(3)-3*pad-wLabel-3)/2 hCtrl];
        position = [2*pad+wLabel parent.Position(4)-row*(pad+hCtrl-1)-hPanelHead];
        control  = uicontrol(parent, ...
            'Style',    'edit', ...
            'Callback', callback,...
            'Position', round([position size]));
    end
end
