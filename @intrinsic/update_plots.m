function update_plots(obj)

if isempty(obj.Stack) || any(isnan(obj.Point))
    obj.h.plot.temporal.XData = NaN;
    obj.h.plot.temporal.YData = NaN;
    obj.h.plot.temporalROI.XData = NaN;
    obj.h.plot.temporalROI.YData = NaN;
    cla(obj.h.axes.spatial)
    return
end

% update X and Y values of temporal plot
x = obj.ResponseTemporal.x;
y = obj.ResponseTemporal.y;
obj.h.plot.temporalROI.XData = x(obj.IdxStimROI);
obj.h.plot.temporalROI.YData = y(obj.IdxStimROI);
obj.h.plot.temporal.XData    = x;
obj.h.plot.temporal.YData    = y;

% plot indicators for oversampling
obj.h.plot.temporalOVS.XData = x;
obj.h.plot.temporalOVS.YData = y;
if obj.Oversampling > 1
    tmp = 1/obj.RateCam*(obj.Oversampling-1)/2;
    tmp = repmat(tmp,size(x));
else
    tmp = [];
end
obj.h.plot.temporalOVS.XNegativeDelta = tmp;
obj.h.plot.temporalOVS.XPositiveDelta = tmp;

% set Y limits
tmp = (max(y)-min(y))*.1;
tmp = [min(y)-tmp max(y)+tmp];
if ~diff(tmp), tmp = [-1 1]; end
ylim(obj.h.axes.temporal,tmp)

% set Y labels
if regexp(obj.redMode,'dF/F')
    lbl = '\DeltaF/F';
else
    lbl = '\DeltaF';
end
ylabel(obj.h.axes.temporal,lbl)
ylabel(obj.h.axes.spatial,lbl)

if ~any(obj.Line.x)
    obj.h.plot.spatial.XData = NaN;
    obj.h.plot.spatial.YData = NaN;
    return
end


%% spatial response ...
if regexp(obj.redMode,'dF/F')
    tmp = obj.ImageRedDFF;
else
    tmp = obj.ImageRedDiff;
end
[xi,yi,y]   = improfile(tmp,obj.Line.x,obj.Line.y,'bilinear');
x           = sqrt((xi-obj.Point(1)).^2+(yi-obj.Point(2)).^2);
tmp         = 1:floor(length(x)/2);
x(tmp)      = -x(tmp);
x           = x/obj.PxPerCm;
cla(obj.h.axes.spatial)
hold(obj.h.axes.spatial,'on')

% ... plot
plot(obj.h.axes.spatial,x,y,'k','linewidth',1)
plot(obj.h.axes.spatial,x,zeros(size(x)),'k')
xlim(obj.h.axes.spatial,x([1 end]))