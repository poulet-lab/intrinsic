function varargout = setup(obj)
% open GUI to change camera settings.

nargoutchk(0,1)

% some parameters controlling size and appearance of the controls
pad     = 7;                    % padding
hFigure	= 310;                  % height of figure
wFigure	= 254;                  % width of figure
wButton = (wFigure-3*pad) / 2;	% width of buttons
wLabel  = (wFigure-3*pad) * .4;	% width of labels
wPopup 	= (wFigure-3*pad) * .6;	% width of pop-up menus
wEdit   = (wPopup-pad*2) / 2;	% width of text fields

% create figure
obj.fig = figure(...
    'Visible',      'off', ...
    'Position',     [100 100 wFigure hFigure], ...
    'Name',         'Camera Settings', ...
    'Resize',       'off', ...
    'WindowStyle',  'modal', ...
    'NumberTitle',  'off', ...
    'Units',        'pixels');

% create UI controls (see helper functions at the bottom)
ctrl.adaptor  = addPopup(1,@obj.cbAdapt,'Adaptor',[{'none'} obj.adaptors]);
ctrl.device   = addPopup(2,@obj.cbDevice,'Device',{''});
ctrl.mode     = addPopup(3,@obj.cbMode,'Mode',{''});
ctrl.res      = addEditXY(4,'','Resolution (px)');
ctrl.binning  = addEditXY(5,@obj.cbROI,'Hardware Binning');
ctrl.ROI      = addEditXY(6,@obj.cbROI,'ROI (px)');
ctrl.FPS      = addEdit(7,0,@obj.cbFPS,'Frame Rate (Hz)');
ctrl.oversmpl = addEdit(8,0,@obj.cbOVS,'Oversampling');
ctrl.bitRate  = addEdit(9,0,'','Bit Rate (Mbit/s)');
ctrl.okay     = addButton(1,'OK',@obj.cbOkay);
ctrl.cancel   = addButton(2,'Cancel',@obj.cbAbort);

% disable some of the UI controls
set([ctrl.res ctrl.binning ctrl.bitRate],'Enable','Off');

% load values from file
ctrl.adaptor.Value = max([find(strcmp(ctrl.adaptor.String,...
    loadVar(obj,'adaptor',''))) 1]);

% store UI control objects
setappdata(obj.fig,'controls',ctrl);

% run dependent callback functions
obj.cbAdapt()

% initialize
movegui(obj.fig,'center')
obj.fig.Visible = 'on';

% output arguments
if nargout
    varargout{1} = obj.fig;
end


    function control = addButton(row,string,callback)
        % helper function for creating buttons
        size     = [wButton 23];
        position = [pad+(row-1)*(wButton+pad) pad];
        control  = uicontrol(obj.fig, ...
            'String',   string, ...
            'Callback', callback, ...
            'Position', round([position size]));
    end

    function control = addLabel(row,string)
        % helper function for creating control labels
        size     = [wLabel 18];
        position = [pad hFigure-row*(pad+22)];
        control  = uicontrol(obj.fig, ...
            'Style',                'text', ...
            'String',               string, ...
            'Position',             round([position size]), ...
            'HorizontalAlignment',  'right');
    end

    function control = addPopup(row,callback,label,string)
        % helper function for creating pop-up menus
        addLabel(row,label);
        size     = [wPopup 23];
        position = [2*pad+wLabel hFigure-row*(pad+22)];
        control  = uicontrol(obj.fig, ...
            'Style',    'popupmenu', ...
            'String',   string, ...
            'Callback', callback, ...
            'Position', round([position size]));
    end

    function control = addEdit(row,col,callback,label)
        % helper function for creating text fields
        if exist('label','var')
            addLabel(row,label);
        end
        size     = [wEdit 23];
        position = [2*pad+wLabel+col*(wEdit+2*pad) hFigure-row*(pad+22)];
        control  = uicontrol(obj.fig, ...
            'Style',    'edit', ...
            'Callback', callback,...
            'Position', round([position size]));
    end

    function control = addEditXY(row,cb,label)
        % helper function for creating XY text fields
        control(1) = addEdit(row,0,cb,label);
        control(2) = addEdit(row,1,cb);
        size       = [2*pad 18];
        position   = [2*pad+wLabel+wEdit hFigure-row*(pad+22)];
        uicontrol(obj.fig, ...
            'Style',    'text', ...
            'String',   'x',...
            'Position', round([position size]));
    end
end
