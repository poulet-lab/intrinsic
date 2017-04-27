function settingsVideo(obj,~,~)

% We need the Image Acquisition Toolbox for this to work ...
if ~obj.Toolbox.ImageAcquisition.available
    return
end

if isa(obj.VideoInputRed,'videoinput')
    % IF there is a valid videoinput present already, assume the user wants
    % to modify its settings
    
    % check with user, if he really wants to change things
    %
    % TODO: This should be moved to a separate function, which is only
    % invoked, if there is actual unsaved data
    tmp = questdlg({['Changing the video settings will ' ...
        'discard all unsaved data.'] ['Do you really want ' ...
        'to continue?']}, 'Warning', 'Right on!', ...
        'Hold on a sec ...', 'Right on!');
    if ~strcmp(tmp,'Right on!')
        return
    end
    
    obj.VideoPreview.Preview = false;       % disable video preview ...
    if isfield(obj.VideoPreview,'Figure')
        delete(obj.VideoPreview.Figure)     % delete preview figure
    end
    
    [obj.VideoInputRed, VidPref]   = ...
        video_settings(obj.VideoInputRed,obj.Scale,obj.RateCam);
    %obj.previewGUI
    obj.VideoPreview.Scale = VidPref{5};
    
else
    % Else, if there is no valid videoinput yet (e.g., right after
    % start-up), try to load the settings from disk. If this fails, prompt
    % the user for input.
    try
        VidPref = obj.Settings.VidPref;
        obj.VideoInputRed = videoinput(VidPref{1:3});
    catch
        [obj.VideoInputRed,VidPref] = video_settings;
    end
end

if isa(obj.VideoInputRed,'videoinput')
    % In case we have a valid videoinput by now, save its current settings
    % to disk and update the corresponding fields of the main object. If
    % anything went wrong, throw an error.
    
    obj.Settings.VidPref          = VidPref;
    obj.VideoInputRed.ROIPosition = VidPref{4};
    obj.Scale                     = VidPref{5};
    obj.RateCam                   = VidPref{6};
    
    if obj.Binning > 1 && regexpi(imaqhwinfo(obj.VideoInputRed,'DeviceName'),'^QICam')
        current = obj.VideoInputRed.VideoFormat;
        current = textscan(current,'%s%n%n','Delimiter',{'_','x'});
        tmp   	= imaqhwinfo('qimaging','DeviceInfo');
        tmp   	= tmp.SupportedFormats;
        asd     = regexp(tmp,['(?<=^' current{1}{:} '_)\d*'],'match');
        [~,ii]  = max(str2double([asd{:}]));
        obj.VideoInputGreen = videoinput(VidPref{1:2},tmp{ii});
        obj.VideoInputGreen.ROIPosition  = VidPref{4} * obj.Binning;
    else
        obj.VideoInputGreen = videoinput(VidPref{1:3});
        obj.VideoInputGreen.ROIPosition = VidPref{4};
    end
    
    switch imaqhwinfo(obj.VideoInputRed,'AdaptorName')
        case 'qimaging'
            obj.Bits = 12;
            set(obj.VideoInputRed.Source, ...
                'NormalizedGain',   0.601, ...
                'ColorWheel',       'red')
            set(obj.VideoInputGreen.Source, ...
                'ColorWheel',       'green')
    end
    
else
    warning('No camera found. Did you switch it on?')
end

end

function [vid_out,settings_out,cancelled] = video_settings(varargin)

%% handle input arguments (argument 1: videoinput, argument 2: scale)
narginchk(0,3)                                      % number of inputs args
nargoutchk(0,4)                                     % number of output args
settings    = cell(1,3);                           	% pre-allocate settings
vid_in      = [];
scale_in	= [];
fps_in      = [];
cancelled   = true;

if nargin>=1                                        % at least 1 input arg
    if ~isempty(varargin{1})
        validateattributes(varargin{1},{'videoinput'},{'scalar'},...
            'video_settings','input argument 1')
        vid_in      = varargin{1};
        settings{1} = imaqhwinfo(vid_in,'AdaptorName');	% video adaptor
        settings{2} = vid_in.DeviceID;                	% device ID
        settings{3} = vid_in.VideoFormat;             	% video mode
    end
end

if nargin>=2                                        % at least 2 input args
    if ~isempty(varargin{2})
        validateattributes(varargin{2},{'numeric'},...
            {'scalar','positive'},'video_settings','input argument 2')
    end
    scale_in    = varargin{2};                      % scale from input
else
    scale_in    = 1;                                % default scale
end

if nargin>=3                                        % 3 input arguments
    if ~isempty(varargin{2})
        validateattributes(varargin{2},{'numeric'},...
            {'scalar','positive'},'video_settings','input argument 3')
    end
    fps_in      = varargin{3};                      % framerate from input
else
    fps_in      = 30;                               % default framerate
end

vid_out     = vid_in;
scale_out   = scale_in;
fps_out     = fps_in;
settings_in = settings;

%% create figure & UI controls
vsize  	 = 30;                             	% height of each UI row
voffset	 = 0;                               % vertical offset of UI rows
hpad   	 = 5;                               % padding of UI elements
hsizes	 = [55 140];                        % width of UI elements

labels   = {'Adaptor', 'Device ID', 'Mode', 'Resolution', ...
    'ROI', 'Scale', 'Framerate'};
popup	 = cell(1,3);
edit_res = cell(2,2);

hfig = figure( ...
    'Visible',          'off', ...
    'Toolbar',          'none', ...
    'Menu',             'none', ...
    'NumberTitle',      'off', ...
    'Resize',           'off', ...
    'Name',             'Video Settings', ...
    'WindowStyle',      'modal', ...
    'Position',         [1 1 3*hpad+sum(hsizes)-2 ...
    (length(labels)+1)*vsize+15], ...
    'DeleteFcn',        {@button_cancel_callback});

for ii = 1:length(labels)
    vpos = hfig.Position(4) - vsize*(ii) + voffset;
    uicontrol(...
        'Style',  	'text', ...
        'String',	[labels{ii} ':'], ...
        'Position',	[hpad,vpos,hsizes(1),20], ...
        'Horiz',    'right', ...
        'Parent',   hfig);
    if ii <= 3
        popup{ii} = uicontrol(...
            'Style',    'popupmenu', ...
            'Position', [2*hpad+hsizes(1),vpos+5,hsizes(2)-1,20], ...
            'String',   {' '}, ...
            'Callback', {@popup_callback}, ...
            'Parent',   hfig, ...
            'Userdata', ii);
    elseif (ii == 4) || (ii == 5)
        edit_res{ii-3,1} = uicontrol(...
            'Style',    'edit', ...
            'Position', [2*hpad+hsizes(1),vpos+3,hsizes(2)*.45,20], ...
            'String',   '', ...
            'Enable',   'off', ...
            'Tag',      'x', ...
            'Parent',   hfig);
        edit_res{ii-3,2} = uicontrol(...
            'Style',    'edit', ...
            'Position', [2*hpad+hsizes(1)+hsizes(2)*.55,vpos+3,hsizes(2)*.45,20], ...
            'String',   '', ...
            'Enable',   'off', ...
            'Tag',      'y', ...
            'Parent',   hfig);
        uicontrol(...
            'Style',  	'text', ...
            'String',	'x', ...
            'Position',	[2*hpad+hsizes(1)+hsizes(2)*.45,vpos,hsizes(2)*.1,20], ...
            'Horiz',    'center', ...
            'Foregr',   [.5 .5 .5], ...
            'Parent',   hfig);
    elseif ii == 6
        edit_scale = uicontrol(...
            'Style',    'edit', ...
            'Position', [2*hpad+hsizes(1),vpos+3,hsizes(2)*.45,20], ...
            'String',   scale_out, ...
            'UserData', scale_in, ...
            'Callback', {@edit_callback});
    elseif ii == 7
        edit_fps = uicontrol(...
            'Style',    'edit', ...
            'Position', [2*hpad+hsizes(1),vpos+3,hsizes(2)*.45,20], ...
            'String',   fps_out, ...
            'UserData', fps_in, ...
            'Callback', {@edit_callback});
    end
end
set([edit_res{2,:}],'Callback',{@edit_ROI_callback})

vpos = hfig.Position(4) - vsize*(length(labels)+1) + voffset - 10;
ok_button = uicontrol(...
    'Style',    'pushbutton', ...
    'Position', [1*hpad,vpos,sum(hsizes)/2+1,23], ...
    'String',   'Accept', ...
    'Enable',   'off', ...
    'Callback', {@button_accept_callback});
uicontrol(...
    'Style',    'pushbutton', ...
    'Position', [2*hpad+sum(hsizes)/2,vpos,sum(hsizes)/2+1,23], ...
    'String',   'Cancel', ...
    'Callback', {@button_cancel_callback});

%% Fill UI controls with values
populatePopups
update_settings
popupidx = cellfun(@(x) x.Value,popup);
if all(~cellfun(@isempty,settings)) && ~isa(vid_out,'videoinput')
    vid_out = videoinput(settings{:});
end
if isa(vid_out,'videoinput')                % if vid_out is valid already..
    tmp = vid_out.VideoResolution;          % (1) populate res fields
    edit_res{1,1}.String = tmp(1);
    edit_res{1,2}.String = tmp(2);
    tmp = vid_out.ROIPosition;              % (2) populate ROI fields
    edit_res{2,1}.String = tmp(3);
    edit_res{2,2}.String = tmp(4);
    set([edit_res{2,:}],'Enable','on')      % (3) enable ROI fields
    ok_button.Enable = 'on';                % (4) enable OK button
end

%% Finishing touches
movegui(hfig,'center')
hfig.Visible = 'on';
waitfor(hfig)


%% Callback function for popups
    function popup_callback(~,~)
        if any(popupidx~=cellfun(@(x) x.Value,popup))                      % if any changes ...
            settings = arrayfun(@(x) ...                                   % ... update settings
                popup{x}.String{popup{x}.Value},1:3,'uni',0);
            settings(strcmpi(settings,' ')) = {[]};
        end
        if popupidx(1)~=popup{1}.Value                                     % if adaptor change ...
            populatePopups                                                 % ... repopulate popups
        end
        if any(popupidx~=cellfun(@(x) x.Value,popup))                      % if any changes ...
            update_settings                                                % ... update settings
            
            if all(~cellfun(@isempty,settings))                            % if settings valid ...
                vid_out = videoinput(settings{:});                         % (1) create vid_out
                tmp = vid_out.VideoResolution;                             % (2) display resolution
                edit_res{1,1}.String = tmp(1);
                edit_res{1,2}.String = tmp(2);
                tmp = vid_out.ROIPosition;                                 % (3) display & enable ROI
                edit_res{2,1}.String = tmp(3);
                edit_res{2,2}.String = tmp(4);
                set([edit_res{2,:}],'Enable','on')
                ok_button.Enable = 'on';                                   % (4) enable OK button
            else                                                           % if settings invalid ...
                vid_out = [];                                              % (1) clear vid_out
                set([edit_res{:,:}],'String','')                           % (2) clear res/ROI
                set([edit_res{2,:}],'Enable','off')                        % (3) disable ROI
                ok_button.Enable = 'off';                                  % (4) disable OK button
            end
        end
        popupidx = cellfun(@(x) x.Value,popup);                            % save indices
    end

%% Callback function for ROI fields
    function edit_ROI_callback(~,~)
        roisize = round(str2double(get([edit_res{2,:}],'String')))';
        
        % correct for NaN / oversize / undersize values
        roisize(isnan(roisize)) = Inf;
        roisize(roisize<1) = 1;
        tmp1 = vid_out.VideoResolution;
        tmp2 = roisize>tmp1;
        roisize(tmp2) = tmp1(tmp2);
        set([edit_res{2,1}],'String',roisize(1))
        set([edit_res{2,2}],'String',roisize(2))
        
        vid_out.ROIPosition = ...
            [floor((vid_out.VideoResolution-roisize)/2) roisize];
    end

%% Callback function for scale/fps edit fields
    function edit_callback(src,~)
        value = str2double(get(src,'String'));
        if isnan(value) || value<0
            value = src.UserData;
        end
        set(src,'String',value)
    end

%% Callback function for accept button
    function button_accept_callback(~,~)
        settings_out = [ ...
            settings ...
            vid_out.ROIPosition ...
            str2double(edit_scale.String) ...
            str2double(edit_fps.String)];
        
        cancelled = false;
        delete(hfig)
    end

%% Callback function for cancel button
    function button_cancel_callback(~,~)
        if cancelled
            vid_out     = vid_in;
            if isa(vid_in,'videoinput')
                settings_out = [ ...
                    settings_in ...
                    vid_in.ROIPosition ...
                    scale_in ...
                    fps_in];
            else
                settings_out = cell(1,6);
            end
        end
        delete(hfig)
    end

%% Populate popup elements
    function populatePopups
        
        % show available adaptors
        adaptors = imaqhwinfo;
        adaptors = adaptors.InstalledAdaptors;
        if ~isempty(adaptors)
            idx = find(strcmpi(adaptors,settings{1}),1);
            if isempty(idx)
                idx = 1;
            end
            set(popup{1}, ...
                'Enable',   'on', ...
                'String',   adaptors, ...
                'Value',    idx)
        else
            set([popup{:}], ...
                'Enable',   'off', ...
                'String',   {' '}, ...
                'Value',    1)
            return
        end
        
        % show available device IDs
        adaptor = popup{1}.String{popup{1}.Value};
        hwinfo  = imaqhwinfo(adaptor);
        if ~isempty(hwinfo.DeviceIDs)
            idx = find(cellfun(@(x) x==1,hwinfo.DeviceIDs),1);
            if isempty(idx)
                idx = 1;
            end
            set(popup{2}, ...
                'Enable',   'on', ...
                'String',   hwinfo.DeviceIDs, ...
                'Value',    idx)
        else
            set(popup{2}, ...
                'Enable',   'off', ...
                'String',   {' '}, ...
                'Value',    1)
        end
        
        % show sorted list of available video modes
        vmodes = [hwinfo.DeviceInfo.SupportedFormats];
        if ~isempty(vmodes)
            if strcmp(adaptor,'qimaging')
                vmodes = vmodes(~cellfun(@isempty, ...
                    regexpi(vmodes,'MONO16')));
                idx     = cellfun(@(x) textscan(x,'%s%d%d', ...
                    'Delimiter','_x')',vmodes,'uni',0);
                [~,idx] = sortrows(cell2table([idx{:}]'));
                vmodes 	= vmodes(idx);
            end
            idx = find(strcmpi(vmodes,settings{3}),1);
            if isempty(idx)
                idx = find(~cellfun(@isempty, ...
                    regexpi(hwinfo.DeviceInfo.DefaultFormat,vmodes)));
            end
            set(popup{3}, ...
                'Enable',   'on', ...
                'String',   vmodes, ...
                'Value',    idx)
        else
            set(popup{3}, ...
                'Enable',   'off', ...
                'String',   {' '}, ...
                'Value',    1)
        end
        
    end

%% Update settings structure from popup fields
    function update_settings
        settings = arrayfun(@(x) ...
            popup{x}.String{popup{x}.Value},1:3,'uni',0);
        settings(strcmpi(settings,' ')) = {[]};
    end
end