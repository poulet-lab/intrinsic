function varargout = generateStimulus(obj,varargin)

% parse input arguments
ip  = inputParser;
addOptional(ip,'stimParams',struct,@(x) validateattributes(x,...
    {'struct'},{'scalar'}));
addOptional(ip,'fs',obj.DAQ.Session.Rate,@(x) validateattributes(x,...
    {'numeric'},{'scalar','positive','real'}));
parse(ip,varargin{:})
p   = ip.Results.stimParams;    % stimulus parameters
fs  = ip.Results.fs;            % sampling rate (Hz)
ds	= obj.Camera.Downsample;    % downsampling factor
fps = obj.Camera.FrameRate;

% Load stimulus parameters from disk, if they were not passed
% (they are only being passed, if the stimulus is generated for
% viewing purposes, i.e., within the stimulus settings window)
if isempty(fieldnames(p))
    if ~ismember('Stimulus',who(obj.Settings))
        obj.settingsStimulus
    end
    p = obj.Settings.Stimulus;
end

% Generate times where we send out a ttl to the cam
rateOvs = fps / ds;
nPerNeg = ceil(rateOvs*p.pre)-.5;
nPerPos = ceil(rateOvs*(p.d+p.post))-.5;
t_ovs   = (-nPerNeg:nPerPos)/rateOvs;

% Generate times where we send out a ttl to the cam
nPerNeg = nPerNeg*ds + floor(ds/2-.5) + (obj.WarmupN > 0);
nPerPos = nPerPos*ds +  ceil(ds/2-.5);
t_trig  = ((-nPerNeg:nPerPos) -(~mod(ds,2)*.5)) / fps;

% Prepend remaining sample numbers for warmup
% (the first warmup trigger has already been added above)
if obj.WarmupN > 1
    t_warm  = t_trig(1) - (obj.WarmupN-1:-1:1)/obj.WarmupRate;
    t_trig  = [t_warm t_trig];
end

% build ttl + time vectors (append + prepend 100ms of silence)
s_trig      = round(t_trig*fs);
tax         = (s_trig(1)-.1*fs):(s_trig(end)+.1*fs);
ttl_cam     = ismember(tax,s_trig);
tax         = tax/fs;
ttl_view    = ismember(tax,round(t_ovs*fs)/fs);

% generate stimulus
switch p.type
    case 'Sine'
        d   = round(p.d*p.freq)/p.freq;     	% round periods
        t   = (1:d*fs)/fs;                      % time axis
        tmp = (sin(2*pi*p.freq*t-.5*pi)/2+.5);  % generate sine
        
    otherwise
        % generate square wave
        per	= [ones(1,ceil(1/p.freq*fs*p.dc/100)) ...
            zeros(1,floor((1/p.freq*fs)*(1-p.dc/100)))];
        tmp	= repmat(per,1,round(p.d*p.freq));
        
        % add ramp by means of convolution
        if p.ramp > 0
            ramp = ones(1,ceil(1/p.freq*fs*p.ramp/100*p.dc/100));
            tmp  = conv(tmp,ramp)/length(ramp);
        end
end
tmp = tmp(1:find(tmp,1,'last')); 	% remove trailing zeros
tmp = tmp * p.amp;                  % set amplitude
out = zeros(size(tax));
s0  = find(tax==0);
out(s0+1:s0+length(tmp)) = tmp;

if nargout == 0
    obj.DAQvec.stim = out;
    obj.DAQvec.time = tax;
    obj.DAQvec.cam  = ttl_cam;
    obj.Time        = obj.DAQvec.time(ttl_view);
    obj.IdxStimROI  = obj.Time>=0;
    if isfield(obj.h,'axes')
%         obj.h.plot.stimulus.XData = tax;
%         obj.h.plot.stimulus.YData = out;
%         xlim(obj.h.axes.stimulus,tax([1 end]))
%         ylim(obj.h.axes.stimulus,[0 max(out)*10])
        obj.clearData
        obj.update_plots
        obj.plotCameraTrigger
    end
else
    varargout{1} = out;
    varargout{2} = tax;
    varargout{3} = ttl_cam;
end