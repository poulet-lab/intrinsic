classdef scalebar < handle & matlab.mixin.SetGet
    
    properties
        Scale = 1
    end

    properties (SetObservable, AbortSet)
        Padding = 2
        Margin = 12
        FontSize
        BarSize = [120 5]
    end
    
    properties (SetAccess = immutable)
        Parent
    end

    properties (Dependent)
        Visible
        FaceColor
        BackgroundColor
        Position
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        Background
        Bar
        Label
        Listener
    end

    properties (Constant, GetAccess = private)
        SInames = {'fm','pm','nm',[char(181) 'm'],'mm','cm','m','km'};
        SIexp   = [-15 -12 -9 -6 -3 -2 0 3];
    end
    
    methods
        function obj = scalebar(axes,scale)
            obj.Parent = axes;
            obj.FontSize = obj.Parent.FontSize;
            obj.Background = rectangle(obj.Parent, ...
                'LineStyle',            'none', ...
                'FaceColor',            'w', ...
                'HitTest',              'off');
            obj.Bar = rectangle(obj.Parent, ...
                'LineStyle',            'none', ...
                'FaceColor',            'k', ...
                'HitTest',              'off');
            obj.Label = text(obj.Parent,125,75,'test', ...
                'Color',                'k', ...
                'VerticalAlignment',    'bottom', ...
                'HorizontalAlignment',  'center', ...
                'HitTest',              'off');
            obj.Scale = scale;
            obj.Listener = ...
                addlistener(obj.Parent.Parent,'SizeChanged',@obj.update);
            addlistener(obj,{'Padding','Margin','FontSize','BarSize'},...
                'PostSet',@obj.update);
        end

        function set.Scale(obj,value)
            if ~isnan(value)
                validateattributes(value,{'numeric'},{'scalar',...
                    'positive','finite','real'},mfilename,'Scale')
            else
                validateattributes(value,{'numeric'},{'scalar','real'},...
                    mfilename,'Scale')
            end
            obj.Scale = value;
            obj.update()
        end
        
        function set.Visible(obj,value)
            set([obj.Background,obj.Bar,obj.Label],'Visible',value)
        end
        
        function set.FaceColor(obj,value)
            obj.validateColor(value)
            obj.Bar.FaceColor = value;
            obj.Label.Color = value;
        end
        
        function set.BackgroundColor(obj,value)
            obj.validateColor(value)
            obj.Background.FaceColor = value;
        end

        function value = get.Visible(obj)
            value = obj.Bar.Visible;
        end
        
        function value = get.Position(obj)
            value = obj.Background.Position;
        end
        
        function value = get.FaceColor(obj)
            value = obj.Bar.FaceColor;
        end
        
        function value = get.BackgroundColor(obj)
            value = obj.Background.FaceColor;
        end
        
        function delete(obj)
            delete(obj.Bar)
            delete(obj.Background)
            delete(obj.Label)
            delete(obj.Listener)
        end
    end
    
    methods (Access = private)
        
        function update(obj,~,~)
            
            tmp = obj.Parent.Units;
            obj.Parent.Units = 'pixels';
            zoom = min(obj.Parent.Position([3 4])) / ...
                min([diff(obj.Parent.XLim) diff(obj.Parent.YLim)]);
            obj.Parent.Units = tmp;
            
            padding  = obj.Padding / zoom;
            margin   = obj.Margin / zoom;
            hBarPx   = obj.BarSize(2) / zoom;
            MinBarPx = obj.BarSize(1) / zoom;
            
            if ~isnan(obj.Scale)
                pxPerUnit = obj.Scale ./ power(10,-2-obj.SIexp);
                idxUnit   = find(pxPerUnit<=MinBarPx,1,'last');
                strUnit   = obj.SInames{idxUnit};
                tmp       = reshape([1 2 5]'.*10.^(0:10),1,[]);
                lBarSI    = tmp(find(pxPerUnit(idxUnit).*tmp<=MinBarPx,1,'last'));
                lBarPx    = lBarSI * pxPerUnit(idxUnit);
                lString   = sprintf('%d %s',lBarSI,strUnit);
            else
                lBarPx    = MinBarPx;
                lString   = 'NaN';
            end
            
            set(obj.Bar,'Position',[ ...
                obj.Parent.XLim(2)-lBarPx-margin ...
                    obj.Parent.YLim(2)-hBarPx-margin lBarPx hBarPx]);
            set(obj.Label, ...
                'Position',     [obj.Bar.Position(1)+obj.Bar.Position(3)/2 ...
                obj.Bar.Position(2)-0 0], ...
                'Interpreter',  'tex', ...
                'String',       lString, ...
                'FontSize',     obj.FontSize);

            obj.Label.Units = 'pixels';
            hBack = 0.75*obj.Label.Extent(4)/zoom+2*padding;
            obj.Label.Units = 'data';
            
            set(obj.Background, ...
                'Position',     obj.Bar.Position+[-padding -hBack+padding 2*padding hBack]);
        end
        
        function validateColor(~,in)
            valid = false;
            if isnumeric(in)
                valid = isequal(size(in),[1 3]) && ...
                    all(in>=0 & in<=1 & isreal(in) & isfinite(in));
            elseif ischar(in)
                valid = ismember(in,{'ymc','r','g','b','w','k',...
                    'yellow','magenta','cyan','red','green','blue',...
                    'white','black','none'});
            end
            if ~valid
                error('Invalid color value.')
            end
        end
    end
end