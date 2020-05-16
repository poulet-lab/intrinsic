classdef intrinsic < handle & matlab.mixin.CustomDisplay

    properties %(Access = private)
        Version         = '2.0-alpha1'
        Flags

        h               = [] 	% handles

        DirBase         = fileparts(fileparts(mfilename('fullpath')));
        DirSave
        DirLoad         = [];

        VideoPreview

        Scale           = 0.5

        % The Q-Cam Needs a little time to deliver a high frame rate.
        % Therefore, we deliver a couple of "Warmup Triggers" at a lower
        % rate before switching to the actual trigger rate. These initial
        % triggers will be skipped during the analysis
        WarmupN         = 5     % Number of "Warmup Triggers" for Camera
        WarmupRate      = 5     % Rate of "Warmup Triggers" (Hz)

        PointCoords     = nan(1,2)
        LineCoords      = nan(1,2)

        Stack           % raw data
        SequenceRaw     % relative response (averaged across trials, raw)
        SequenceFilt    % relative response (averaged across trials, filtered)
        Time            % time vector
        IdxStimROI

        Movie           % relative response (same as obj.Sequence, as movie)
        ImageRedDiff    % relative response (averaged across trials & time)
        ImageRedBase    %
        ImageRedStim    %
        ImageRedDFF
        ImageGreen      % snapshot of anatomical details
        TimeStamp       = NaN;

        Toolbox

        Camera
        DAQ
        DAQvec
        
        Green

        StimIn

        ResponseTemporal

        PxPerCm
    end

    properties (SetAccess = immutable, GetAccess = private)
        Settings
    end
    
    properties (Dependent = true)
        redMode
        nTrials
        Figure
        Point
        Line
    end

    events
        Ready
    end
    
    methods

        % Class Constructor
        function obj = intrinsic(varargin)

            % Clear command window, close all figures & say hi
            clc
            close all
            fprintf('Intrinsic Imaging, v%s\n',obj.Version)
            obj.welcome();

            % Warn if necessary toolboxes are unavailable
            for tmp = struct2cell(obj.Toolbox)'
                if ~tmp{1}.available
                    warning([tmp{1}.name ' not available'])
                end
            end

            % Add submodules to path
            addpath(genpath(fullfile(obj.DirBase,'submodules')))

            % Settings are loaded from / saved to disk
            obj.Settings = matfile(fullfile(obj.DirBase,'settings.mat'),...
                'Writable',true);

            % Initialize some variables
            obj.h.image.green       = [];
            obj.h.image.red         = [];
            obj.Flags.Running       = false;
            obj.Flags.Saved         = false;
            obj.Flags.Loaded        = false;
            obj.Flags.FakeDat       = false;
            obj.ResponseTemporal.x  = [];
            obj.ResponseTemporal.y  = [];

            % Initalize data acquisition & video device, generate stimulus
            obj.DAQ    = daqdevice(obj.Settings);
            obj.Camera = camera(obj.Settings);
            disp('Generating stimulus ...')
            obj.generateStimulus
            
            % Fire up GUI
            obj.notify('Ready');
            fprintf('\nReady to go!\n')
            obj.GUImain             % Create main window
           
            figure(obj.h.fig.main)
            obj.updateEnabled       % Update availability of UI elements
            
        end
    end

    % Methods defined in separate files:
    methods (Access = private)
        GUImain(obj)                    % Create MAIN GUI
        GUIpreview(obj,hbutton,~)     	% Create PREVIEW GUI
        GUIgreen(obj)                	% Create GREEN GUI
        GUIred(obj)                    	% Create RED GUI
        f = welcome(obj)
        settingsStimulus(obj,~,~)      	% Stimulus Settings
        settingsVideo(obj,~,~)
        settingsMagnification(obj,~,~)
        fileSave(obj,~,~)

        greenCapture(obj,~,~)           % Capture reference ("GREEN IMAGE")
        greenContrast(obj,~,~)          % Modify contrast of "GREEN IMAGE"
        redStart(obj,~,~)
        updateEnabled(obj)
    end

    methods %(Access = private)




        %% all things related to the RED image stack

        function redClick(obj,h,~)
            hfig    = h.Parent.Parent.Parent;
            coord   = round(h.Parent.CurrentPoint(1,1:2));
           	switch get(hfig,'SelectionType')

                % define point of interest
                case 'normal'
                    obj.Point = coord;

                % define spatial cross/section
                case 'alt'
                    obj.Line  = coord;

                % optimize contrast to region of interest
                case 'extend'
                    % get coordinates of ROI
                    c(1,:) = round(obj.h.axes.red.CurrentPoint(1,1:2));
                    rbbox; pause(.1)
                    c(2,:) = round(obj.h.axes.red.CurrentPoint(1,1:2));

                    % sanitize & sort coordinates
                    c(c<1) = 1;
                    c(1,:) = min([c(1,:); obj.ROISize]);
                    c(2,:) = min([c(2,:); obj.ROISize]);
                    c      = [sort(c(:,1)) sort(c(:,2))];

                    % select image data depending on view mode
                    if regexpi(obj.redMode,'dF/F')
                        im  = obj.ImageRedDFF;
                    else
                        im  = obj.ImageRedDiff;
                    end

                    % find intensity maximum within ROI
                    tmp = im(c(1,2):c(2,2),c(1,1):c(2,1));
                    tmp = max(abs(tmp(:)));

                    % update figure
                    obj.h.axes.red.UserData = ...
                        sum(abs(im(:))<=tmp) / length(im(:));
                    redView(obj,obj.h.popup.redView)
                    figure(obj.h.fig.red)
                otherwise
                    return
            end
        end

        function redPlayback(obj,~,~)           % Play stack as movie

            %TODO: THIS IS BROKEN
%             % disable UI controls
%             tmpobj = struct2cell(obj.h.fig);
%             tmpobj = findobj([tmpobj{:}],'Enable','on');
%             set(tmpobj,'Enable','off')
%
%             % create temporary axes for movie
%             tmpax = axes(...
%                 'Parent',   obj.h.panel.red, ...
%                 'Position', obj.h.axes.red.Position, ...
%                 'Visible',  'off');
%
%             % play movie
%             obj.processMovie
%
%             movie(tmpax,obj.Movie,1,obj.RateCam/obj.Oversampling,[2 2 0 0])
%
%             % delete temporary axes, enable UI controls
%             delete(tmpax)
%             set(tmpobj,'Enable','on')

        end

        function redView(obj,~,~)
            modus = obj.redMode;                % get current image mode
            ptile = obj.h.axes.red.UserData;    % scaling percentile
            bit   = 8;                          % bit depth of the image

            if regexpi(modus,'(diff)|(dF/F)')
                obj.h.edit.redSigmaSpatial.Enable  = 'on';
                obj.h.edit.redSigmaTemporal.Enable = 'on';
                obj.h.edit.redRange.Enable         = 'on';
                cmap = flipud(brewermap(2^bit,'PuOr'));

                if regexpi(modus,'dF/F')
                    im = obj.ImageRedDFF;
                else
                    im = obj.ImageRedDiff;
                end
                tmp  = sort(abs(im(:)));
                scal = tmp(ceil(length(tmp) * ptile));
                im   = floor(im ./ scal .* 2^(bit-1) + 2^(bit-1));
                im(im>2^bit) = 2^bit;
                im(im<1)     = 1;
            else
                obj.h.edit.redSigmaSpatial.Enable  = 'off';
                obj.h.edit.redSigmaTemporal.Enable = 'off';
                obj.h.edit.redRange.Enable         = 'off';
                cmap = gray(2^bit);
            end

            if regexpi(modus,'neg')         % negative deflections
                im(im>2^(bit-1)) = 2^(bit-1);
            elseif regexpi(modus,'pos')     % positive deflections
                im(im<2^(bit-1)) = 2^(bit-1);
            elseif regexpi(modus,'(base)|(stim)')    % baseline

                if regexpi(modus,'log')
                    base = log(obj.ImageRedBase);
                    stim = log(obj.ImageRedStim);
                    tmp  = [base(:); stim(:)];
                    tmp1 = min(tmp);
                    tmp2 = max(tmp-tmp1);
                    base = floor((base-tmp1)./tmp2*(2^bit-1))+1;
                    stim = floor((stim-tmp1)./tmp2*(2^bit-1))+1;
                else
                    base  = obj.ImageRedBase;
                    stim  = obj.ImageRedStim;
                    tmp	  = [base(:); stim(:)];

                    quant = [.01 .99];
                    tmp   = sort(tmp(:));
                    tmp   = tmp(round(length(tmp)*quant));

                    base(base<tmp(1)) = tmp(1);
                    base(base>tmp(2)) = tmp(2);
                    stim(stim<tmp(1)) = tmp(1);
                    stim(stim>tmp(2)) = tmp(2);

                    base = round((base-tmp(1)) ./ diff(tmp) * (2^bit-1) + 1);
                    stim = round((stim-tmp(1)) ./ diff(tmp) * (2^bit-1) + 1);
                end

                if regexpi(modus,'base')
                    im = base;
                elseif regexpi(modus,'stim')
                    im = stim;
                end
            end

            obj.processSubStack
            obj.h.image.red.CData = ind2rgb(im,cmap);
            obj.update_plots;
        end

        function redStop(obj,~,~)
            obj.Flags.Running = false;
            stop(obj.VideoInputRed)
            obj.DAQsession.stop
            obj.led(false)
        end

        % Load variable from file, return defaults if var/file not found
        function out = loadVar(obj,name,default)
            validateattributes(name,{'char'},{'vector'})
            if isempty(who(obj.Settings,name))
                obj.Settings.(name) = default;
            end
            out = obj.Settings.(name);
        end

        function out = get.nTrials(obj)
            out = length(obj.Stack);
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

            if isempty(obj.Stack) || any(isnan(obj.Point))
                obj.h.plot.temporal.XData = NaN;
                obj.h.plot.temporal.YData = NaN;
                obj.h.plot.temporalROI.XData = NaN;
                obj.h.plot.temporalROI.YData = NaN;
                cla(obj.h.axes.spatial)
                return
            end

            % update X and Y values of temporal plot
            x = obj.ResponseTemporal.x;
            y = obj.ResponseTemporal.y;
            obj.h.plot.temporalROI.XData = x(obj.IdxStimROI);
            obj.h.plot.temporalROI.YData = y(obj.IdxStimROI);
            obj.h.plot.temporal.XData    = x;
            obj.h.plot.temporal.YData    = y;

            % plot indicators for oversampling
        	obj.h.plot.temporalOVS.XData = x;
            obj.h.plot.temporalOVS.YData = y;
            if obj.Oversampling > 1
                tmp = 1/obj.RateCam*(obj.Oversampling-1)/2;
                tmp = repmat(tmp,size(x));
            else
                tmp = [];
            end
            obj.h.plot.temporalOVS.XNegativeDelta = tmp;
            obj.h.plot.temporalOVS.XPositiveDelta = tmp;

            % set Y limits
            tmp = (max(y)-min(y))*.1;
            tmp = [min(y)-tmp max(y)+tmp];
            if ~diff(tmp), tmp = [-1 1]; end
            ylim(obj.h.axes.temporal,tmp)

            % set Y labels
            if regexp(obj.redMode,'dF/F')
                lbl = '\DeltaF/F';
            else
                lbl = '\DeltaF';
            end
            ylabel(obj.h.axes.temporal,lbl)
            ylabel(obj.h.axes.spatial,lbl)

            if ~any(obj.Line.x)
                obj.h.plot.spatial.XData = NaN;
                obj.h.plot.spatial.YData = NaN;
                return
            end

            %% spatial response ...
            if regexp(obj.redMode,'dF/F')
                tmp = obj.ImageRedDFF;
            else
                tmp = obj.ImageRedDiff;
            end
            [xi,yi,y]   = improfile(tmp,obj.Line.x,obj.Line.y,'bilinear');
            x           = sqrt((xi-obj.Point(1)).^2+(yi-obj.Point(2)).^2);
            tmp         = 1:floor(length(x)/2);
            x(tmp)      = -x(tmp);
            x           = x/obj.PxPerCm;
            cla(obj.h.axes.spatial)
            hold(obj.h.axes.spatial,'on')

            % ... plot
            plot(obj.h.axes.spatial,x,y,'k','linewidth',1)
            plot(obj.h.axes.spatial,x,zeros(size(x)),'k')
            xlim(obj.h.axes.spatial,x([1 end]))
        end


        function update_redImage(obj,~,~)
            sigma = struct;
            for id = {'Spatial','Temporal'}
                hedit   = obj.h.edit.(['redSigma' id{:}]);
                value	= str2double(hedit.String);
                if isempty(value) || value<=0
                    value        = 0;
                    hedit.String = value;
                end
                sigma.(id{:}) = value;
            end

            obj.ImageRedDiff     = mean(obj.SequenceRaw(:,:,obj.IdxStimROI),3);
            obj.ImageRedDFF 	 = obj.ImageRedDiff ./ obj.ImageRedBase;
            if sigma.Spatial>0
                obj.ImageRedDiff = imgaussfilt(obj.ImageRedDiff,sigma.Spatial);
                obj.ImageRedDFF  = imgaussfilt(obj.ImageRedDFF,sigma.Spatial);
            end
            obj.processSubStack
        end


        function update_stimDisp(obj)
            if ~isempty(obj.StimIn)
                tmp = mean(obj.StimIn(:,any(obj.StimIn,1)),2);
                tmp = detrend(tmp-min(tmp));
                if max(tmp)-min(tmp) > .5
                    y = mean(obj.StimIn(:,any(obj.StimIn,1)),2);
                end
            end
            if ~exist('y','var')
                y = obj.DAQvec.stim;
            end
            tmp = obj.h.plot.grid.XData([1 end-2]);
            idx = obj.DAQvec.time>=tmp(1) & obj.DAQvec.time<=tmp(2);
            obj.h.plot.stimulus.XData = obj.DAQvec.time(idx);
            obj.h.plot.stimulus.YData = y(idx);

            range = round([min(y) max(y)]*10)/10;
            obj.h.axes.stimulus.YLim  = [range(1) range(2)];
            obj.h.axes.stimulus.YTick = range;
        end

        % Generate Test Data
        function test_data(obj,~,~)

            obj.clearData

            imSize      = fliplr(obj.ROISize);
            if isempty(imSize)
                imSize = [200 200];
            end
            val_mean    = 2^(obj.VideoBits-1);
            n_frames    = length(obj.Time);
            n_trials    = 2;
            amp_noise   = 50;

            sigma   = 150;
            s       = sigma / imSize(1);
            X0      = ((1:imSize(2))/ imSize(1))-.5;
            Y0      = ((1:imSize(1))/ imSize(1))-.5;
            [Xm,Ym] = meshgrid(X0, Y0);
            gauss   = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );

            sigma   = 300;
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
            tmp       = obj.Time;
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

            for ii = 1:size(data_stim,4)
                obj.Stack{ii} = data_stim(:,:,:,ii);
            end

            obj.processStack
            obj.TimeStamp = now;
        end

        % Process image stack (averaging, spatial filtering)
        function processStack(obj)
            % create red GUI if necessary
            if ~isfield(obj.h.fig,'red')
                obj.GUIred
            end

            % reduce size of stack to recorded data
            if obj.nTrials > 1
                stack = mean(cat(4,obj.Stack{:}),4);
            else
                stack = double(obj.Stack{1});
            end

            % obtain baseline & stimulus
            base = mean(stack(:,:,obj.Time<0),3);
            stim = mean(stack(:,:,obj.IdxStimROI),3);

            % obtain the average response (time res., baseline substracted)
            obj.SequenceRaw  = stack - base;
            obj.ImageRedBase = base;
            obj.ImageRedStim = stim;

            % apply temporal/spatial smoothing
            obj.update_redImage
            obj.processSubStack
            obj.update_stimDisp
            obj.redView(obj.h.popup.redView);
            figure(obj.h.fig.red)
        end

        function processSubStack(obj,~,~)
            % This function extracts a sub-volume from obj.StackAverage
            % which is centered on the currently selected XY-position.
            % Instead of processing the whole image stack, temporal and
            % spatial filtering will be applied to the sub-volume only.
            % Doing so significantly reduces processing time.

            %% we can take a shortcut if no XY-position is selected
            if any(isnan(obj.Point))
                obj.ResponseTemporal.x = [];
                obj.ResponseTemporal.y = [];
                return
            end

            %% get sigma values from text fields
            sigma = struct;                           	% preallocate
            for id = {'Spatial','Temporal'}
                hUI = obj.h.edit.(['redSigma' id{:}]);  % UI handle
                sigma.(id{:}) = str2double(hUI.String); % set sigma value
            end

            %% obtain sub-volume & center coordinates
            % Perhaps a bit cumbersome, this section ensures correct
            % sub-volumes even for XY-positions close to the border.

            tmp     = ceil(2*sigma.Spatial);
            c1      = obj.Point(2)+(-tmp:tmp); 	% row indices of sub-volume
            c2      = obj.Point(1)+(-tmp:tmp); 	% col indices of sub-volume

            sz      = size(obj.SequenceRaw);
            b1      = ismember(c1,1:sz(1));  	% bool: valid row indices
            b2      = ismember(c2,1:sz(2));   	% bool: valid col indices

            mask    = false(2*tmp+1,2*tmp+1);   % preallocate logical mask
            mask(tmp+1,tmp+1) = true;           % logical: X/Y center
            mask    = mask(b1,b2);              % trim mask to valid values
            [c3,c4] = find(mask);               % indices of X/Y center

            c1      = c1(b1);                 	% keep valid row indices
            c2      = c2(b2);                 	% keep valid col indices

            subVol  = obj.SequenceRaw(c1,c2,:);
            if regexp(obj.redMode,'dF/F')
                subVol = subVol ./ obj.ImageRedBase(c1,c2,:);
            end

            %% spatial filtering
            % 2D Gaussian filtering of the sub-volume's 1st two dimensions
            if sigma.Spatial > 0
                subVol = imgaussfilt(subVol,sigma.Spatial);
            end

            %% temporal filtering
            % Gaussian filtering along the sub-volume's 3rd dimension
            if sigma.Temporal > 0
                s       = sigma.Temporal*obj.RateCam/obj.Oversampling/1000;
                sz      = floor(size(subVol,3)/3);
                x       = (0:sz-1)-floor(sz/2);
                gf      = exp(-x.^2/(2*s^2));      	% the Gaussian kernel
                gf      = gf/sum(gf);              	% normalize Gaussian
                subVol	= FiltFiltM(gf,1,subVol,3);
            end

            %% define X and Y values for temporal plot
            obj.ResponseTemporal.x = obj.Time';
            obj.ResponseTemporal.y = squeeze(subVol(c3,c4,:));
        end

        function processMovie(obj)
            ptile = obj.h.axes.red.UserData;
            cmap  = flipud(brewermap(2^8,'PuOr'));
            tmp   = sort(abs(obj.SequenceFilt(:)));
            scal  = max([1 tmp(ceil(length(tmp)*ptile))]);
          	tmp   = obj.SequenceFilt ./ scal;
            tmp   = ceil(tmp .* 2^7 + 2^7);
            tmp(tmp<1)	 = 1;
            tmp(tmp>2^8) = 2^8;
            tmp  = imresize(tmp,obj.Scale,'nearest');
            mov(size(obj.SequenceFilt,3)) = struct('cdata',[],'colormap',[]);
            for ii = 1:size(obj.SequenceFilt,3)
                mov(ii) = im2frame(tmp(:,:,ii),cmap);
            end
            obj.Movie = mov;
        end

        % Load icon for toolbar
        function img = icon(obj,filename)
            validateattributes(filename,{'char'},{'vector'})

            % read image, convert to double
            iconpath = fullfile(obj.DirBase,'icons');
            [img,~,alpha] = imread(fullfile(iconpath,filename));
            img     = double(img) / 255;
            alpha   = repmat(double(alpha) / 255,[1 1 3]);

            % create background, multiply with alpha
            bg      = repmat(240/255,size(img));
            img     = immultiply(img,alpha);
            bg      = immultiply(bg,1-alpha);

            % merge background and image
            img     = imadd(img,bg);

            % remove completely transparent areas
            img(~alpha) = NaN;
        end

        %% Dependent Properties (GET)
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

        function out = get.redMode(obj)
            tmp = obj.h.popup.redView;
            out = tmp.String{tmp.Value};
        end

        function fileOpen(obj,~,~)

            % Let the user pick a directory to load data from
            dn_data = uigetdir(obj.DirSave,'Select folder');
            fn_data = fullfile(dn_data,'data.mat');
            if isempty(dn_data)
                return
            elseif ~exist(fn_data,'file') || isempty(dir(fullfile(dn_data,'stack*.tiff')))
                errordlg('This doesn''t seem to be a valid data directory!',...
                    'Hold on!','modal')
                return
            else
                obj.clearData
                if isfield(obj.h.fig,'green')
                    delete(obj.h.fig.green)
                    obj.h.fig = rmfield(obj.h.fig,'green');
                end
                obj.DirLoad = dn_data;
            end

            % Load the image stack
            for ii = 1:100
                % define name of TIFF and check if it exists
                fn = sprintf('stack%03d.tiff',ii);
                if ~exist(fullfile(obj.DirLoad,fn),'file')
                    break
                end

                % load TIFF to stack
                obj.message(sprintf('Loading "%s" ... ',fn))
                fprintf('Loading "%s" ... ',fn)
                obj.Stack{ii} = loadtiff(fullfile(obj.DirLoad,fn));
            end
            obj.message

            % Load green image
            fn = fullfile(obj.DirLoad,'green.png');
            if exist(fn,'file')
                obj.GUIgreen
                obj.ImageGreen          = imread(fn);
            else
                warning('Could not find green image')
            end

            % Load all remaining vars
            tmp = load(fn_data);
            for field = fieldnames(tmp)'
                if ~isempty(tmp.(field{:}))
                    obj.(field{:}) = tmp.(field{:});
                end
            end
            obj.DirLoad = dn_data;
            figure(obj.h.fig.green)
            obj.greenContrast

            % Process stack
            obj.message('Processing ...')
            obj.processStack
            obj.updateEnabled
            obj.message
        end

        function varargout = generateStimulus(obj,varargin)

            % parse input arguments
            ip  = inputParser;
            addOptional(ip,'stimParams',struct,@(x) validateattributes(x,...
                {'struct'},{'scalar'}));
            addOptional(ip,'fs',obj.DAQ.Session.Rate,@(x) validateattributes(x,...
                {'numeric'},{'scalar','positive','real'}));
            parse(ip,varargin{:})
            p   = ip.Results.stimParams;    % stimulus parameters
            fs  = ip.Results.fs;            % sampling rate (Hz)
            ds	= obj.Camera.Downsample;    % downsampling factor
            fps = obj.Camera.FrameRate;

            % Load stimulus parameters from disk, if they were not passed
            % (they are only being passed, if the stimulus is generated for
            % viewing purposes, i.e., within the stimulus settings window)
            if isempty(fieldnames(p))
                if ~ismember('Stimulus',who(obj.Settings))
                    obj.settingsStimulus
                end
                p = obj.Settings.Stimulus;
            end

            % Generate times where we send out a ttl to the cam
            rateOvs = fps / ds;
            nPerNeg = ceil(rateOvs*p.pre)-.5;
            nPerPos = ceil(rateOvs*(p.d+p.post))-.5;
            t_ovs   = (-nPerNeg:nPerPos)/rateOvs;

            % Generate times where we send out a ttl to the cam
            nPerNeg = nPerNeg*ds + floor(ds/2-.5) + (obj.WarmupN > 0);
            nPerPos = nPerPos*ds +  ceil(ds/2-.5);
            t_trig  = ((-nPerNeg:nPerPos) -(~mod(ds,2)*.5)) / fps;

            % Prepend remaining sample numbers for warmup
            % (the first warmup trigger has already been added above)
            if obj.WarmupN > 1
                t_warm  = t_trig(1) - (obj.WarmupN-1:-1:1)/obj.WarmupRate;
                t_trig  = [t_warm t_trig];
            end

            % build ttl + time vectors (append + prepend 100ms of silence)
            s_trig      = round(t_trig*fs);
            tax         = (s_trig(1)-.1*fs):(s_trig(end)+.1*fs);
            ttl_cam     = ismember(tax,s_trig);
            tax         = tax/fs;
            ttl_view    = ismember(tax,round(t_ovs*fs)/fs);

            % generate stimulus
            switch p.type
                case 'Sine'
                    d   = round(p.d*p.freq)/p.freq;     	% round periods
                    t   = (1:d*fs)/fs;                      % time axis
                    tmp = (sin(2*pi*p.freq*t-.5*pi)/2+.5);  % generate sine

                otherwise
                    % generate square wave
                    per	= [ones(1,ceil(1/p.freq*fs*p.dc/100)) ...
                           zeros(1,floor((1/p.freq*fs)*(1-p.dc/100)))];
                    tmp	= repmat(per,1,round(p.d*p.freq));

                    % add ramp by means of convolution
                    if p.ramp > 0
                        ramp = ones(1,ceil(1/p.freq*fs*p.ramp/100*p.dc/100));
                        tmp  = conv(tmp,ramp)/length(ramp);
                    end
            end
            tmp = tmp(1:find(tmp,1,'last')); 	% remove trailing zeros
            tmp = tmp * p.amp;                  % set amplitude
            out = zeros(size(tax));
            s0  = find(tax==0);
            out(s0+1:s0+length(tmp)) = tmp;

            if nargout == 0
                obj.DAQvec.stim = out;
                obj.DAQvec.time = tax;
                obj.DAQvec.cam  = ttl_cam;
                obj.Time        = obj.DAQvec.time(ttl_view);
                obj.IdxStimROI  = obj.Time>=0;
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
            obj.Stack           = cell(1,0);
            obj.SequenceRaw     = [];
            obj.SequenceFilt    = [];
            obj.h.image.red     = [];
            obj.StimIn          = [];
            obj.DirLoad         = [];
            obj.update_stimDisp
            obj.update_plots
        end

        %% check availability of needed toolboxes
        function out = get.Toolbox(~)

            % define names/identifiers of toolboxes
            str  = { ...
                'Data Acquisition Toolbox', 'data_acq_toolbox';...
                'Image Acquisition Toolbox','image_acquisition_toolbox';...
                'Image Processing Toolbox', 'Image_Toolbox'};

            % check if toolboxes are available
            v 	= ver;
            installed = cellfun(@(x) any(strcmp({v.Name},x)),str(:,1));
            licensed  = cellfun(@(x) license('test',x),str(:,2));

            % generate fieldnames for output structure
            fns = matlab.lang.makeValidName(str(:,1));
            fns = strrep(fns,'Toolbox','');

            % create output structure
            for ii = 1:length(fns)
                out.(fns{ii}).name      = str{ii,1};
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
            obj.processSubStack
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

        function set.PxPerCm(obj,value)

             obj.PxPerCm = value;

            padding  = round(2 / obj.Scale);
            margin   = round(15 / obj.Scale);
            wBarPx   = round(5 / obj.Scale);
            MinBarPx = round(100 / obj.Scale);
            hBack    = round(18 / obj.Scale);

            SInames  = {'fm','pm','nm',[char(181) 'm'],'mm','cm','m','km'};
            SIexp    = [-15 -12 -9 -6 -3 -2 0 3];

            pxPerUnit = value ./ power(10,-2-SIexp);
            idxUnit   = find(pxPerUnit<=MinBarPx,1,'last');
            strUnit   = SInames{idxUnit};

            % define length of bar (SI and px)
            tmp       = reshape([1 2 5]'.*10.^(0:3),1,[]);
            lBarSI    = tmp(find(pxPerUnit(idxUnit).*tmp<MinBarPx,1,'last'));
            lBarPx    = lBarSI * pxPerUnit(idxUnit);

            ha = obj.h.axes.green;
            hs = obj.h.scalebar.green;
            set(hs.bar, ...
                'Position',     [ha.XLim(2)-lBarPx-margin ...
                    ha.YLim(2)-wBarPx-margin lBarPx wBarPx]);
            set(hs.background, ...
                'Position',     hs.bar.Position+[-padding -hBack+padding 2*padding hBack]);
            set(hs.label, ...
                'Position',     [hs.bar.Position(1)+hs.bar.Position(3)/2 ...
                    hs.bar.Position(2)-0 0], ...
                'Interpreter',  'tex', ...
                'String',       sprintf('%d %s',lBarSI,strUnit));

            obj.update_plots

        end

        function message(obj,in)
            basename = 'Intrinsic Imaging';
            if nargin < 2
                obj.h.fig.main.Name = basename;
                drawnow
            else
                obj.h.fig.main.Name = sprintf('%s - %s',basename,in);
                drawnow
            end
        end
    end

    methods (Access = 'protected')
        function out = getPropertyGroups(obj)
            out = matlab.mixin.util.PropertyGroup(struct);
        end
        function out = getHeader(obj)
            out = sprintf('  %s\n',matlab.mixin.CustomDisplay.getClassNameForHeader(obj));
        end
    end

end
