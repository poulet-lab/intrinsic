function plotStimulus(obj,p)

if ~exist('p','var')
    p = obj.Stimulus.Parameters;
end

ts = obj.Stimulus.generate(p);

obj.h.plot.stimulus.XData = ts.Time;
obj.h.plot.stimulus.YData = ts.Data;

xlim(obj.h.axes.stimulus,[-p.PreStimulus p.Duration+p.PostStimulus])
ylim(obj.h.axes.stimulus,[0 p.Amplitude])