function out = isCallback()
% ISCALLBACK  Identify callback functions.
%   Returns true if the parent function is a GUI callback.
%
% (c) 2020 Florian Rau

% get function call stack
stack = dbstack(1);
if numel(stack) < 2
    out = false;
    return
end

% extract name of functions from function call stack
fn = regexpi({stack.name},'([a-zA-Z]\w*)(?:\([^\)]*\))?$','tokens','once');
if numel(fn) < 2
    out = false;
	return
end
fn  = [fn{1:2}];

% return result
out = isequal(fn{:}) && any(strfind(stack(2).name,'(varargin{:})'));