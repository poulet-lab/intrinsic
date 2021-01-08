function raster(x,yfill,hax,varargin)
% RASTER  Generate raster plot.
%   RASTER(X) will draw a raster plot for the x-values defined in X.
%   Multiple trials can be passed as a cell-array. YFILL defines the height
%   of tickmarks relative to the row-height. HAX is an axes handle.
%   VARARGIN will be passed directly to the LINE function (e.g., for
%   setting line colors).
%
% (c) 2016 Florian Rau


% check input args
if ~exist('yfill','var')
    yfill = .8;
end
if ~exist('hax','var')
    hax = gca;
end
if ~iscell(x)
    x = {x};
end
if ~ishandle(hax)
    varargin = [hax varargin];
    hax = gca;
end

% loop through trials
for ii = 1:length(x)                        
    xs  = x{ii}(:);                         % convert x to column
    xs  = [xs xs nan(size(xs))]';           % define xlims, separate w/ NaN
    xs  = xs(:);                            % convert xs to column
    
    ys  = [ii-yfill/2; ii+yfill/2; NaN];    % define ylims, separate w/ NaN
    ys  = repmat(ys,size(xs,1)/3,1);        % repeat for each tick
    
    line(xs,ys,'Parent',hax,varargin{:})    % draw ticks for current trial
end

% setup appearance of axis
hax.YDir  = 'Reverse';
hax.YLim  = [.5-(1-yfill)/2 ii+.5+(1-yfill)/2];
hax.YTick = unique([1 hax.YTick(mod(hax.YTick,1)==0 & hax.YTick>0)]);