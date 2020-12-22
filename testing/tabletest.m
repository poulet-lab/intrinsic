close all
clear
clc

t = table( {'40x'}, {'QiCam'}, {'modestr'}, 1203, ...
    'VariableNames',    {'Magnification', 'Camera', 'Mode', 'Px/cm'});
t = repmat(t,40,1);
t = table2cell(t);


h = figure;
ht = uitable(h,'Data',t);

