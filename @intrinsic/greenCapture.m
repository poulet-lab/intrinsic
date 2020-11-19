function greenCapture(obj,~,~)

% Get the current preview state
if isa(obj.VideoPreview,'video_preview')
    preview_state = obj.VideoPreview.Preview;
end

% If  red preview is running, stop it temporarily
if strcmp(obj.Camera.Input.Red.preview,'on')
    obj.VideoPreview.Preview = false;
end

% Create obj.Green / take snapshot
if isa(obj.Green,'imageGreen')
    obj.Green.takeImage()
    obj.Green.focus
else
    obj.Green = imageGreen(obj);
end

% Return to former preview state
if isa(obj.VideoPreview,'video_preview')
    obj.VideoPreview.Preview = preview_state;
end