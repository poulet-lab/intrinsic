function cbOVS(obj, ~, ~)

ctrl  = getappdata(obj.fig,'controls');
hCtrl = ctrl.oversmpl;
ovs   = real(round(str2double(hCtrl.String)));
ovs   = floor(ovs/2)*2+1;
ovs   = max([1 ovs]);
hCtrl.String = ovs;
setappdata(obj.fig,'downsample',ovs);

if isCallback()
    obj.bitrate()
end
