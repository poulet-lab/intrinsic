function settingsStimulus(obj,~,~)

%% Define UI Elements
tmp = {'Sine' 'Square' 'Triangle'};
ui_params = { ...
    %TAG	LABEL                   UI-TYPE     VALUE	LIMITS
    'type' 	'Signal Type'         	'popupmenu' tmp    	[];        ...
    'freq' 	'Frequency / Hz'      	'edit'      10      [.1 1000]; ...
    'dc'  	'Duty Cycle / %'     	'edit'      20      [0  100];  ...
    'ramp' 	'Ramp / %'              'edit'      0       [0  100];  ...
    'amp'  	'Amplitude / V'         'edit'      5       [0  10];   ...
    'd'    	'Stimulus Duration / s'	'edit'      4       [0  10];   ...
    'pre'  	'Pre-Stimulus / s'      'edit'      4       [0  10];   ...
    'post' 	'Post-Stimulus / s'     'edit'      8       [0  10];   ...
    'inter'	'Inter-Stimulus / s'	'edit'      20      [0  600]};

%% Load Settings
try 
    stim = obj.Settings.Stimulus;
    for ii = 1:size(ui_params,1)
        switch ui_params{ii,1}
            case 'type'
                ui_params{ii,5} = find(strcmp(tmp,stim.type));
            otherwise
                ui_params{ii,4} = stim.(ui_params{ii,1});
        end
    end
catch
    stim = [];
    for ii = 1:size(ui_params,1)
        if strcmp(ui_params{ii,3},'popupmenu')
            stim.(ui_params{ii,1}) = ui_params{ii,4}{1};
        else
            stim.(ui_params{ii,1}) = ui_params{ii,4};
        end
    end
    obj.Settings.Stimulus = stim;
end

%% Create and populate figure
base = 50;
marg = 5;
hgth = 23;
wdth = [105 65 600];
hfig = figure( ...
    'Position',     [100 100 sum(wdth)+2*marg+100 size(ui_params,1)*25+base+25], ...
    'Visible',      'off', ...
    'Toolbar',    	'none', ...
    'Menu',       	'none', ...
    'NumberTitle', 	'off', ...
    'Resize',     	'off', ...
    'Name',        	'Stimulus Settings', ...
    'WindowStyle', 	'modal');
for ii = 1:size(ui_params,1)
    pos = [marg abs(ii-size(ui_params,1))*25+marg+base];
    tag	= ui_params{ii,1};
    uicontrol( ...
        'Style',      'text', ...
        'Position',   [pos+[0 -5] wdth(1) hgth], ...
        'String',     [ui_params{ii,2} ':'], ...
        'Horizontal', 'right')
    hui.(ui_params{ii,1}) = uicontrol( ...
        'Style',      ui_params{ii,3}, ...
        'Position',   [pos+[wdth(1)+marg 0] wdth(2) hgth],...
        'Tag',        tag, ...
        'Callback',   @ui_callback);
    if strcmp(ui_params{ii,3},'popupmenu')
        hui.(tag).String = ui_params{ii,4};
        hui.(tag).Value  = find(strcmp(hui.(tag).String,stim.(tag)),1);
    else
        hui.(tag).Value  = stim.(tag);
        hui.(tag).String = stim.(tag);
    end
end
hui.ok = uicontrol( ...
    'Position', [marg marg sum(wdth(1:2))/2+1 23], ...
    'String',   'OK', ...
    'Callback',	@button_callback);
hui.cancel = uicontrol( ...
    'Position', [2*marg+hui.ok.Position(3) marg sum(wdth(1:2))/2+1 23],...
    'String',   'Cancel', ...
    'Callback',	@button_callback);

hui.axes = axes( ...
    'Units',    'Pixels', ...
    'Position', [hui.(ui_params{end,1}).Position([1 2]) + ...
                [wdth(2)+70 0] wdth(3) ...
                hui.(ui_params{1,1}).Position(2) + ...
                hgth-marg-base], ...
    'fontsize', 9, ...
    'tickdir',  'out', ...
    'Color',   	'none');
hold on
hui.plot = area(hui.axes,NaN,NaN,'edgecolor','none','facecolor','k');
xlabel('Time (s)')
ylabel('Amplitude (V)')
zoom xon

%% Last touches
ui_callback(hui.type)
movegui(hfig,'center')
hfig.Visible = 'on';

%% Callback Functions

    function ui_callback(hobj,~,~)
        switch hobj.Tag
            case 'type'
                switch hobj.String{hobj.Value}
                    case 'Sine'
                        stim.dc         = 50;
                        stim.ramp       = NaN;
                        hui.dc.Enable   = 'off';
                        hui.ramp.Enable = 'off';
                    case 'Square'
                        stim.ramp       = 0;
                        hui.dc.Enable   = 'on';
                        hui.ramp.Enable = 'on';
                    case 'Triangle'
                        stim.dc         = 50;
                        stim.ramp       = 100;
                        hui.dc.Enable   = 'off';
                        hui.ramp.Enable = 'off';
                end
                hui.dc.String   = stim.dc;
                hui.ramp.String = stim.ramp;
                stim.type       = hobj.String{hobj.Value};
                
            otherwise
                idx = find(strcmp(ui_params(:,1),hobj.Tag));
                val = str2double(hobj.String);

                if isnan(val)
                    val = ui_params{idx,4};
                elseif val < ui_params{idx,5}(1)
                    val = ui_params{idx,5}(1);
                elseif val > ui_params{idx,5}(2)
                    val = ui_params{idx,5}(2);
                end
                stim.(hobj.Tag) = val;
                hobj.Value      = val;
                hobj.String     = val;
                
                if stim.inter < stim.pre + stim.post
                    stim.inter = stim.pre + stim.post;
                    hui.inter.String = stim.inter;
                end

        end
        
        [Y,X] = obj.generateStimulus(stim,1000);    % Get stimulus vector
        hui.plot.XData = X;                         % Update area plot
        hui.plot.YData = Y;
        xlim(hui.axes,X([1 end]))                	% Set axes limits
        ylim(hui.axes,[0 stim.amp])
    end

    function button_callback(hobj,~,~)
        if strcmp(hobj.String,'OK')
            obj.Settings.Stimulus = stim;
            obj.generateStimulus
        end
        delete(gcf)
    end
end