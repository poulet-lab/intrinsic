function cbMagnification(obj,~,~)

deviceData = getappdata(obj.Figure,'deviceData');
controls   = getappdata(obj.Figure,'controls');

% handle empty popup menu
if isequal(controls.magnification.String,{''})
    controls.calibrate.Enable = 'off';
    controls.pxpercm.String = '';
    setappdata(obj.Figure,'deviceData',struct);
    return
else
    controls.calibrate.Enable = 'on';
end

% update deviceData
tmp = genvarname(controls.magnification.String);
if ~isempty(setxor(tmp,fieldnames(deviceData)))
    for ii = find(~ismember(tmp,fieldnames(deviceData)))'
        deviceData.(genvarname(controls.magnification.String{ii})) = NaN;
    end
    deviceData = rmfield(deviceData,setdiff(fieldnames(deviceData),tmp));
    setappdata(obj.Figure,'deviceData',deviceData)
end

% update PxPerCm string
pxpercm = deviceData.(tmp{controls.magnification.Value});
if isnan(pxpercm)
    controls.pxpercm.String = 'uncalibrated';
else
    controls.pxpercm.String = sprintf('%0.1f',pxpercm);
end