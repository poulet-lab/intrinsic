function cbCalibrate(obj,~,~)

deviceData  = getappdata(obj.Figure,'deviceData');
controls    = getappdata(obj.Figure,'controls');
imCal       = imageCalibration(obj.Parent);
listener    = addlistener(imCal,'Calibrate',@done);

    function done(~,~)
        magnification = ...
            controls.magnification.String{controls.magnification.Value};
        controls.pxpercm.String = sprintf('%0.1f',imCal.PxPerCm);
        deviceData(strcmp({deviceData.Name},magnification)).PxPerCm = imCal.PxPerCm;
        setappdata(obj.Figure,'deviceData',deviceData)
        delete(listener)
    end
end
