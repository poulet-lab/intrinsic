function ts = generate(obj,p,fs)

% check arguments
if ~exist('p','var') || isempty(p)
    p = obj.Parameters;
end
if ~exist('fs','var')
    fs = obj.Parent.DAQ.Session.Rate;
end

% create time axis
t      = -p.PreStimulus : (1/fs) : (p.Duration + p.PostStimulus - 1/fs);
[~,i0] = min(abs(t));
t      = t - t(i0);

% create stimulus waveform
d = round(p.Duration * p.Frequency) / p.Frequency;
switch p.Type
    case 'Sinusoidal'
        s = sinpi(2 * p.Frequency * (0:d*fs)/fs - .5) / 2 + .5;
    otherwise
        r = mod((0:fs*d-1) / fs * p.Frequency,1);
        s = r <= p.DutyCycle/100;
        
        if p.Ramp > 0
            r = ones(1,ceil(1/p.Frequency*fs*p.Ramp/100*p.DutyCycle/100));
            s = conv(s,r)/length(r);
        end
end
s = s * p.Amplitude;

% place stimulus
x = zeros(size(t));
x(i0+(0:numel(s)-1)) = s;

% create timeseries
ts = timeseries(x,t,'Name','Stimulus');
ts.DataInfo.Units = 'V';