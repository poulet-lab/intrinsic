function stop(obj,~,~)

if ~obj.Running
    return
end

obj.Parent.Camera.stop();
obj.Parent.DAQ.stop();
obj.Running = false;

% Delete temporary data if end of first trial was not reached
if ~obj.nTrials
    obj.clearData(1)
end
