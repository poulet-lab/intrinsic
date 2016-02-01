% Setup the Videoinput
function settingsVideo(obj,~,~)

% We need the Image Acquisition Toolbox for this to work ...
if ~obj.Toolbox.ImageAcquisition.available
    return
end

% If there IS a valid videoinput present already, lets assume
% the user wants to modify its settings
if isa(obj.VideoInputRed,'videoinput')
    tmp = questdlg({['Changing the video settings will ' ...
        'discard all unsaved data.'] ['Do you really want ' ...
        'to continue?']}, 'Warning', 'Right on!', ...
        'Hold on a sec ...', 'Right on!');
    if ~strcmp(tmp,'Right on!')
        return
    end
    obj.VideoPreview.Preview = false;
    if isfield(obj.VideoPreview,'Figure')
        delete(obj.VideoPreview.Figure)
    end
    [obj.VideoInputRed, VidPref]   = ...
        video_settings(obj.VideoInputRed,obj.Scale,obj.RateCam);
    %obj.previewGUI
    obj.VideoPreview.Scale = VidPref{5};
    
    % Else, if there is no valid videoinput yet (e.g., after
    % start-up), try to load the settings from disk. If this fails,
    % prompt the user for input.
else
    try
        VidPref = obj.Settings.VidPref;
        obj.VideoInputRed = videoinput(VidPref{1:3});
    catch
        [obj.VideoInputRed,VidPref] = video_settings;
    end
end

% In case we have a valid videoinput by now, save its current
% settings to disk and update the corresponding fields of the
% main object. If anything went wrong, throw an error.
if isa(obj.VideoInputRed,'videoinput')
    
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
    
    if regexpi(imaqhwinfo(obj.VideoInputRed,'DeviceName'),'^QICam')
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