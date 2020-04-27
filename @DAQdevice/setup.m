function setup(obj)
% open GUI to change DAQ settings.

% some parameters controlling size and appearance of the controls
pad         = 7;                    % padding
hFigure     = 355;                  % height of figure
wFigure     = 290;                  % width of figure
wLabel      = 107;                  % width of labels
hCtrl       = 23;
hPanelHead  = 20;

% create figure
obj.fig = figure(...
    'Visible',      'off', ...
    'Position',     [100 100 wFigure hFigure], ...
    'Name',         'DAQ Settings', ...
    'Resize',       'off', ...
    'WindowStyle',  'modal', ...
    'NumberTitle',  'off', ...
    'Units',        'pixels');

% create UI panels (see helper function below)
p(1) = addPanel(2,'Device Selection',hFigure);
p(2) = addPanel(numel(obj.channelProp),'Channel Selection',p(1).Position(2));
p(3) = addPanel(2,'Output Parameters',p(2).Position(2));

% create UI controls (see helper functions below)
ctrl.panels	= p';
ctrl.vendor	= addPopup(1,@obj.cbVendor,'Vendor',{obj.vendors.FullName},p(1));
ctrl.device	= addPopup(2,@obj.cbDevice,'Device',{''},p(1));
ctrl.amp   	= addEdit(1,@obj.cbTriggerAmp,'Trigger Amplitude (V)',p(3));
ctrl.rate  	= addEdit(2,@obj.cbRate,'Sampling Rate (Hz)',p(3));

% create UI controls for channels
ctrl.channel = gobjects(numel(obj.channelProp),1);
for ii = 1:numel(ctrl.channel)
    ctrl.channel(ii) = addPopup(ii,@obj.cbChannel,...
        obj.channelProp(ii).label,{''},p(2));
end

% create UI buttons
ctrl.okay      = addButton(1,'OK',@obj.cbOkay);
ctrl.cancel    = addButton(2,'Cancel',@(~,~,~) close(obj.fig));

% load vendor selection
ctrl.vendor.Value = max([find(strcmp(ctrl.vendor.String,...
    loadVar(obj,'deviceID',NaN)),1) 1]);

% store UI control objects
setappdata(obj.fig,'controls',ctrl);

% initialize
obj.cbVendor(ctrl.vendor)
movegui(obj.fig,'center')
obj.fig.Visible = 'on';

    function panel = addPanel(nRows,string,top)
        % helper function for creating uipanels
        size     = [wFigure-2*pad nRows*(pad+hCtrl)+hPanelHead+7];
        position = [pad+1 top-pad-size(2)];
        panel    = uipanel(obj.fig, ...
            'Title',    string, ...
            'Units',    'pixels', ...
            'Position', floor([position size]), ...
            'Tag',      string);
    end

    function control = addButton(row,string,callback)
        % helper function for creating buttons
        size     = [(wFigure-3*pad)/2 hCtrl];
        position = [pad+(row-1)*((wFigure-3*pad)/2+pad) pad];
        control  = uicontrol(obj.fig, ...
            'String',   string, ...
            'Callback', callback, ...
            'Position', round([position size]), ...
            'Tag',      string);
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
            'Position', round([position size]), ...
            'Tag',      label);
    end

    function control = addEdit(row,callback,label,parent)
        % helper function for creating text fields
        addLabel(row,label,parent);
        size     = [(parent.Position(3)-3*pad-wLabel-3)/2 hCtrl];
        position = [2*pad+wLabel parent.Position(4)-row*(pad+hCtrl-1)-hPanelHead];
        control  = uicontrol(parent, ...
            'Style',    'edit', ...
            'Callback', callback, ...
            'Position', round([position size]), ...
            'Tag',      label);
    end
end
