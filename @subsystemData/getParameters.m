function getParameters(obj,~,~)
% Collects relevant parameters from other objects. Used as a
% callback for listener-functions - see constructor of
% subsystemData.

if obj.Unsaved
    return
end

obj.P.Camera.Adaptor  	= obj.Parent.Camera.Adaptor;
obj.P.Camera.DeviceName	= obj.Parent.Camera.DeviceName;
obj.P.Camera.Mode     	= obj.Parent.Camera.Mode;
obj.P.Camera.DataType  	= obj.Parent.Camera.DataType;
obj.P.Camera.Binning  	= obj.Parent.Camera.Binning;
obj.P.Camera.BitDepth  	= obj.Parent.Camera.BitDepth;
obj.P.Camera.Resolution	= obj.Parent.Camera.Resolution;
obj.P.Camera.ROI     	= obj.Parent.Camera.ROI;
obj.P.Camera.FrameRate	= obj.Parent.Camera.FrameRate;
obj.P.DAQ.VendorID    	= obj.Parent.DAQ.VendorID;
obj.P.DAQ.VendorName   	= obj.Parent.DAQ.VendorName;
obj.P.DAQ.OutputData  	= obj.Parent.DAQ.OutputData;
obj.P.DAQ.nTrigger    	= obj.Parent.DAQ.nTrigger;
obj.P.DAQ.tTrigger   	= obj.Parent.DAQ.tTrigger;
obj.P.Stimulus      	= obj.Parent.Stimulus.Parameters;
