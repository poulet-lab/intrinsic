classdef scalebar < handle
    
    properties
        Scale(1,1) double {mustBeNumeric, mustBeFinite, mustBeReal}
    end

    properties (SetAccess = immutable)
        Parent
    end

    properties (Dependent)
        Visible
        FaceColor
        BackgroundColor
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
        end

        function set.Scale(obj,value)
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
            
            padding  = round(2 / zoom);
            margin   = round(12 / zoom);
            wBarPx   = round(5 / zoom);
            MinBarPx = round(80 / zoom);
            hBack    = round(18 / zoom);
            
            pxPerUnit = obj.Scale ./ power(10,-2-obj.SIexp);
            idxUnit   = find(pxPerUnit<=MinBarPx,1,'last');
            strUnit   = obj.SInames{idxUnit};
            
            % define length of bar (SI and px)
            tmp       = reshape([1 2 5]'.*10.^(0:10),1,[]);
            lBarSI    = tmp(find(pxPerUnit(idxUnit).*tmp<=MinBarPx,1,'last'));
            lBarPx    = lBarSI * pxPerUnit(idxUnit);

            set(obj.Bar,'Position',[ ...
                obj.Parent.XLim(2)-lBarPx-margin ...
                    obj.Parent.YLim(2)-wBarPx-margin lBarPx wBarPx]);
            set(obj.Background, ...
                'Position',     obj.Bar.Position+[-padding -hBack+padding 2*padding hBack]);
            set(obj.Label, ...
                'Position',     [obj.Bar.Position(1)+obj.Bar.Position(3)/2 ...
                obj.Bar.Position(2)-0 0], ...
                'Interpreter',  'tex', ...
                'String',       sprintf('%d %s',lBarSI,strUnit));
        end
        
        function validateColor(~,in)
            valid = false;
            if isnumeric(in)
                valid = isequal(size(in),[1 3]) && ...
                    all(in>=0 & in<=1 & isreal(in) & isfinite(in));
            elseif ischar(in)
                valid = ismember(in,{'y','m','c','r','g','b','w','k',...
                    'yellow','magenta','cyan','red','green','blue',...
                    'white','black','none'});
            end
            if ~valid
                error('"%s" is not a valid ColorSpec.',in)
            end
        end
    end
end