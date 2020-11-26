function obj = cbOkay(obj,~,~)

% apply & save values of edit fields
Parameters = getappdata(obj.Figure,'parameters');
for Var = fieldnames(Parameters)'
    obj.saveVar(Var{:},Parameters.(Var{:}))
end
if ~isequaln(obj.Parameters,Parameters)
    obj.Parameters = Parameters;
end

% close figure
close(obj.Figure)
