function plotStimulus(obj,p)

if ~exist('p','var') && ~isempty(obj.DAQ.OutputData)
    ts = obj.DAQ.OutputData.Stimulus;
    p  = struct(obj.Stimulus);
elseif exist('p','var')
    ts = obj.Stimulus.generate(p);
else
    return
end

set(obj.h.plot.stimulus, ...
    'XData',    ts.Time, ...
    'YData',    ts.Data);
set(obj.h.axes.stimulus, ...
    'XLim',     [-p.PreStimulus p.Duration+p.PostStimulus], ...
    'YLim',     [0 p.Amplitude], ...
    'YTick',    [0 p.Amplitude]);