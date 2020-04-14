function updateEnabled(obj)

IAQ = obj.Toolbox.ImageAcquisition.available;
IP  = obj.Toolbox.ImageProcessing.available;
DAQ = obj.Toolbox.DataAcquisition.available;
VID = isa(obj.VideoInputRed,'videoinput');
tmp = {'off', 'on'};

% UI elements depending on Image Acquisition Toolbox
elem = obj.h.menu.settingsVideo;
cond = IAQ;
set(elem,'Enable',tmp{cond+1});

% UI elements depending on Image Acquisition Toolbox & valid video-input
elem = [...
    obj.h.push.capture, ...
    obj.h.push.liveGreen, ...
    obj.h.push.liveRed];
cond = IAQ && VID;
set(elem,'Enable',tmp{cond+1});

% UI elements depending on all Toolboxes
elem = [obj.h.push.start obj.h.push.stop];
cond = IAQ && IP && DAQ && VID;
set(elem,'Enable',tmp{cond+1});

end
