function cbCalibrate(obj,~,~)

deviceData  = getappdata(obj.Figure,'deviceData');
controls    = getappdata(obj.Figure,'controls');
imCal       = imageCalibration(obj.Camera,obj);
listener    = addlistener(imCal,'Calibrate',@done);

    function done(~,~)
        magnification = ...
            controls.magnification.String{controls.magnification.Value};
        controls.pxpercm.String = sprintf('%0.1f',imCal.PxPerCm);
        deviceData.(genvarname(magnification)) = imCal.PxPerCm;
        setappdata(obj.Figure,'deviceData',deviceData)
        delete(listener)
    end
end
