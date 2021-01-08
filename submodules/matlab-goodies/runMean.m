function out = runMean(mean0,data,n)
% RUNMEAN Calculate running mean.
%   RUNMEAN calculates the running mean. Input parameters are:
%
%       MEAN0:  mean of previous iteration
%       DATA:   incoming data
%       N:      index of current iteration
%
% (c) 2019 Florian Rau

if n == 1
    out = data;
else
    out = mean0 + (data - mean0) / n;
end