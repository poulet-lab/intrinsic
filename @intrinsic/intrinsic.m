classdef intrinsic < handle & matlab.mixin.CustomDisplay
    
    properties
        DAQ             = [] %daq.createSession('ni');
        h               = []        % handles

        DirBase         = fileparts(fileparts(mfilename('fullpath')));
        DirSave
        
        VideoPreview
        VideoInputRed
        VideoInputGreen
        
        Scale
        RateCam         = 10
        RateDAQ         = 10000

        PointCoords     = nan(1,2)
        LineCoords      = nan(1,2)
        
        StackStim       % raw data
        Sequence        % relative response (averaged across trials)
        SequenceVar
        Movie           % relative response (same as obj.Sequence, as movie)
        ImageRedDiff    % relative response (averaged across trials & time)
        ImageRedBase    % 
        ImageRedStim    % 
        ImageGreen      % snapshot of anatomical details
        
        Toolbox
        Settings
        
        DAQvec
    end
    
    properties (Dependent = true)
        nTrials
        Figure
        ROISize
        Point
        Line
        Binning
    end
    
    methods
        
        % Class Constructor
        function obj = intrinsic(varargin)
            
            % Warn if necessary toolboxes are unavailable
            for tmp = struct2cell(obj.Toolbox)'
                if ~tmp{1}.available
                    warning([tmp{1}.name ' not available'])
                end
            end
           
            % Manage path
            addpath(fullfile(obj.DirBase,'submodules','matlab-tools'))
            addpathr(fullfile(obj.DirBase,'submodules'))
                        
            % Settings are loaded from / saved to disk
            obj.Settings = matfile(fullfile(obj.DirBase,'settings.mat'),...
                'Writable',true);
            
            % Initialize some variables
            obj.h.image.green = [];
            obj.h.image.red   = [];
            
            % Initialize the Image Acquisition Subsystem
            obj.settingsVideo 	% Set video device
                       
            % Initialize the Data Acquisition Subsystem
            % TODO
            
            % Generate Stimulus
            obj.generateStimulus
            
            obj.mainGUI         % Create main window
            obj.updateEnabled   % Update availability of UI elements
        end
        
    end
    
    % Methods defined in separate files:
    methods (Access = private)
        mainGUI(obj)                            % Create MAIN GUI
        previewGUI(obj,hbutton,~)               % Create PREVIEW GUI
        greenGUI(obj)                           % Create GREEN GUI
        redGUI(obj)                             % Create RED GUI
        settingsStimulus(obj,~,~)             	% Stimulus Settings
        fileSave(obj,~,~)
    end

    methods %(Access = private)
        function updateEnabled(obj)
            
            IAQ = obj.Toolbox.ImageAcquisition.available;
            IP  = obj.Toolbox.ImageProcessing.available;
            DAQ = obj.Toolbox.DataAcquisition.available;
            VID = isa(obj.VideoInputRed,'videoinput');
            tmp = {'off', 'on'};
            
            % UI elements depending on Image Acquisition Toolbox
            elem = obj.h.menu.settingsVideo;
            cond = IAQ;
            set(elem,'Enable',tmp{cond+1});
            
            % UI elements depending on Image Acquisition Toolbox & valid
            % video-input
            elem = [...
                obj.h.push.capture, ...
                obj.h.push.liveGreen, ...
                obj.h.push.liveRed];
            cond = IAQ && VID;
            set(elem,'Enable',tmp{cond+1});
            
            % UI elements depending on all Toolboxes
            elem = [obj.h.push.start obj.h.push.stop];
            cond = IAQ && IP && DAQ && VID;
            set(elem,'Enable',tmp{cond+1});

        end

        %% all things related to the GREEN image
        
        function greenCapture(obj,~,~)          % Take a snapshot
            
            % Create green window, if its not there already
            if ~isfield(obj.h.fig,'green')
                obj.greenGUI
            end
            
            % If red preview is running, we need to stop it temporarily
            if isa(obj.VideoPreview,'video_preview')
                preview_was_running = obj.VideoPreview.Preview;
                if strcmp(obj.VideoInputRed.preview,'on')
                    obj.VideoPreview.Preview = false;
                end
            end
            
            % Capture and process image
            obj.ImageGreen = getsnapshot(obj.VideoInputGreen); % Capture
            obj.h.image.green.CData = obj.ImageGreen;          % Update display
            obj.greenContrast(obj.h.check.greenContrast)       % Enhance Contrast
            
            % Return to former preview state
            if isa(obj.VideoPreview,'video_preview')
                obj.VideoPreview.Preview = preview_was_running;
            end
            
            % Focus the green window
            figure(obj.h.fig.green)
        end
        
        function greenContrast(obj,hcheck,~)    % Stretch the contrast
            obj.Settings.greenContrast = hcheck.Value;
            if hcheck.Value
                %tmp = [min(obj.ImageGreen(:)) max(obj.ImageGreen(:))];
                tmp = quantile(obj.ImageGreen(:),[.005 .995]);
                if tmp(1) == tmp(2)
                    tmp(2) = tmp(1) + 1;
                end
                set(obj.h.axes.green,'Clim',tmp);
            else
                set(obj.h.axes.green,'Clim',[0 2^12-1]);
            end
        end
        
        
        %% all things related to the RED image stack
        
        function redClick(obj,h,~)              % Define point and line
            hfig    = h.Parent.Parent.Parent;
            coord   = round(h.Parent.CurrentPoint(1,1:2));
           	switch get(hfig,'SelectionType')
                case 'normal'
                    obj.Point = coord;
                case 'alt'
                    obj.Line  = coord;
                case 'extend'
                    % get rectangle
                    c1  = round(obj.h.axes.red.CurrentPoint(1,1:2));
                    rbbox;
                    c2  = round(obj.h.axes.red.CurrentPoint(1,1:2));
                    c2  = min([c2; obj.ROISize]);
                    tmp = sort([c1; c2]);
                    tmp = [tmp(1,1:2) tmp(2,1:2)];
                    tmp = obj.ImageRedDiff(tmp(2):tmp(4),tmp(1):tmp(3));
                    tmp = max(abs(tmp(:)));
                    
                    tmp = sprintf('%0.2f',sum(abs(obj.ImageRedDiff(:))<=tmp) / ...
                        length(obj.ImageRedDiff(:)) * 100);
                    obj.h.edit.redRange.String = tmp;
                    obj.processStack
                otherwise
                    return
            end
        end
        
        function redPeak(obj,~,~)               % Peak intensity of stack
            [~,I] = max(abs(obj.ImageRedDiff(:)));
            [y,x] = ind2sub(size(obj.ImageRedDiff),I);
            obj.Point = [x y];
        end
        
        function redPlayback(obj,~,~)           % Play stack as movie

            % disable UI controls
            tmpobj = struct2cell(obj.h.fig);
            tmpobj = findobj([tmpobj{:}],'Enable','on');
            set(tmpobj,'Enable','off')
            
            % create temporary axes for movie
            tmpax = axes(...
                'Parent',   obj.h.panel.red, ...
                'Position', obj.h.axes.red.Position, ...
                'Visible',  'off');
            
            % play movie
            movie(tmpax,obj.Movie,1,obj.RateCam,[2 2 0 0])
            
            % delete temporary axes, enable UI controls
            delete(tmpax)
            set(tmpobj,'Enable','on')
            
        end
        
        function redRange(obj,hedit,~)          % Range of colormap
            value = str2double(hedit.String);
            if isempty(value) || value<=0 || value>100
                hedit.String = '100';
            end
            obj.processStack
            
            obj.Settings.redRange = value;      % update settings
        end
        
        function redSigma(obj,hedit,~)                  % Gaussian smoothing
            value = str2double(hedit.String);
            if isempty(value) || value<0
                hedit.String = '0';
            end
            obj.processStack
            
            if regexpi(hedit.TooltipString,'spatial')   % update settings
                obj.Settings.redSigmaSpatial = value;
            elseif regexpi(hedit.TooltipString,'temporal')
                obj.Settings.redSigmaTemporal = value;      
            end
        end
        
        function redView(obj,hdrop,~)           % Gaussian smoothing
            modus = hdrop.String{hdrop.Value};
            ptile = str2double(obj.h.edit.redRange.String)/100;
            
            if regexpi(modus,'difference')
                obj.h.edit.redSigmaSpatial.Enable  = 'on';
                obj.h.edit.redSigmaTemporal.Enable = 'on';
                obj.h.edit.redRange.Enable         = 'on';
                cmap = flipud(brewermap(2^8,'PuOr'));

                tmp  = sort(abs(obj.ImageRedDiff(:)));
                scal = tmp(ceil(length(tmp)*ptile));
                tmp  = floor(obj.ImageRedDiff ./ scal .* 2^7 + 2^7);
                
            elseif regexpi(modus,'sem')
                obj.h.edit.redSigmaSpatial.Enable  = 'on';
                obj.h.edit.redSigmaTemporal.Enable = 'on';
                obj.h.edit.redRange.Enable         = 'on';
                cmap = flipud(brewermap(2^8,'PuOr'));

                n    = obj.nTrials * length(obj.DAQvec.time(obj.DAQvec.cam)>0);
                tmp  = obj.DAQvec.time(obj.DAQvec.cam)>0;
                var  = mean(obj.SequenceVar(:,:,tmp),3);
                sem  = sqrt(var)/sqrt(n);
                sem  = (abs(mean(obj.Sequence(:,:,tmp),3)) ./ sem) >= 1;
                
                tmp  = sort(abs(obj.ImageRedDiff(:)));
                scal = tmp(ceil(length(tmp)*ptile));
                tmp  = floor(obj.ImageRedDiff ./ scal .* 2^7 + 2^7) .* sem;
                tmp(sem<1) = 2^7;
                
            elseif regexpi(modus,'base')
                obj.h.edit.redSigmaSpatial.Enable  = 'off';
                obj.h.edit.redSigmaTemporal.Enable = 'off';
                obj.h.edit.redRange.Enable         = 'off';
                cmap = gray(2^8);
                base = abs([obj.ImageRedBase(:); obj.ImageRedStim(:)]);
                tmp1 = abs(obj.ImageRedBase) - min(base);
                tmp2 = abs(obj.ImageRedStim) - min(base);
                tmp  = floor(tmp1 ./ max(tmp2(:)) .* 2^8);
                
            elseif regexpi(modus,'stim')
                obj.h.edit.redSigmaSpatial.Enable  = 'off';
                obj.h.edit.redSigmaTemporal.Enable = 'off';
                obj.h.edit.redRange.Enable         = 'off';
                cmap = gray(2^8);
                base = abs([obj.ImageRedBase(:); obj.ImageRedStim(:)]);
                tmp  = abs(obj.ImageRedStim) - min(base);
                tmp  = floor(tmp ./ max(tmp(:)) .* 2^8);
            end
            obj.h.image.red.CData = ind2rgb(tmp,cmap);
        end
        
        function redStart(obj,~,~)
            
            fignam = obj.h.fig.main.Name;
            nruns  = 10;
            
            obj.clearData
            obj.preallocateStack
            
            % camera warm-up
            n_warm 	 = 5;                       % number of warm-up frames
            f_warm 	 = 5;                       % warm-up framerate [Hz]
            tmp      = round(obj.RateDAQ/f_warm);
            ttl_warm = false(tmp*(n_warm-1)+diff(find(obj.DAQvec.cam,2)),1);
            ttl_warm(1:tmp:n_warm*tmp) = true;
            
            daq_vec  = full([ ...
                [ttl_warm(:); obj.DAQvec.cam(:)] ...
                [zeros(size(ttl_warm(:))); obj.DAQvec.stim(:)]]);

            % configure camera triggers
            triggerconfig(obj.VideoInputRed,'hardware','risingEdge','TTL')
            obj.VideoInputRed.FramesPerTrigger = 1;
            obj.VideoInputRed.TriggerRepeat    = sum(daq_vec(:,1))-1;
            obj.VideoInputRed.FramesAcquiredFcn = @count_frames;
            obj.VideoInputRed.FramesAcquiredFcnCount = 1;
            
%             obj.VideoInputRed.LoggingMode = 'Disk&Memory';
%             logfile = VideoWriter('logfile.mj2','Archival');
%             logfile.FrameRate   = obj.RateCam;
%             logfile.MJ2BitDepth = 12;
%             logfile.LosslessCompression = true;
%             obj.VideoInputRed.DiskLogger = logfile;
            
            % configure DAQ session
            device  = daq.getDevices;
            obj.DAQ = daq.createSession('ni');
            obj.DAQ.addDigitalChannel(device.ID,'Port0/line0','OutputOnly');
            obj.DAQ.addAnalogOutputChannel(device.ID,0,'Voltage');
            obj.DAQ.Channels(1).Name = 'Camera clock';
            obj.DAQ.Channels(2).Name = 'Stimulus';
            obj.DAQ.Rate = obj.RateDAQ;
            disp(obj.DAQ)

            tmp    = obj.Settings.Stimulus;
            dpause = round(tmp.inter-tmp.pre-tmp.post);
            
            
            for ii = 1:nruns
                start(obj.VideoInputRed)
                queueOutputData(obj.DAQ,daq_vec)
                obj.DAQ.startForeground;            % 

                if ~isrunning(obj.VideoInputRed) && ...
                        obj.VideoInputRed.FramesAvailable ~= ...
                        obj.VideoInputRed.TriggerRepeat+1
                    obj.h.fig.main.Name = fignam;
                    break
                end
                
                data = getdata(obj.VideoInputRed,sum(daq_vec(:,1)),'uint16');
                stop(obj.VideoInputRed)
                obj.StackStim(:,:,:,ii) = squeeze(data(:,:,1,n_warm+1:end));
                obj.processStack

%                 %%
%                 vid_read = VideoReader('logfile.mj2');
%                 n_frames = round(vid_read.Duration*vid_read.FrameRate);
%                 data     = zeros(vid_read.Height,vid_read.Width,n_frames,'uint16');
%                 for jj =1:n_frames
%                     data(:,:,jj) = readFrame(vid_read);
%                 end
%                 %%

                for pp = 1:dpause
                    tmp = sprintf(' - Waiting (%ds)',dpause-pp);
                    obj.h.fig.main.Name = [fignam tmp];
                    pause(1)
                end
            end
            obj.h.fig.main.Name = fignam;
            
            function count_frames(~,~,~)
                asd = sprintf(...
                    ' - Acquiring Data (run %d/%d, frame %d/%d)',...
                    [ii nruns obj.VideoInputRed.FramesAvailable ...
                    obj.VideoInputRed.TriggerRepeat+1]);
                obj.h.fig.main.Name = [fignam asd];
            end

        end
        

        
        function redStop(obj,~,~)
            stop(obj.VideoInputRed)
            obj.DAQ.stop
        end
        
        
        
        % Shared code for creation of Red/Green Figure
        function createGeneric(obj,name,margin,bottom)
            
            imsize  = obj.ROISize*obj.Scale;        % image size [px]
            psize   = imsize+4;                     % panel size [px]
            if bottom > 0                           % figure size [px]
                fsize   = psize+[2 3]*margin+[0 bottom];
                ppos    = [margin+1 2*margin+bottom psize];
            else
                fsize   = psize+2*margin;
                ppos    = [margin+1 margin psize];
            end
            
            obj.h.fig.(lower(name)) = figure( ...
                'Visible',          'off', ...
                'Toolbar',          'none', ...
                'Menu',             'none', ...
                'NumberTitle',      'off', ...
                'Resize',           'off', ...
                'DockControls',     'off', ...
                'Position',         [5 5 fsize], ...
                'Tag',              name, ...
                'Name',             [name ' Image'], ...
                'CloseRequestFcn',  {@(obj,~) set(obj,'visible','off')});
            obj.h.panel.(lower(name)) = uipanel(obj.h.fig.(lower(name)), ...
                'Units',            'Pixels', ...
                'BorderType',       'beveledin', ...
                'Position',         ppos, ...
                'Tag',              name, ...
                'BackgroundColor',  'black');
            obj.h.axes.(lower(name)) = axes(...
                'Parent',           obj.h.panel.(lower(name)), ...
                'Position',         [0 0 1 1], ...
                'Tag',              name, ...
                'DataAspectRatio',  [1 1 1], ...
                'CLimMode',         'manual', ...
                'Clim',             [0 2^12-1]);
            
            if strcmpi(name,'green')
                tmp = obj.ROISize * obj.Binning;
            else
                tmp = obj.ROISize;
            end
            obj.h.image.(lower(name)) = imshow(zeros(fliplr(tmp)),...
                'DisplayRange',     [0 2^12-1], ...
                'Parent',           obj.h.axes.(lower(name)));
        end
                
        % Load variable from file, return defaults if var/file not found
        function out = loadVar(obj,name,default)
            validateattributes(name,{'char'},{'vector'})
            if ~isempty(who(obj.Settings,name))
                out = obj.Settings.(name);
            else
                out = default;
            end
        end
        
        function out = get.nTrials(obj)
            if ndims(obj.StackStim)>3
                out = sum(squeeze(obj.StackStim(1,1,1,:)) ~= intmax('uint16'));
            else
                out = 0;
            end
        end
        
        % Return data directory
        function out = get.DirSave(obj)
            
            % Load from settings file
            out = obj.loadVar('DirSave',[]);
            if isdir(out)
                return
            end
            
            % Let user pick directory
            out = uigetdir('/','Select Data Directory');
            if isdir(out)
                obj.Settings.DirSave = out;
            end
            
        end
        
        % Setup the Videoinput
        function settingsVideo(obj,~,~)
            
            % We need the Image Acquisition Toolbox for this to work ...
            if ~obj.Toolbox.ImageAcquisition.available
                return
            end
            
            % If there IS a valid videoinput present already, lets assume
            % the user wants to modify its settings
            if isa(obj.VideoInputRed,'videoinput')
                tmp = questdlg({['Changing the video settings will ' ...
                    'discard all unsaved data.'] ['Do you really want ' ...
                    'to continue?']}, 'Warning', 'Right on!', ...
                    'Hold on a sec ...', 'Right on!');
                if ~strcmp(tmp,'Right on!')
                    return
                end
                obj.VideoPreview.Preview = false;
                delete(obj.VideoPreview.Figure)
                [obj.VideoInputRed, VidPref]   = ...
                    video_settings(obj.VideoInputRed,obj.Scale,obj.RateCam);
                %obj.previewGUI
                obj.VideoPreview.Scale = VidPref{5};
            
            % Else, if there is no valid videoinput yet (e.g., after
            % start-up), try to load the settings from disk. If this fails,
            % prompt the user for input.
            else
                try
                    VidPref = obj.Settings.VidPref;
                    obj.VideoInputRed = videoinput(VidPref{1:3});
                catch
                    [obj.VideoInputRed,VidPref] = video_settings;
                end
            end
            
            % In case we have a valid videoinput by now, save its current
            % settings to disk and update the corresponding fields of the
            % main object. If anything went wrong, throw an error.
            if isa(obj.VideoInputRed,'videoinput')
                
                obj.Settings.VidPref          = VidPref;
                obj.VideoInputRed.ROIPosition = VidPref{4};
                obj.Scale                     = VidPref{5};
                obj.RateCam                   = VidPref{6};
                
                if obj.Binning > 1 && regexpi(imaqhwinfo(obj.VideoInputRed,'DeviceName'),'^QICam')
                    current = obj.VideoInputRed.VideoFormat;
                    current = textscan(current,'%s%n%n','Delimiter',{'_','x'});
                    tmp   	= imaqhwinfo('qimaging','DeviceInfo');
                    tmp   	= tmp.SupportedFormats;
                    asd     = regexp(tmp,['(?<=^' current{1}{:} '_)\d*'],'match');
                    [~,ii]  = max(str2double([asd{:}]));
                    obj.VideoInputGreen = videoinput(VidPref{1:2},tmp{ii});
                    obj.VideoInputGreen.ROIPosition  = VidPref{4} * obj.Binning;
                else
                    obj.VideoInputGreen = videoinput(VidPref{1:3});
                    obj.VideoInputGreen.ROIPosition = VidPref{4};
                end
                
                if regexpi(imaqhwinfo(obj.VideoInputRed,'DeviceName'),'^QICam')
                    tmp = propinfo(obj.VideoInputRed.Source,'NormalizedGain');
                    set(obj.VideoInputRed.Source, ...
                        'NormalizedGain',   tmp.ConstraintValue(1), ...
                    	'ColorWheel',       'red')
                    set(obj.VideoInputGreen.Source, ...
                        'ColorWheel',       'green')
                end

            else
                warning('No camera found. Did you switch it on?')
            end
        end
        
        % Update checkmarks in the VIEW menu
        function updateMenuView(obj,h,~)
            delete(h.Children)
            for ii = fieldnames(obj.h.fig)'
                hi = obj.h.fig.(ii{:});
                switch ii{:}
                    case 'main'
                        continue
                    case 'preview'
                        uimenu(h, ...
                            'Label',   	hi.Name, ...
                            'UserData',	obj.VideoPreview, ...
                            'Callback',	{@obj.toggleMenuView}, ...
                            'Checked', 	hi.Visible);
                    otherwise
                        uimenu(h, ...
                            'Label',   	hi.Name, ...
                            'UserData',	hi, ...
                            'Callback',	{@obj.toggleMenuView}, ...
                            'Checked', 	hi.Visible);
                end
            end
        end
        
        % Toggle checkmarks in the VIEW menu
        function toggleMenuView(~,h,~)
            if strcmp(h.UserData.Visible,'on')
                h.UserData.Visible = 'off';
            else
                h.UserData.Visible = 'on';
            end
        end
        
        % Save window positions
        function saveWindowPositions(obj,~,~)
            for fn = fieldnames(obj.h.fig)'
                obj.Settings.(['WinPos_' fn{:}]) = obj.h.fig.(fn{:}).Position;
            end
        end

        % Restore window positions
        function restoreWindowPositions(obj,varargin)
            
            % Get available window positions
            if ~isempty(varargin)
                tmp = cellfun(@(x) ['WinPos_' x],varargin,'uni',0);
                fns = whos(obj.Settings,tmp{:});
            else
                fns = whos(obj.Settings,'WinPos_*');
            end
            fns = cellfun(@(x) x(8:end),{fns.name},'uni',0);
            
            % Limit list of windows to restore positions for
            fns = intersect(fns,fieldnames(obj.h.fig));
            fns = fns(cellfun(@(x) ishandle(obj.h.fig.(x)),fns));
            
            % Restore positions
            for ii = 1:length(fns)
                if strcmp(fns{ii},'main')
                    obj.h.fig.(fns{ii}).Position = ...
                        obj.Settings.(['WinPos_' fns{ii}]);
                else
                    obj.h.fig.(fns{ii}).Position = [...
                        obj.Settings.(['WinPos_' fns{ii}])(1,1:2) ...
                        obj.h.fig.(fns{ii}).Position(3:4)];
                end
                %movegui(obj.h.fig.(fns{ii}),'onscreen')
            end
        end

        % Close the app
        function close(obj,~,~)
            %obj.saveWindowPositions
            obj.VideoPreview.Preview = false;
            pause(.1)
            structfun(@delete,obj.h.fig)
        end
        
        % Update the plots
        function update_plots(obj)
            
            if ~any(obj.StackStim(:)) || any(isnan(obj.Point))
                obj.h.plot.temporal.XData = NaN;
                obj.h.plot.temporal.YData = NaN;
                cla(obj.h.axes.spatial)
                return
            end
            
            % plot temporal response
            y = squeeze(obj.Sequence(obj.Point(2),obj.Point(1),:));
            x = obj.DAQvec.time(obj.DAQvec.cam)';
            obj.h.plot.temporal.XData = x;
            obj.h.plot.temporal.YData = y;
            %y = y(2:end);
            xlim(obj.h.axes.temporal,x([1 end]))
            ylim(obj.h.axes.temporal,[min(y)-(max(y)-min(y))*.15 max(y)])
            if ~any(obj.Line.x)
                obj.h.plot.spatial.XData = NaN;
                obj.h.plot.spatial.YData = NaN;
                return
            end
            
            % spatial response ...
            tmp = obj.DAQvec.time(obj.DAQvec.cam)>0;
            [xi,yi,y] = improfile(...
                mean(obj.Sequence(:,:,tmp),3),obj.Line.x,obj.Line.y,'bilinear');
            
            n = obj.nTrials * length(obj.DAQvec.time(obj.DAQvec.cam)>0);
            [~,~,var] = improfile(...
                mean(obj.SequenceVar(:,:,tmp),3),obj.Line.x,obj.Line.y,'bilinear');
            sem = sqrt(var)./sqrt(n);
            
            x = sqrt((xi-obj.Point(1)).^2+(yi-obj.Point(2)).^2);
            tmp = 1:floor(length(x)/2);
            x(tmp) = -x(tmp);
            cla(obj.h.axes.spatial)
            hold(obj.h.axes.spatial,'on')

            % ... plot
            tmp = ~isnan(y);
            fill([x(tmp); flipud(x(tmp))],...
                [y(tmp)+sem(tmp); flipud(y(tmp)-sem(tmp))],ones(1,3)*.9,...
                'parent',obj.h.axes.spatial,'linestyle','none')
            
%             % ... fit ...
%             p0  = [y(x==0) 0 x(end)/2];
%             tmp	= optimset('display','off');
%             fit = fminsearch(@fitfun,p0,tmp);
%             tmp = linspace(min(x),max(x),1000);
%             plot(obj.h.axes.spatial,tmp,gauss(tmp,fit), ...
%                 'color',        ones(1,3)*0.5, ...
%                 'linewidth',    6);
            plot(obj.h.axes.spatial,x,y,'k','linewidth',2)
            plot(obj.h.axes.spatial,x,zeros(size(x)),':k')
            xlim(obj.h.axes.spatial,x([1 end]))

            function [sse, fit] = fitfun(params)
                fit	= gauss(x,params);
                sse = sum((fit-y) .^ 2);
            end
            
            function y = gauss(x,p)
                y = p(1) * exp(-(x-p(2)).^2/(2*p(3)^2));
            end            
        end
        
        % Generate Test Data
        function test_data(obj,~,~)
                        
            obj.clearData
            obj.preallocateStack

            imSize      = fliplr(obj.ROISize);
            if isempty(imSize)
                imSize = [200 200];
            end
            val_mean    = 2^11;
            n_frames    = nnz(obj.DAQvec.cam);
            n_trials    = 10;
            amp_noise   = 50;

            sigma   = 20; 
            s       = sigma / imSize(1); 
            X0      = ((1:imSize(2))/ imSize(1))-.5;
            Y0      = ((1:imSize(1))/ imSize(1))-.5;  
            [Xm,Ym] = meshgrid(X0, Y0); 
            gauss   = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );
            
            sigma   = 40; 
            s       = sigma / imSize(1)*2; 
            X0      = ((1:imSize(1)*2)/ imSize(1)*2)-.5;
            Y0      = ((1:imSize(2)*2)/ imSize(2)*2)-.5;  
            [Xm,Ym] = meshgrid(X0, Y0); 
            gauss2  = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );
            gauss2  = gauss2(1:imSize(1),(1:imSize(2))+round(imSize(2)/5))./4;

            %data_nostim = uint16(val_mean+randn(imSize(1),imSize(2),n_frames,n_trials)*amp_noise);
            tmp = ceil(gcd(imSize(1),imSize(2))/2);
            tmp = checkerboard(tmp,1,1)>0.5;
            tmp = int32(tmp * 20);

            noise_stim  = int32(val_mean+randn(imSize(1),imSize(2),n_frames,n_trials)*amp_noise);
            noise_stim  = noise_stim + repmat(tmp,1,1,n_frames,n_trials);
            
            data_stim = repmat((gauss-gauss2)./3,1,1,n_frames);
            lambda    = 3;
            mu        = 3;
            tmp       = obj.DAQvec.time(obj.DAQvec.cam);
            x         = tmp(tmp>0);
            amp_stim  = (lambda./(2*pi*x.^3)).^.5 .* exp((-lambda*(x-mu).^2)./(2*mu^2*x));
            amp_stim  = -[zeros(size(tmp(tmp<=0))) amp_stim] * 50;
            for ii = 1:size(data_stim,3)
                data_stim(:,:,ii) = data_stim(:,:,ii) * amp_stim(ii);
            end
            data_stim = int32(data_stim * 3);
            
            data_stim = repmat(data_stim,1,1,1,n_trials);
            data_stim = uint16(data_stim + noise_stim);
            clear noise_stim
            
            tmp = size(data_stim)+[0 0 0 1];
            %obj.StackBase   = ones(tmp,'uint16')*intmax('uint16');
            obj.StackStim   = ones(tmp,'uint16')*intmax('uint16');
            
            %obj.StackBase(:,:,:,1:size(data_nostim,4))  = data_nostim;
            obj.StackStim(:,:,:,1:size(data_stim,4))    = data_stim;
            
            obj.processStack
            
        end
        
        % Preallocation of image stack
        function preallocateStack(obj)
            % Define stack dimensions (Width * Height * nFrames * nTrials)
            dims = [fliplr(obj.ROISize) nnz(obj.DAQvec.cam) 10];
            
            % Use intmax('uint16') for preallocation
            % (NaN is not available with the uint16 class)
            %obj.StackBase = ones(dims,'uint16')*intmax('uint16');
            obj.StackStim = ones(dims,'uint16')*intmax('uint16');
        end
        
        % Process image stack (averaging, spatial filtering)
        function processStack(obj)
            if ~isfield(obj.h.fig,'red')
                obj.redGUI
            end
            sigmaSpatial   = str2double(obj.h.edit.redSigmaSpatial.String);
            sigmaTemporal  = str2double(obj.h.edit.redSigmaTemporal.String);
            ptile   = str2double(obj.h.edit.redRange.String)/100;
            
            isdata  = squeeze(obj.StackStim(1,1,1,:)) ~= intmax('uint16');
            idxbase	= obj.DAQvec.time(obj.DAQvec.cam)<0;
            idxstim = obj.DAQvec.time(obj.DAQvec.cam)>0;
            
            % averaging baseline across, both, time and trials
            base	= mean(reshape(obj.StackStim(:,:,idxbase,isdata), ...
                size(obj.StackStim,1), size(obj.StackStim,2), []),3);
            varbase	= var(double(reshape(obj.StackStim(:,:,idxbase,isdata), ...
                size(obj.StackStim,1), size(obj.StackStim,2), [])),[],3);
            
            % average response
            obj.Sequence = ...
                mean(bsxfun(@minus,double(obj.StackStim(:,:,:,isdata)), ...
                base),4);
            
            % variance of average response
            tmp = var(double(obj.StackStim(:,:,:,isdata)),[],4);
            obj.SequenceVar = bsxfun(@plus,tmp,varbase);
            
            
            stim    = mean(reshape(obj.StackStim(:,:,idxstim,isdata), ...
                size(obj.StackStim,1), size(obj.StackStim,2), []),3);
            
            
%             keyboard
%             tmp = squeeze(mean(obj.StackStim(:,:,:,isdata),3));
%             a   = quantile(tmp,[0.25 0.5 0.75],3,'R-5');
%             iqr = a(:,:,3)-a(:,:,1);


            % spatial filtering
            if sigmaSpatial > 0;
                obj.Sequence    = imgaussfilt(obj.Sequence,sigmaSpatial);
                obj.SequenceVar = imgaussfilt(obj.SequenceVar,sigmaSpatial);
            end

            
            % temporal filtering
            if sigmaTemporal > 0;
                sigma = sigmaTemporal * obj.RateCam / 1000;
                sz    = floor(size(obj.Sequence,3)/3);
                x     = (0:sz-1)-floor(sz/2);
                gf    = exp(-x.^2/(2*sigma^2));         % gaussian
                gf    = gf/sum (gf);                	% normalize to 1
                obj.Sequence = FiltFiltM(gf,1,obj.Sequence,3);
            end
            
            % average across time
            obj.ImageRedDiff = mean(obj.Sequence(:,:,idxstim,:),3);
            obj.ImageRedBase = base;
            obj.ImageRedStim = mean(stim,3);
            %obj.ImageRedDiff = min(obj.Sequence(:,:,idxstim,:),[],3);
            %obj.ImageRedDiff = obj.ImageRedDiff.*(obj.ImageRedDiff<=0);
            
            % process movie
            cmap = flipud(brewermap(2^8,'PuOr'));
            tmp  = sort(abs(obj.Sequence(:)));
            scal = max([1 tmp(ceil(length(tmp)*ptile))]);
          	tmp  = obj.Sequence ./ scal;
            tmp  = ceil(tmp .* 2^7 + 2^7);
            tmp(tmp<1)	 = 1;
            tmp(tmp>2^8) = 2^8;
            tmp  = imresize(tmp,obj.Scale,'nearest');
            mov(size(obj.Sequence,3)) = struct('cdata',[],'colormap',[]);
            for ii = 1:size(obj.Sequence,3)
                mov(ii) = im2frame(tmp(:,:,ii),cmap);
            end
            obj.Movie = mov;
            
            % scale and display as image
            obj.redView(obj.h.popup.redView);
            obj.update_plots
            
            % Focus the red window
            figure(obj.h.fig.red)
        end
        
        % Load icon for toolbar
        function img = icon(obj,filename)
            validateattributes(filename,{'char'},{'vector'})
            iconpath = fullfile(obj.DirBase,'icons');
            [img,map,alpha]	= imread(fullfile(iconpath,filename));
            if ~isempty(map)
                img = ind2rgb(img,map);
            else
                img = double(img);
                img = img./max(img(:));
            end
            if ~isempty(alpha)
                alpha = ~repmat(alpha>(max(alpha(:))/2),1,1,3);
                img(alpha) = NaN;
            end
        end
        
        %% Dependent Properties (GET)
        function binning = get.Binning(obj)
            % The QImaging QiCam can average neighboring pixels into bins. This
            % yields an increase in both RateCam and SNR at the expense of
            % image resolution. The binning factor reflects the amount of
            % binning (1: no binning, 4: 4x4 binning)
            
            % Binning is only defined given a valid videoinput
            if ~isa(obj.VideoInputRed,'videoinput')
                binning = NaN;
                return
            end
            
            % Currently, this function only works with the QiCam
            if ~regexpi(imaqhwinfo(obj.VideoInputRed,'DeviceName'),'^QICam')
                binning = 1;
                return
            end
            
            % Current video mode / resolution
            current = obj.VideoInputRed.VideoFormat;
            current = textscan(current,'%s%n%n','Delimiter',{'_','x'});
            
            % Highest supported resolution
            tmp   	= imaqhwinfo('qimaging','DeviceInfo');
            tmp   	= tmp.SupportedFormats;
            tmp     = regexp(tmp,['(?<=^' current{1}{:} '_)\d*'],'match');
            highest = max(str2double([tmp{:}]));
            
            % Binning factor
            binning	= highest/current{2};
        end
        
        function out = get.Line(obj)
            if ~any(obj.LineCoords)
                out.x = [NaN NaN];
                out.y = [NaN NaN];
            else
                out.x = obj.LineCoords(1)*[1 -1]+obj.Point(1);
                out.y = obj.LineCoords(2)*[1 -1]+obj.Point(2);
            end
        end
        
        function out = get.Point(obj)
            out = obj.PointCoords;
        end
        
        function out = get.ROISize(obj)
            if isa(obj.VideoInputRed,'videoinput')
                tmp	= obj.VideoInputRed.ROIPosition;
                out = tmp(3:4);
            else
                out = [];
            end
        end
        
        function fileOpen(obj,~,~)
%             %% temp
%             tmp = ['intrinsic_' datestr(now,'yymmdd_HHMM') '.mat'];
%             [fn,pn,~] = uiputfile({'intrinsic_*.mat','Intrinsic Data'},'Save File ...',tmp);
%             if fn==0
%                 return
%             end
%             fid = matfile(fullfile(pn,fn),'Writable',true);
%             
%             isdata = squeeze(obj.StackStim(1,1,1,:)) ~= intmax('uint16');
%             fid.StackStim  = obj.StackStim(:,:,:,isdata);
%             fid.ImageGreen = obj.ImageGreen;
%             %%
% % %             
%             [fn,pn,~] = uigetfile({'intrinsic_*.mat','Intrinsic Data'},'Load File ...');
%             if fn==0
%                 return
%             end
%             fn = fullfile(pn,fn);
%             obj.clearData
%             
%             obj.StackStim  = load(fn,'StackStim');
%             
%             obj.ImageGreen = load(fn,'ImageGreen');
%             obj.greenGUI
%             obj.h.image.green.CData = obj.ImageGreen;
            %keyboard
%             tmp = matfile(fullfile(pn,fn));
        end
        
        
        
        function varargout = generateStimulus(obj,p,fs)

            if ~exist('p','var')
                if ~ismember(who(obj.Settings),'Stimulus');
                    obj.settingsStimulus
                end
                p = obj.Settings.Stimulus;
            end
            if ~exist('fs','var')
                fs = 10000;
            end
            
            switch p.type
                case 'Sine'
                    
                    d   = round(p.d*p.freq)/p.freq;     	% round periods
                    t   = (1:d*fs)/fs;                      % time axis
                    out = (sin(2*pi*p.freq*t-.5*pi)/2+.5);  % generate sine
                
                otherwise
                    
                    % generate square wave
                    per	= [ones(1,ceil(1/p.freq*fs*p.dc/100)) ...
                           zeros(1,floor((1/p.freq*fs)*(1-p.dc/100)))];
                    out	= repmat(per,1,round(p.d*p.freq));
                    
                    % add ramp by means of convolution
                    if p.ramp > 0
                        ramp = ones(1,ceil(1/p.freq*fs*p.ramp/100*p.dc/100));
                        out  = conv(out,ramp/100)/length(ramp/100);
                    end
            end
            
            out = out(1:find(out,1,'last')); 	% remove trailing zeros
            out = out * p.amp;                  % set amplitude
            out = [zeros(1,round(p.pre*fs)) ... % add pre- and post-stim
                out zeros(1,round(p.post*fs))];
            
            tax = (0:length(out)-1)/fs-p.pre;   % time axis
            
            inter_cam = round(obj.RateDAQ/obj.RateCam);
            phase_cam = 0;
            phase_cam = round(mod(phase_cam,360)/360*inter_cam);
            ttl_cam	= false(size(out));
            ttl_cam(1+phase_cam:inter_cam:end) = true;
            
            if nargout == 0
                obj.DAQvec.stim = out;
                obj.DAQvec.time = tax;
                obj.DAQvec.cam  = ttl_cam;
                if isfield(obj.h,'axes')
                    obj.h.plot.stimulus.XData = tax;
                    obj.h.plot.stimulus.YData = out;
                    xlim(obj.h.axes.stimulus,tax([1 end]))
                    ylim(obj.h.axes.stimulus,[0 max(out)*10])
                    obj.clearData
                    obj.update_plots
                end
            else
            	varargout{1} = out;
                varargout{2} = tax;
                varargout{3} = ttl_cam;
            end
        end

        function clearData(obj,~,~)
            obj.PointCoords	= nan(1,2);
            obj.LineCoords  = nan(1,2);
            if isfield(obj.h.fig,'red')
                delete(obj.h.fig.red)
                obj.h.fig = rmfield(obj.h.fig,'red');
            end
%             if isfield(obj.h.fig,'green')
%                 delete(obj.h.fig.green)
%                 obj.h.fig = rmfield(obj.h.fig,'green');
%             end
            %obj.StackBase     = [];
            obj.StackStim     = [];
            obj.Sequence      = [];
           % obj.h.image.green = [];
            obj.h.image.red   = [];
            obj.ImageGreen    = [];
        end

        function out = get.Toolbox(~)
            v       = ver;
            check1  = { ...                      	  % necessary toolboxes
                'Data Acquisition Toolbox', ...
                'Image Acquisition Toolbox', ...
                'Image Processing Toolbox'};
            check2 = { ...
                'data_acq_toolbox', ...
                'image_acquisition_toolbox', ...
                'Image_Toolbox'};
            fns = matlab.lang.makeValidName(check1);  % generate fieldnames
            fns = strrep(fns,'Toolbox','');
            
            installed = cellfun(@(x) any(strcmp({v.Name},x)),check1);
            licensed  = cellfun(@(x) license('test',x),check2);
            
            for ii = 1:length(fns)
                out.(fns{ii}).name      = check1{ii};
                out.(fns{ii}).installed = installed(ii);
                out.(fns{ii}).licensed  = licensed(ii);
                out.(fns{ii}).available = installed(ii) & licensed(ii);
            end
        end
        
        %% Dependent Properties (SET)
        function set.Point(obj,value)
            % Process and validate input
            if isempty(value)
                value = nan(1,2);
            end
            validateattributes(value,{'numeric'},{'2d',...
                'numel',2,'positive','row'})
            if any(value>obj.ROISize)
                error('Point coordinates must be within ROI')
            end
            obj.PointCoords	= value;

            % Update Position of Points (red and green images)
            if isfield(obj.h,'point')
                for fn = fieldnames(obj.h.point)'
                    if ~ishandle(obj.h.point.(fn{:}))
                        continue
                    end
                    tmp = strcmp(fn{:},'green') * (obj.Binning-1) + 1;
                    set(obj.h.point.(fn{:}), ...
                        'XData',    value(1) * tmp, ...
                        'YData',    value(2) * tmp);
                end
            end
            
            % Update Position of Line (red image)
            if isfield(obj.h,'line')
                if ishandle(obj.h.line)
                    set(obj.h.line, ...
                        'XData',    obj.Line.x, ...
                        'YData',    obj.Line.y);
                end
            end
            
            % Update Position of Point (live preview)
            if isa(obj.VideoPreview,'video_preview')
                tmp = ~isempty(regexpi(obj.VideoPreview.Figure.Name,...
                    'green','once')) * (obj.Binning-1) + 1;
                obj.VideoPreview.Point = obj.Point * tmp;
            end
            
            % Update Images
            obj.update_plots
        end
        
        function set.Line(obj,value)
            obj.LineCoords = value-obj.Point;
            if isfield(obj.h,'line')
                if ishandle(obj.h.line)
                    set(obj.h.line, ...
                        'XData',    obj.Line.x, ...
                        'YData',    obj.Line.y);
                end
            end
            obj.update_plots
        end
        
        
        
    end
    
end