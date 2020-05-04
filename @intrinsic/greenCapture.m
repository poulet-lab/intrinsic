function greenCapture(obj,~,~)

% Create green window, if its not there already
if ~isfield(obj.h.fig,'green')
    obj.GUIgreen
end

% Get the current preview state
if isa(obj.VideoPreview,'video_preview')
    preview_state = obj.VideoPreview.Preview;
end

% If  red preview is running, stop it temporarily
if strcmp(obj.VideoInputRed.preview,'on')
    obj.VideoPreview.Preview = false;
end

% Capture image, use only one color plane
obj.ImageGreen = getsnapshot(obj.VideoInputGreen);
obj.ImageGreen = obj.ImageGreen(:,:,1);

% Return to former preview state
if isa(obj.VideoPreview,'video_preview')
    obj.VideoPreview.Preview = preview_state;
end

% Process image
obj.h.image.green.CData = obj.ImageGreen; 	% Update display
obj.greenContrast()                       	% Enhance Contrast

% Focus the green window
figure(obj.h.fig.green)
end
