function plotStimulus(obj)

obj.h.plot.stimulus.XData = obj.Stimulus.Timeseries.Time;
obj.h.plot.stimulus.YData = obj.Stimulus.Timeseries.Data;

xlim(obj.h.axes.stimulus,[-obj.Stimulus.PreStimulus ...
    obj.Stimulus.Duration + obj.Stimulus.PostStimulus])
ylim(obj.h.axes.stimulus,[0 obj.Stimulus.Amplitude])