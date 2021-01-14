function clearData(obj,force)

% Double check with user
if ~(nargin==2 && force)
    answer = questdlg('This will clear all unsaved data. Are you sure?',...
        'Warning!','Yes','Cancel','Cancel');
    if isempty(answer) || strcmp(answer,'Cancel')
        return
    end
end

% Feedback
intrinsic.message('Clearing temporary data')

% Clear object's properties
obj.Mean = [];
obj.Var = [];
obj.n = 0;
obj.Trials = [];
obj.Unsaved = false;

% Delete temporary files
delete(fullfile(obj.DirTemp,'*'))