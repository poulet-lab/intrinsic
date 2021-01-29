function cbMagnification(obj,~,~)

deviceData = getappdata(obj.Figure,'deviceData');
ctrl       = getappdata(obj.Figure,'controls');

% handle empty popup menu
if isequal(ctrl.magnification.String,{''})
    ctrl.calibrate.Enable = 'off';
    ctrl.pxpercm.String = '';
    setappdata(obj.Figure,'deviceData',struct);
    return
else
    ctrl.calibrate.Enable = 'on';
end

% update deviceData
tmp = ctrl.magnification.String;
if ~isempty(setxor(tmp,{deviceData.Name}))
    for ii = find(~ismember(tmp,{deviceData.Name}))'
        new.Name    = deblank(tmp{ii});
        new.PxPerCm = NaN;
        deviceData  = [deviceData new]; %#ok<AGROW>
    end
    deviceData(~ismember({deviceData.Name},tmp)) = [];
    setappdata(obj.Figure,'deviceData',deviceData)
end

% update PxPerCm string
magnification = ctrl.magnification.String{ctrl.magnification.Value};
tmp = find(strcmp(magnification,{deviceData.Name}),1);
pxpercm = [deviceData(tmp).PxPerCm NaN];
if isnan(pxpercm(1))
    ctrl.pxpercm.String = 'uncalibrated';
else
    ctrl.pxpercm.String = sprintf('%0.1f',pxpercm(1));
end