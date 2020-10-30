function cbCalibrate(obj,~,~)

deviceData = getappdata(obj.Figure,'deviceData');
controls = getappdata(obj.Figure,'controls');
imCal = imageCalibration(obj.Camera,obj.PxPerCm);
addlistener(imCal,'Calibrate',@done);

    function done(~,~)
        magnification = ...
            controls.magnification.String{controls.magnification.Value};
        controls.pxpercm.String = sprintf('%0.1f',imCal.Scale);
        deviceData.(genvarname(magnification)) = imCal.Scale;
        setappdata(obj.Figure,'deviceData',deviceData)
    end

end

