function checkDirTemp(obj)

if numel(dir(obj.DirTemp)) > 2
    str = sprintf(['The directory for temporary data is not empty. ' ...
        'This could be due to a crash in a previous session. Please ' ...
        'double-check and clear the directory''s contents manually.' ...
        '\n\n%s'], obj.DirTemp);
    tmp = errordlg(str,'Error');
    uiwait(tmp)
    if ispc
        winopen(obj.DirTemp);
    end
    error(str) %#ok<SPERR>
end