function addpathr(varargin)
% ADDPATHR  Recursively add folders to search path.
%   ADDPATHR will add the user provided directories and all of their
%   subdirectories to the MATLAB search path. Hidden folders and MATLAB
%   special folders are being ignored.
%
% (c) 2016 Florian Rau

for d = varargin
    if isdir(d{:})
        
        % add current directory to search path
        addpath(d{:})
        
        % find valid subdirectories
        sub = dir(d{:});
        sub = sub([sub.isdir]);
        sub = {sub(~cellfun(@isempty,{sub.date})).name}; 
        sub = sub(cellfun(@isempty,regexpi(sub,'^[.+@]','once')));
        sub = fullfile(d{:},sub);
        
        % process subdirectories
        addpathr(sub{:})

    else
        return
    end    
end
    