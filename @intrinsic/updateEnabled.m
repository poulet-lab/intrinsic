function updateEnabled(obj,~,~)

% Helper function for converting bool values to 'on' / 'off'
toggle = @(h,x) set(h,'Enable',subsref({'off','on'},substruct('{}',{x+1})));

% Toggle main figure's menu
toggle(findobj(obj.h.fig.main,'Type','uimenu','Parent',obj.h.fig.main),...
    ~obj.Data.Running)

% Toggle buttons for saving and printing the dataset
toggle([obj.h.push.save obj.h.menu.fileSave obj.h.menu.filePrint],...
    ~obj.Data.Running && obj.Data.Unsaved)

% Toggle buttons for creating and loading a dataset
toggle([obj.h.push.new obj.h.push.open obj.h.menu.fileOpen ...
    obj.h.menu.fileNew],~obj.Data.Running)

% Bool: all necessary subsystems available
subsystems = obj.Camera.Available && obj.DAQ.Available;

% Toggle toolbar buttons
toggle([obj.h.push.liveGreen obj.h.push.capture obj.h.push.liveRed],...
    ~obj.Data.Running && subsystems)

% Toggle start button
toggle(obj.h.push.start,~obj.Data.Running && ~obj.Data.Unsaved && subsystems)

% Toggle stop button
toggle(obj.h.push.stop,obj.Data.Running && subsystems)
