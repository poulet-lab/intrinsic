classdef update
    
    properties (SetAccess = immutable)
        BaseDirectory
        LocalVersion
        RemoteVersion
        RemoteZIP
    end
    
    properties (Constant, Access = private)
        RepoOwner = 'poulet-lab';
        RepoName  = 'intrinsic';
        RestBase  = 'https://api.github.com';
        RestOpts  = weboptions(...
            'ContentType',  'json', ...
            'MediaType',    'application/vnd.github.v3+json');
    end
        
    methods
        function obj = update(varargin)
            % TODO: Test for open intrinsic sessions
            
            %% test for internet connection
            if ~obj.testInternet()
                error('Can''t connect to the internet.')
            end

            %% check for version control
            if exist(fullfile(obj.BaseDirectory,'.git'),'dir')
                url = sprintf('%s/repos/%s/%s',...
                    obj.RestBase,obj.RepoOwner,obj.RepoName);
                link = [webread(url,obj.RestOpts).html_url '/releases'];
                error(['You are using intrinsic with GIT version ' ...
                    'control. Use GIT to update your local ' ...
                    'repository.\nAlternatively, manually download ' ...
                    'the newest release of intrinsic from ' ...
                    '<a href="matlab: web(''%s'');">%s</a>.\n'],link,link)
            end
            
            %% get local version
            obj.LocalVersion = intrinsic.version;

            %% get remote details from github
            try
                url = sprintf('%s/repos/%s/%s/releases',...
                    obj.RestBase,obj.RepoOwner,obj.RepoName);
                data = webread(url,obj.RestOpts);
                obj.RemoteZIP = data(1).zipball_url;
                obj.RemoteVersion = ...
                    regexprep(data(1).tag_name,'^v?(.*)$','$1');
            catch
                error('Error getting remote details')
            end
            
            if checkUpdate
                disp('Your are already up to date.')
                return
            end
                
            %% handle directories
            obj.BaseDirectory = fileparts(mfilename('fullpath'));
            dnUpdate = fullfile(obj.BaseDirectory,'update');
            if exist(dnUpdate,'dir'), rmdir(dnUpdate,'s'); end

            %% download & extract remote data
            fprintf('Downloading new version %s ... ', obj.RemoteVersion)
            try
                unzip(obj.RemoteZIP,dnUpdate)
            catch
                fprintf('Failed.\n')
                error('Error downloading version %s', obj.RemoteVersion)
            end
            fprintf('Done.\n')
            
            %% find intrinsic within dnUpdate
            tmp = dir(dnUpdate);
            tmp(startsWith({tmp.name},'.')) = [];
            if numel(tmp)==1
                dnUpdateSub = fullfile(tmp.folder,tmp.name);
            else
                rmdir(dnUpdate,'s')
                error('Error interpreting download - update cancelled')
            end

            %% backup old version
            fprintf('Backing up old version ... ');
            fBackup = dir(obj.BaseDirectory);
            rgx = '^(\.{1,2}(git)?|update|backups)$';
            fBackup(arrayfun(@(x) any(regexp(x.name,rgx)),fBackup)) = [];
            dnBackup = fullfile(obj.BaseDirectory,'backups',sprintf(...
                '%s___%s',datestr(now,'yymmdd_HHMMSS'),obj.LocalVersion));
            mkdir(dnBackup)
            status = false(1,numel(fBackup));
            for ii = 1:numel(fBackup)
                status(ii) = copyfile(...
                    fullfile(fBackup(ii).folder,fBackup(ii).name),...
                    fullfile(dnBackup,fBackup(ii).name));
            end
            if all(status)
                fprintf('Done.\n')
            else
                fprintf('Failed.\n')
                error('Error backing up old version - update cancelled.')
            end

            %% delete old version
            fDelete = fBackup;
            fDelete = fDelete(~strcmp({fDelete.name},'settings.mat'));
            for ii = 1:numel(fDelete)
                tmp = fullfile(fDelete(ii).folder,fDelete(ii).name);
                if fDelete(ii).isdir
                    rmdir(tmp,'s')
                else
                    delete(tmp)
                end
            end
            
            %% move update in place
            fprintf('Moving update in place ... ');
            fUpdate = dir(dnUpdateSub);
            rgx = '^\.{1,2}(gitignore)?$';
            fUpdate(arrayfun(@(x) any(regexp(x.name,rgx)),fUpdate)) = [];
            status = false(1,numel(fUpdate));
            for ii = 1:numel(fUpdate)
                status(ii) = movefile(...
                    fullfile(fUpdate(ii).folder,fUpdate(ii).name),...
                    fullfile(obj.BaseDirectory,fUpdate(ii).name));
            end
            if all(status)
                fprintf('Done.\n')
            else
                fprintf('Failed.\n')
                error('Error moving update in place.')
            end
            
            %% delete remains and finish off
            rmdir(dnUpdate,'s')
            fprintf('Update to version %s was successful.',obj.RemoteVersion)
            
        end
        
        function varargout = checkUpdate(obj)
            
            nargoutchk(0,1)
            
            % check validity of version strings & extract fields
            vCell = struct;
            vMat  = struct;
            for tmp = {'Local','Remote'}
                [valid,vCell.(tmp{:})] = obj.validateVersionString(...
                    obj.([tmp{:} 'Version']));
                if ~valid
                    error('Cannot parse %s version: "%s".',...
                        lower(tmp{:}),obj.([tmp{:} 'Version']))
                end
                vMat.(tmp{:}) = str2double(vCell.(tmp{:})(1:3));
            end
            
            if isequal(vMat.Remote,vMat.Local)
                % TODO: check pre-release string
            else
                % compare major, minor and patch number
                tmp1   = find(vMat.Remote > vMat.Local,1);
                tmp2   = find(vMat.Remote < vMat.Local,1);
                result = ~isempty(tmp1) && (isempty(tmp2) || tmp2>tmp1);
            end
                
            % set return value / show result
            if nargout
                varargout{1} = result;
            else
                fprintf('Local version:  %s\n',obj.LocalVersion)
                fprintf('Remote version: %s\n\n',obj.RemoteVersion)
                if result
                    disp('Update available!')
                else
                    disp('You are up to date.')
                end
            end
        end
    end
    
    methods (Static)
        
        function connected = testInternet()
            try
                java.net.InetAddress.getByName('www.github.com');
                connected = true;
            catch
                connected = false;
            end
        end
        
        function [isvalid,components] = validateVersionString(input)
            % validate arguments
            nargoutchk(0,2)
            validateattributes(input,{'char','string'},...
                {'row'},mfilename,'INPUT')
            if isstring(input)
                input = input.char;
            end

            % get components of version string
            % (c.f., https://semver.org/spec/v2.0.0.html)
            components = regexpi(input, ...
                ['^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)' ...
                '(-((0|[1-9]\d*|\d*[a-z-][\da-z-]*)' ...
                '(\.(0|[1-9]\d*|\d*[a-z-][\da-z-]*))*))?' ...
                '(\+([\da-z-]+(?:\.[\da-z-]+)*))?$'], 'once', 'tokens');

            % check validity
            isvalid = ~isempty(components);

            % remove remaining delimiters
            if isvalid && nargout > 1
                components(4:5) = regexprep(components(4:5),'^(-|\+)','');
            end
        end
    end
end