classdef (Sealed) intrinsic < handle

    properties (GetAccess = {?subsystemData}, Constant)
        DirBase	= fileparts(fileparts(mfilename('fullpath')));
    end

    properties %(Access = private)
        Flags

        h               = [] 	% handles

%         DirSave
%         DirLoad         = [];
%         DirData

        VideoPreview

        PointCoords     = nan(1,2)
        LineCoords      = nan(1,2)

        Stack           % raw data
        SequenceRaw     % relative response (averaged across trials, raw)
        SequenceFilt    % relative response (averaged across trials, filtered)
        Time            % time vector
        IdxStimROI

        ImageRedDiff    % relative response (averaged across trials & time)
        ImageRedBase    %
        ImageRedStim    %
        ImageRedDFF
        ImageGreen      % snapshot of anatomical details
        TimeStamp       = NaN;

        Toolbox

        % new objects
        Green
        Red

        StimIn

        ResponseTemporal

        PxPerCm
    end
    
    properties (Access = private, SetObservable)
        WinBaseline = [0 0]
        WinControl  = [0 0]
        WinResponse = [0 0]
    end

    properties (SetAccess = immutable)
        Camera
        DAQ
        Scale
        Stimulus
        Data
    end
    
    properties (SetAccess = immutable, GetAccess = {?subsystemData})
        Settings
    end
    
    properties (SetAccess = immutable, GetAccess = private)
        ListenerStimulus;
        ListenerCamera;
        ListenerDAQ;
        ListenerDataRun;
        ListenerDataUnsaved;
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

            % TODO: Single Instance
                        
            % Start a new diary file
            diary off
            tmp = fullfile(obj.DirBase,'diary.txt');
            if exist(tmp,'file')
                delete(tmp);
            end
            diary(tmp)
            
            % intrinsic requires MATLAB 2018b or newer
            if verLessThan('matlab','9.5')
                errordlg(['This software requires MATLAB version ' ...
                    'R2018b or newer.'],'Sorry ...')
                delete(obj)
                return
            end

            % For development purposes only ...
            if ~update.validateVersionString(obj.version)
                error('Invalid version string: "%s".', obj.version)
            end

            % Clear command window, close all figures & say hi
            clc
            close all
            fprintf('<strong>Intrinsic Imaging, v%s</strong>\n\n',obj.version)
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
                'Writable', true);

            % Initalize subsystems
            obj.Stimulus = subsystemStimulus(obj);
            obj.Camera   = subsystemCamera(obj);
            obj.DAQ      = subsystemDAQ(obj);
            obj.Scale    = subsystemScale(obj);
            obj.Data     = subsystemData(obj);

            % Initialize listeners
            obj.ListenerStimulus = addlistener(obj.Stimulus,...
                'Update',@obj.cbUpdatedStimulusSettings);
            obj.ListenerCamera =   addlistener(obj.Camera,...
                'Update',@obj.cbUpdatedCameraSettings);
            obj.ListenerDAQ =      addlistener(obj.DAQ,...
                'Update',@obj.cbUpdatedDAQSettings);
            obj.ListenerDataRun =  addlistener(obj.Data,...
                'Running','PostSet',@obj.updateEnabled);
            obj.ListenerDataUnsaved =  addlistener(obj.Data,...
                'Unsaved','PostSet',@obj.updateEnabled);

            % LEGACY STUFF BELOW ------------------------------------------

            % Initialize some variables
            obj.h.image.green       = [];
            obj.h.image.red         = [];
            obj.Flags.Running       = false;
            obj.Flags.Saved         = false;
            obj.Flags.Loaded        = false;
            obj.Flags.FakeDat       = false;
            obj.ResponseTemporal.x  = [];
            obj.ResponseTemporal.y  = [];

            %obj.generateStimulus

            % Fire up GUI
            obj.notify('Ready');
            intrinsic.message('Startup complete')
            obj.GUImain             % Create main window

            figure(obj.h.fig.main)
            if ~nargout
                clearvars
            end
        end
    end

    % Methods defined in separate files:
    methods (Access = {?subsystemStimulus})
        plotStimulus(obj,p)
    end

    methods %(Access = private)
        plotCameraTrigger(obj)
        togglePlots(obj,visible)


        GUImain(obj)                    % Create MAIN GUI
        GUIpreview(obj,hbutton,~)     	% Create PREVIEW GUI
        GUIgreen(obj)                	% Create GREEN GUI
        GUIred(obj)                    	% Create RED GUI
        welcome(obj)
        settingsStimulus(obj,~,~)      	% Stimulus Settings
        settingsVideo(obj,~,~)
        settingsGeneral(obj,~,~)
        fileNew(obj,~,~)
        fileSave(obj,~,~)

        greenCapture(obj,~,~)           % Capture reference ("GREEN IMAGE")
        greenContrast(obj,~,~)          % Modify contrast of "GREEN IMAGE"
        
        %varargout = generateStimulus(obj,varargin)
        
        cbUpdatedCameraSettings(obj,src,eventData)
        cbUpdatedDAQSettings(obj,src,eventData)
        cbUpdatedStimulusSettings(obj,src,eventData)
        cbUpdatedTemporalWindow(obj,src,eventData)
        updateEnabled(obj,~,~)
        
        function new = forceWinResponse(obj,new)
            validateattributes(new,{'numeric'},...
                {'size',[1 2],'real','nonnan'})
            if isempty(obj.DAQ.OutputData)
                return
            end

            
            changes = diff([obj.WinResponse;new]);
            tcam = obj.DAQ.OutputData.Trigger.Time(...
                diff([0; obj.DAQ.OutputData.Trigger.Data])>0)';
            camRate = min(diff(tcam));
            tcam = [tcam tcam(end)+camRate];
            
%             [~,idxOld] = arrayfun(@(x) min(abs(tcam-x)),obj.WinResponse)
%             [~,idxNew] = arrayfun(@(x) min(abs(tcam-x)),new)
            
            if any(changes)
                changes = round(changes/camRate)*camRate;
            else
                new = obj.WinResponse;
                return;
            end
            
            if ~diff(changes)   % if the response window was MOVED ...
                if new(1) < 0
                    new = obj.WinResponse - obj.WinResponse(1);
                elseif new(2) > obj.h.axes.temporal.XLim(2)
                    new = obj.h.axes.temporal.XLim(2) - ...
                        fliplr(obj.WinResponse - obj.WinResponse(1));
                end
            else                % if the response window was RESIZED ...
                if new(1) < 0
                    new(1) = 0;
                end
                if new(2) > obj.h.axes.temporal.XLim(2)
                    new(2) = obj.h.axes.temporal.XLim(2);
                end
                if diff(new) < min(diff(tcam))
                    if changes(1)
                        new(1) = new(2) - camRate;
                    else
                        new(2) = new(1) + camRate;
                    end
                end
            end
            
            % snap to camera triggers
            [~,idxNew] = arrayfun(@(x) min(abs(tcam-x)),new);
            new = tcam(idxNew);
        end
    end

    methods
        function set.WinResponse(obj,in)
            obj.WinResponse = obj.forceWinResponse(in);
            obj.WinControl  = [0 -diff(obj.WinResponse)];
        end
        
        update_plots(obj)
    end

    methods %(Access = private)




        %% all things related to the RED image stack

%         function redClick(obj,h,~)
%             hfig    = h.Parent.Parent.Parent;
%             coord   = round(h.Parent.CurrentPoint(1,1:2));
%            	switch get(hfig,'SelectionType')
% 
%                 % define point of interest
%                 case 'normal'
%                     obj.Point = coord;
% 
%                 % define spatial cross/section
%                 case 'alt'
%                     obj.Line  = coord;
% 
%                 % optimize contrast to region of interest
%                 case 'extend'
%                     % get coordinates of ROI
%                     c(1,:) = round(obj.h.axes.red.CurrentPoint(1,1:2));
%                     rbbox; pause(.1)
%                     c(2,:) = round(obj.h.axes.red.CurrentPoint(1,1:2));
% 
%                     % sanitize & sort coordinates
%                     c(c<1) = 1;
%                     c(1,:) = min([c(1,:); obj.ROISize]);
%                     c(2,:) = min([c(2,:); obj.ROISize]);
%                     c      = [sort(c(:,1)) sort(c(:,2))];
% 
%                     % select image data depending on view mode
%                     if regexpi(obj.redMode,'dF/F')
%                         im  = obj.ImageRedDFF;
%                     else
%                         im  = obj.ImageRedDiff;
%                     end
% 
%                     % find intensity maximum within ROI
%                     tmp = im(c(1,2):c(2,2),c(1,1):c(2,1));
%                     tmp = max(abs(tmp(:)));
% 
%                     % update figure
%                     obj.h.axes.red.UserData = ...
%                         sum(abs(im(:))<=tmp) / length(im(:));
%                     redView(obj,obj.h.popup.redView)
%                     figure(obj.h.fig.red)
%                 otherwise
%                     return
%             end
%         end

%         function redView(obj,~,~)
%             modus = obj.redMode;                % get current image mode
%             ptile = obj.h.axes.red.UserData;    % scaling percentile
%             bit   = 8;                          % bit depth of the image
% 
%             if regexpi(modus,'(diff)|(dF/F)')
%                 obj.h.edit.redSigmaSpatial.Enable  = 'on';
%                 obj.h.edit.redSigmaTemporal.Enable = 'on';
%                 obj.h.edit.redRange.Enable         = 'on';
%                 cmap = flipud(brewermap(2^bit,'PuOr'));
% 
%                 if regexpi(modus,'dF/F')
%                     im = obj.ImageRedDFF;
%                 else
%                     im = obj.ImageRedDiff;
%                 end
%                 tmp  = sort(abs(im(:)));
%                 scal = tmp(ceil(length(tmp) * ptile));
%                 im   = floor(im ./ scal .* 2^(bit-1) + 2^(bit-1));
%                 im(im>2^bit) = 2^bit;
%                 im(im<1)     = 1;
%             else
%                 obj.h.edit.redSigmaSpatial.Enable  = 'off';
%                 obj.h.edit.redSigmaTemporal.Enable = 'off';
%                 obj.h.edit.redRange.Enable         = 'off';
%                 cmap = gray(2^bit);
%             end
% 
%             if regexpi(modus,'neg')         % negative deflections
%                 im(im>2^(bit-1)) = 2^(bit-1);
%             elseif regexpi(modus,'pos')     % positive deflections
%                 im(im<2^(bit-1)) = 2^(bit-1);
%             elseif regexpi(modus,'(base)|(stim)')    % baseline
% 
%                 if regexpi(modus,'log')
%                     base = log(obj.ImageRedBase);
%                     stim = log(obj.ImageRedStim);
%                     tmp  = [base(:); stim(:)];
%                     tmp1 = min(tmp);
%                     tmp2 = max(tmp-tmp1);
%                     base = floor((base-tmp1)./tmp2*(2^bit-1))+1;
%                     stim = floor((stim-tmp1)./tmp2*(2^bit-1))+1;
%                 else
%                     base  = obj.ImageRedBase;
%                     stim  = obj.ImageRedStim;
%                     tmp	  = [base(:); stim(:)];
% 
%                     quant = [.01 .99];
%                     tmp   = sort(tmp(:));
%                     tmp   = tmp(round(length(tmp)*quant));
% 
%                     base(base<tmp(1)) = tmp(1);
%                     base(base>tmp(2)) = tmp(2);
%                     stim(stim<tmp(1)) = tmp(1);
%                     stim(stim>tmp(2)) = tmp(2);
% 
%                     base = round((base-tmp(1)) ./ diff(tmp) * (2^bit-1) + 1);
%                     stim = round((stim-tmp(1)) ./ diff(tmp) * (2^bit-1) + 1);
%                 end
% 
%                 if regexpi(modus,'base')
%                     im = base;
%                 elseif regexpi(modus,'stim')
%                     im = stim;
%                 end
%             end
% 
%             obj.processSubStack
%             obj.h.image.red.CData = ind2rgb(im,cmap);
%             obj.update_plots;
%         end
% 
%         function out = get.nTrials(obj)
%             out = length(obj.Stack);
%         end
% 
%         % Return data directory
%         function out = get.DirSave(obj)
% 
%             % Load from settings file
%             out = obj.loadVar('DirSave',[]);
%             if isfolder(out)
%                 return
%             end
% 
%             % Let user pick directory
%             out = uigetdir('/','Select Data Directory');
%             if isfolder(out)
%                 obj.Settings.DirSave = out;
%             end
% 
%         end

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
            if obj.Data.Running
                return
            end
            
            %obj.saveWindowPositions
            obj.VideoPreview.Preview = false;
            pause(.1)
            structfun(@delete,obj.h.fig)
            diary off
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

%         % Generate Test Data
%         function test_data(obj,~,~)
% 
%             %obj.clearData
% 
%             imSize      = obj.Camera.ROI;
%             val_mean    = power(2,obj.Camera.BitDepth-1);
%             n_frames    = obj.DAQ.nTrigger;
%             n_trials    = 2;
%             amp_noise   = 50;
% 
%             sigma   = 150;
%             s       = sigma / imSize(1);
%             X0      = ((1:imSize(2))/ imSize(1))-.5;
%             Y0      = ((1:imSize(1))/ imSize(1))-.5;
%             [Xm,Ym] = meshgrid(X0, Y0);
%             gauss   = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );
% 
%             sigma   = 300;
%             s       = sigma / imSize(1)*2;
%             X0      = ((1:imSize(1)*2)/ imSize(1)*2)-.5;
%             Y0      = ((1:imSize(2)*2)/ imSize(2)*2)-.5;
%             [Xm,Ym] = meshgrid(X0, Y0);
%             gauss2  = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );
%             gauss2  = gauss2(1:imSize(1),(1:imSize(2))+round(imSize(2)/5))./4;
% 
%             %data_nostim = uint16(val_mean+randn(imSize(1),imSize(2),n_frames,n_trials)*amp_noise);
%             tmp = ceil(gcd(imSize(1),imSize(2))/2);
%             tmp = checkerboard(tmp,1,1)>0.5;
%             tmp = int32(tmp * 20);
% 
%             noise_stim  = int32(val_mean+randn(imSize(1),imSize(2),n_frames,n_trials)*amp_noise);
%             noise_stim  = noise_stim + repmat(tmp,1,1,n_frames,n_trials);
% 
%             data_stim = repmat((gauss-gauss2)./3,1,1,n_frames);
%             lambda    = 3;
%             mu        = 3;
%             tmp       = obj.DAQ.OutputData.Trigger.Time([1; find(diff(obj.DAQ.OutputData.Trigger.Data)>0)+1])';
%             %tmp       = obj.DAQ.OutputData.Trigger.Time(obj.DAQ.OutputData.Trigger.Data>0)';
%             x         = tmp(tmp>0);
%             amp_stim  = (lambda./(2*pi*x.^3)).^.5 .* exp((-lambda*(x-mu).^2)./(2*mu^2*x));
%             amp_stim  = -[zeros(size(tmp(tmp<=0))) amp_stim] * 50;
%             for ii = 1:size(data_stim,3)
%                 data_stim(:,:,ii) = data_stim(:,:,ii) * amp_stim(ii);
%             end
%             data_stim = int32(data_stim * 3);
% 
%             data_stim = repmat(data_stim,1,1,1,n_trials);
%             data_stim = uint16(data_stim + noise_stim);
%             clear noise_stim
% 
%             for ii = 1:size(data_stim,4)
%                 obj.Stack{ii} = data_stim(:,:,:,ii);
%             end
% 
%             obj.processStack
%             obj.TimeStamp = now;
%         end

        % Process image stack (averaging, spatial filtering)
        function processStack(obj)
%             % create red GUI if necessary
%             if ~isfield(obj.h.fig,'red')
%                 obj.GUIred
%             end

%             % reduce size of stack to recorded data
%             if size(obj.Stack,2) > 1
%                 %%
%                 tic
%                 stack = mean(cat(4,obj.Stack{:}),4);
%                 tmp = var(double(cat(4,obj.Stack{:})),0,4);
%                 toc
%             else
%                 stack = double(obj.Stack{1});
%             end
% 
%             obj.Time = obj.DAQ.OutputData.Trigger.Time([1; find(diff(obj.DAQ.OutputData.Trigger.Data)>0)+1])';
% 
%             
%             %%
%             myclass = 'double';
%             mymean = cast(obj.Stack{1},myclass);
%             myvar  = zeros(size(mymean),myclass);
%             
%             tic
%             data   = cast(obj.Stack{2},myclass);
%             
%             w = 0;
%             n = 2;
%             mean1  = mymean + (data - mymean) / n;
%             norm   = n - ~w;
%             myvar  = (var0 .* (norm - 1) + (data - mymean) .* (data - mean1)) / norm;
%             mymean = mean1;
%             clear mean1
%             
%             toc
%             %%
%             
%             
%             
%             
            % obtain baseline & stimulus
            base = mean(stack(:,:,obj.Time<0),3);
            stim = mean(stack(:,:,obj.Time>=0 & obj.Time < obj.WinResponse(2)),3);

            % obtain the average response (time res., baseline substracted)
            obj.SequenceRaw  = stack - base;
            obj.ImageRedBase = base;
            obj.ImageRedStim = stim;
% 
%             % apply temporal/spatial smoothing
%             obj.update_redImage
%             obj.processSubStack
%             obj.update_stimDisp
%             obj.redView(obj.h.popup.redView);
%             figure(obj.h.fig.red)
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
% 
%             % Let the user pick a directory to load data from
%             dn_data = uigetdir(obj.DirSave,'Select folder');
%             fn_data = fullfile(dn_data,'data.mat');
%             if isempty(dn_data)
%                 return
%             elseif ~exist(fn_data,'file') || isempty(dir(fullfile(dn_data,'stack*.tiff')))
%                 errordlg('This doesn''t seem to be a valid data directory!',...
%                     'Hold on!','modal')
%                 return
%             else
%                 obj.clearData
%                 if isfield(obj.h.fig,'green')
%                     delete(obj.h.fig.green)
%                     obj.h.fig = rmfield(obj.h.fig,'green');
%                 end
%                 obj.DirLoad = dn_data;
%             end
% 
%             % Load the image stack
%             for ii = 1:100
%                 % define name of TIFF and check if it exists
%                 fn = sprintf('stack%03d.tiff',ii);
%                 if ~exist(fullfile(obj.DirLoad,fn),'file')
%                     break
%                 end
% 
%                 % load TIFF to stack
%                 obj.status(sprintf('Loading "%s" ... ',fn))
%                 fprintf('Loading "%s" ... ',fn)
%                 obj.Stack{ii} = loadtiff(fullfile(obj.DirLoad,fn));
%             end
%             obj.status
% 
%             % Load green image
%             fn = fullfile(obj.DirLoad,'green.png');
%             if exist(fn,'file')
%                 obj.GUIgreen
%                 obj.ImageGreen          = imread(fn);
%             else
%                 warning('Could not find green image')
%             end
% 
%             % Load all remaining vars
%             tmp = load(fn_data);
%             for field = fieldnames(tmp)'
%                 if ~isempty(tmp.(field{:}))
%                     obj.(field{:}) = tmp.(field{:});
%                 end
%             end
%             obj.DirLoad = dn_data;
%             figure(obj.h.fig.green)
%             obj.greenContrast
% 
%             % Process stack
%             obj.status('Processing ...')
%             obj.processStack
%             obj.updateEnabled
%             obj.status
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

        function status(obj,in)
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

    methods (Access = {?subsystemGeneric})
        function out = loadVar(obj,variableName,defaultValue)
            % Load variable from file, return defaults if not found
            out = defaultValue;
            if ~exist(obj.Settings.Properties.Source,'file')
                return
            else
                if ~isempty(who(obj.Settings,variableName))
                    out = obj.Settings.(variableName);
                end
            end
        end
        
        function saveVar(obj,variableName,data)
            % Save variable to file
            obj.Settings.(variableName) = data;
        end
    end

    methods (Static)
        out = version()
        message(varargin)
    end

end
