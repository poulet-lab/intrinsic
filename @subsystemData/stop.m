function stop(obj,~,~)

if ~obj.Running
    return
end

obj.Running = false;
obj.Parent.Camera.stop();
obj.Parent.DAQ.stop();