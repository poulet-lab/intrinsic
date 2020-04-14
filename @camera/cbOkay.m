function obj = cbOkay(obj,~,~)
obj.toggleCtrls('off')

% get values
a   = getappdata(obj.fig,'adaptor');
id  = getappdata(obj.fig,'deviceID');
m   = getappdata(obj.fig,'mode');
res = getappdata(obj.fig,'resolution');
roi = getappdata(obj.fig,'roi');
roi = [floor((res-roi)/2) roi];

% create videoinput objects
if ~isequal({a,id,m,roi(3:4)},{obj.adaptor,obj.deviceID, ...
        obj.videoMode,obj.ROI}) && ~strcmp(a,'none')
    obj.inputR = videoinput(a,id,m,'ROIPosition',roi);
    obj.inputG = videoinput(a,id,m,'ROIPosition',roi);
end

% save values to matfile
obj.mat.adaptor     = a;
obj.mat.deviceID    = id;
obj.mat.deviceName  = getappdata(obj.fig,'deviceName');
obj.mat.videoMode   = m;
obj.mat.ROI         = roi;

close(obj.fig)