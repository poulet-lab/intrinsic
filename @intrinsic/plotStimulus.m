function plotStimulus(obj,p)

if ~exist('p','var')
    p = obj.Stimulus.Parameters;
end

hPlot = obj.h.plot.stimulus;
hAxes = obj.h.axes.stimulus;

ts = obj.Stimulus.generate(p);
hPlot.XData = ts.Time;
hPlot.YData = ts.Data;

hAxes.XLim  = [-p.PreStimulus p.Duration+p.PostStimulus];
hAxes.YLim  = [0 p.Amplitude];
hAxes.YTick = [0 p.Amplitude];