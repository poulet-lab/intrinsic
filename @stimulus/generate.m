function varargout = generate(obj,fs)

% check arguments
nargoutchk(0,1)
narginchk(1,2)
if ~exist('fs','var')
    fs = obj.Parent.DAQ.Session.Rate;
end

% create time axis
t      = -obj.PreStimulus : (1/fs) : (obj.Duration + obj.PostStimulus);
[~,i0] = min(abs(t));
t      = t - t(i0);

% create stimulus waveform
d = round(obj.Duration * obj.Frequency) / obj.Frequency;
switch obj.Type
    case 'Sinusoidal'
        s = sinpi(2 * obj.Frequency * (0:d*fs)/fs - .5) / 2 + .5;
    otherwise
        r = mod((0:fs*d-1) / fs * obj.Frequency,1);
        s = r <= obj.DutyCycle/100;
        
        if obj.Ramp > 0
            r = ones(1, ceil(1/obj.Frequency * fs * obj.Ramp/100*obj.DutyCycle/100));
            s = conv(s,r)/length(r);
        end
end
s = s * obj.Amplitude;

% place stimulus
x = zeros(size(t));
x(i0+(0:numel(s)-1)) = s;

% create timeseries
ts = timeseries(x,t,'Name','Stimulus');
ts.DataInfo.Units = 'V';

% handle output arguments
if nargout
    varargout{1} = ts;
else
    obj.Timeseries = ts;
end