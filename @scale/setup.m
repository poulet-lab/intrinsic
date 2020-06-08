function varargout = setup(obj)
% open GUI to change DAQ settings.

nargoutchk(0,1)

% some parameters controlling size and appearance of the controls
pad         = 7;                    % padding
hFigure     = 355;                  % height of figure
wFigure     = 350;                  % width of figure
wLabel      = 90;                  % width of labels
hCtrl       = 23;
hPanelHead  = 20;

% create figure
obj.Fig = figure(...
    'Visible',      'off', ...
    'Position',     [100 100 wFigure hFigure], ...
    'Name',         'Scale Settings', ...
    'Resize',       'off', ...
    'WindowStyle',  'modal', ...
    'NumberTitle',  'off', ...
    'Units',        'pixels');

p = addPanel(3,'Available Settings',hFigure);

% create UI controls (see helper functions below)
ctrl.camera	= addEdit(1,[],'Adaptor / Camera',p);
ctrl.mode	= addPopup(2,@obj.cbMode,'Mode',{'Test 1','Test 2'},p);
ctrl.scale	= addPopup(3,[],'Magnification',{'1','2','3','4','5','1','2','3','4','5'},p);

ctrl.camera.Enable = 'off';

% create UI buttons
ctrl.okay      = addButton(1,'OK',@obj.cbOkay);
ctrl.cancel    = addButton(2,'Cancel',@(~,~,~) close(obj.Fig));

% store UI control objects
setappdata(obj.Fig,'controls',ctrl);

% initialize
%obj.cbVendor(ctrl.vendor)
movegui(obj.Fig,'center')
obj.Fig.Visible = 'on';

% output arguments
if nargout == 1
    varargout{1} = obj.Fig;
end

    function panel = addPanel(nRows,string,top)
        % helper function for creating uipanels
        size     = [wFigure-2*pad nRows*(pad+hCtrl)+hPanelHead+7];
        position = [pad+1 top-pad-size(2)];
        panel    = uipanel(obj.Fig, ...
            'Title',    string, ...
            'Units',    'pixels', ...
            'Position', floor([position size]), ...
            'Tag',      string);
    end

    function control = addButton(row,string,callback)
        % helper function for creating buttons
        size     = [(wFigure-3*pad)/2 hCtrl];
        position = [pad+(row-1)*((wFigure-3*pad)/2+pad) pad];
        control  = uicontrol(obj.Fig, ...
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
        size     = [(parent.Position(3)-3*pad-wLabel-3) hCtrl];
        position = [2*pad+wLabel parent.Position(4)-row*(pad+hCtrl-1)-hPanelHead];
        control  = uicontrol(parent, ...
            'Style',    'edit', ...
            'Callback', callback, ...
            'Position', round([position size]), ...
            'Tag',      label);
    end
end
