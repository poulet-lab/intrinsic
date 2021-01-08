% Copyright (C) 2020 Florian Rau
%
% This file is part of setMenuIcon.
% 
% setMenuIcon is free software: you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation, either version 3 of the License, or (at your
% option) any later version.
% 
% setMenuIcon is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along
% with setMenuIcon.  If not, see <https://www.gnu.org/licenses/>.


%% Step 1: create figure, menus and menu-items

hFigure = figure( ...                           % create figure
    'Menu',       	'none', ...
    'NumberTitle', 	'off', ...
    'DockControls',	'off', ...
    'Name',      	'Demo');

hMenu(1) = uimenu(hFigure,'Text','Menu');       % add menu to figure
hItem(1) = uimenu(hMenu(1),'Text','Item');      % add item to menu

hMenu(2) = uimenu(hMenu(1),'Text','Submenu');   % add submenu to menu
hItem(2) = uimenu(hMenu(2),'Text','Boo!');      % add item to submenu


%% Step 2: set icons for menus & menu-items

setMenuIcon(hMenu(1),'example1.png')
setMenuIcon(hItem(1),'example2.png')
setMenuIcon(hMenu(2),'example3.png')
setMenuIcon(hItem(2),'example4.png')
