function message(varargin)

narginchk(1,inf)

if nargin == 1
    formatSpec  = '%s';
else
    formatSpec  = varargin{1};
    varargin(1) = [];
end
formatSpec = ['%s  ' formatSpec '\n'];

fprintf(formatSpec,datestr(now,'HH:MM:SS'),varargin{:})