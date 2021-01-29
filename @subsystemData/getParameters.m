function getParameters(obj,~,~)
% Collects relevant parameters from other objects. Used as a
% callback for listener-functions - see constructor of
% subsystemData.

if obj.Unsaved
    return
end

obj.P.Username = obj.Parent.Username;
obj.P.Camera = struct(obj.Parent.Camera);
obj.P.DAQ = struct(obj.Parent.DAQ);
obj.P.Stimulus = struct(obj.Parent.Stimulus);
obj.P.Scale = struct(obj.Parent.Scale);