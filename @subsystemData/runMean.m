function runMean(obj,data)

% Cast data to desired class
data = cast(data,obj.DataType);

if obj.nTrials == 1
    % Initialize Mean and Var
    obj.DataMean = data;
    obj.DataVar  = zeros(size(data),obj.DataType);
else
    % Update Mean and Var using Welford's online algorithm
    norm  = obj.nTrials - 1;
    mean0 = obj.DataMean;
    obj.DataMean = mean0 + (data - mean0) / obj.nTrials;
    obj.DataVar  = (obj.DataVar .* (norm-1) + (data-mean0) .* ...
        (data-obj.DataMean)) / norm;
end

% Implement the above for median?
% https://changyaochen.github.io/welford/#how-about-median