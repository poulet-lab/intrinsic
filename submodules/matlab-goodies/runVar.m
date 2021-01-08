function out = runVar(mean0,var0,data,n,w)
% RUNVAR  Calculate running variance.
%   RUNVAR is an implementation of Welford's online algorithm for
%   calculating variance. Input parameters are:
%
%       MEAN0:  mean of previous iteration
%       VAR0:   variance of previous iteration
%       DATA:   incoming data
%       N:      index of current iteration
%
%       W = 0:  normalizes by the number of observations - 1 (default)
%       W = 1:  normalizes by the number of observations
%
% (c) 2019 Florian Rau

narginchk(4,5)
if nargin < 5
    w = 0;
end

if n == 1
    out   = zeros(size(data));
else
    mean1 = mean0 + (data - mean0) / n;
    norm  = n - ~w;
    out   = (var0 .* (norm - 1) + (data - mean0) .* (data - mean1)) / norm;
end