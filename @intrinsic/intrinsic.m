classdef (Sealed) intrinsic < handle

    properties (GetAccess = {?subsystemData}, Constant)
        DirBase	= fileparts(fileparts(mfilename('fullpath')));
    end

    properties (GetAccess = {?subsystemData}, Dependent)
        DirHome
        DirData
        Username
    end
    
    properties (SetAccess = immutable)
        Camera
        DAQ
        Scale
        Stimulus
        Data
        Red
    end
    
    properties (SetAccess = immutable, GetAccess = {?subsystemData})
        Settings
    end
    
    properties (Dependent, GetAccess = {?subsystemData})
        UserSettings
    end

    properties %(Access = private)
        h = []
        VideoPreview
        Toolbox
        Green
    end
    
    properties (SetAccess = immutable, GetAccess = private)
        ListenerStimulus
        ListenerCamera
        ListenerDAQ
        ListenerDataRun
        ListenerDataUnsaved
        ListenerDFF
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

            % Clear command window, close all figures
            clc
            close all
            
            % Add submodules to path
            addpath(genpath(fullfile(obj.DirBase,'submodules')))

            % Settings are loaded from / saved to disk
            obj.Settings = matfile(fullfile(obj.DirBase,'settings.mat'),...
                'Writable', true);
            
            % Select user
            if ~obj.userSelect
                delete(obj)
                clearvars
                return
            end
            
            % Say hi
            fprintf('<strong>Intrinsic Imaging, v%s</strong>\n\n',obj.version)
            obj.welcome();

            % Warn if necessary toolboxes are unavailable
            for tmp = struct2cell(obj.Toolbox)'
                if ~tmp{1}.available
                    warning([tmp{1}.name ' not available'])
                end
            end

            % Initalize subsystems
            obj.Stimulus = subsystemStimulus(obj);
            obj.Camera   = subsystemCamera(obj);
            obj.DAQ      = subsystemDAQ(obj);
            obj.Scale    = subsystemScale(obj);
            obj.Data     = subsystemData(obj);
            obj.Red      = imageRed(obj);
            
            % Initialize listeners
            obj.ListenerStimulus = addlistener(obj.Stimulus,...
                'Update',@obj.cbUpdatedStimulusSettings);
            obj.ListenerCamera = addlistener(obj.Camera,...
                'Update',@obj.cbUpdatedCameraSettings);
            obj.ListenerDFF = addlistener(obj.Data,...
                'DFF','PostSet',@obj.cbUpdatedDFF);
            obj.ListenerDAQ = addlistener(obj.DAQ,...
                'Update',@obj.cbUpdatedDAQSettings);
            obj.ListenerDataRun = addlistener(obj.Data,...
                'Running','PostSet',@obj.updateEnabled);
            obj.ListenerDataUnsaved = addlistener(obj.Data,...
                'Unsaved','PostSet',@obj.updateEnabled);

            % Fire up GUI
            obj.notify('Ready');
            obj.GUImain()
            intrinsic.message('Startup complete')
            
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
        out = userSelect(obj)
        plotCameraTrigger(obj)
        GUImain(obj)                    % Create MAIN GUI
        GUIpreview(obj,hbutton,~)     	% Create PREVIEW GUI
        welcome(obj)
        settingsStimulus(obj,~,~)      	% Stimulus Settings
        settingsVideo(obj,~,~)
        settingsGeneral(obj,~,~)
        fileNew(obj,~,~)
        greenCapture(obj,~,~)           % Capture reference ("GREEN IMAGE")
        cbUpdatedCameraSettings(obj,src,eventData)
        cbUpdatedDAQSettings(obj,src,eventData)
        cbUpdatedStimulusSettings(obj,src,eventData)
        cbUpdatedTemporalWindow(obj,src,eventData)
        cbUpdatedDFF(obj,src,eventData)
        updateEnabled(obj,~,~)
        generateTestData(obj,~,~)
    end

    methods %(Access = private)
        
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
            delete(obj.Red)
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


        function out = get.DirHome(~)
            if ispc
                out = getenv('USERPROFILE');
            else
                out = char(java.lang.System.getProperty('user.home'));
            end
        end
        
        function out = get.DirData(obj)
            out = obj.loadVar('DirData',...
                fullfile(obj.DirHome,'Documents','IntrinsicData'));
        end
        
        function out = get.Username(obj)
            out = obj.loadVar('Username','Unknown');
        end
        
        function out = get.UserSettings(obj)
            % returns a matfile object for storing user settings. The
            % filename is constructed from the sanitized username and a
            % checksum (to guarantee unique filenames)
            san = regexprep(obj.Settings.Username,'[^-\wÀ-ž]','');
            crc = CRC16(obj.Settings.Username);
            fn  = sprintf('settings_%s_%s.mat',san,crc);
            out = matfile(fullfile(obj.DirBase,fn),'Writable', true);
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
        function out = loadVar(obj,variableName,defaultValue,useGeneral)
            % Load variable from file, return defaults if not found.
            % UserSettings have precedence over general settings, except if
            % USEGENERAL is true.
            out = defaultValue;
            if ~exist(obj.Settings.Properties.Source,'file')
                return
            else
                if ~exist('useGeneral','var')
                    useGeneral = false;
                end
                if ~isempty(who(obj.UserSettings,variableName)) && ~useGeneral
                    out = obj.UserSettings.(variableName);
                elseif ~isempty(who(obj.Settings,variableName))
                    out = obj.Settings.(variableName);
                end
            end
        end
        
        function saveVar(obj,variableName,data)
            % Save variable to file. Values are written to, both, a general
            % and a user-specific settings file.
            obj.Settings.(variableName) = data;
            obj.UserSettings.(variableName) = data;
        end
    end

    methods (Static)
        out = version()
        message(varargin)
    end

end
