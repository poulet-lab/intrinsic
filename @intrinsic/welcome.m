function welcome(obj)

p   = 25;
fsz = 18;

logo = fullfile(pwd,'icons','logo.png');
[img,~,alpha] = imread(logo);
whlogo = size(img,[2 1]);

f = figure( ...
    'Position',     [50 50 whlogo+2*p + [0 fsz+p]], ...
    'Resize',       'off', ...
    'Visible',      'off', ...
    'Name',         'Welcome to ...', ...
    'WindowStyle',  'modal', ...
    'NumberTitle',  'off', ...
    'Units',        'pixels');

a = axes(f, ...
    'Units',        'pixels', ...
    'Position',     [p f.Position(4)-whlogo(2)-p whlogo]);

image(img, ...
    'AlphaData',    alpha, ...
    'Parent',       a);

a.Visible = 'off';

uicontrol(f, ...
    'Style',        'text', ...
    'Position',     [p p-0.2*fsz f.Position(3)-50 1.2*fsz], ...
    'String',       ['Version ' obj.Version], ...
    'FontUnits',    'pixels', ...
    'FontSize',     fsz);

movegui(f,'center')
f.Visible = 'on';
drawnow

addlistener(obj,'Ready',@(~,~) delete(f));
t = timer('TimerFcn',@(~,~) delete(f),'StartDelay',10);
t.start