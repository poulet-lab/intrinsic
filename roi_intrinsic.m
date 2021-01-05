classdef roi_intrinsic < handle

    properties (SetAccess = private)
        Center          % point region-of-interest: center 
        Extent          % point region-of-interest: extent
        Outline         % patch: outline
        Line            % line
    end
    
    properties
        Radius
    end
    
    properties (Dependent, SetAccess = private)
        coordsCenter
        coordsLine
    end
    
    properties (Access = private)
        x_rel
        y_rel
        pt1_rel
    end
    
    events
        Updated
    end
    
    methods
        function obj = roi_intrinsic(hax)
            % create objects
            XYLim = [hax.XLim; hax.YLim];
            obj.Center = images.roi.Point(hax, ...
                'Position',	XYLim(:,1)' + .5*diff(XYLim,[],2)',...
                'Color',  	'r', ...
                'Deletable', false);
            obj.Extent = images.roi.Point(hax, ...
                'Position',	XYLim(:,1)' + [1/3 .5] .* diff(XYLim,[],2)',...
                'Color', 	'c', ...
                'Deletable', false);
            obj.Line = line(hax,...
                'LineWidth',            2,...
                'Color',                'k',...
                'LineStyle',            '-',...
                'SelectionHighlight',	'off',...
                'HitTest',              'off',...
                'PickableParts',        'none',...
                'HandleVisibility',     'off');
            obj.Outline = patch(hax,NaN,NaN,'w',...
                'EdgeColor',            'k',...
                'FaceAlpha',            0,...
                'LineStyle',            '-',...
                'Marker',               'none',...
                'SelectionHighlight',	'off',...
                'HitTest',              'off',...
                'PickableParts',        'none',...
                'HandleVisibility',     'off');

            % create listeners
            obj.Center.addlistener('MovingROI',@obj.translate);
            obj.Extent.addlistener('MovingROI',@obj.reshape);
            
            % set initial radius / calculate initial coordinates
            obj.Radius = .1*min(diff(XYLim,[],2));
        end
        
        function BW = mask(obj,s)
            BW = poly2mask(obj.Outline.XData,obj.Outline.YData,s(1),s(2));
        end
        
        function out = get.coordsLine(obj)
            xy  = [obj.Center.Position; obj.Extent.Position];
            out = [xy(2,:); -1 * (xy(2,:)-xy(1,:)) + xy(1,:)];
        end
        
        function out = get.coordsCenter(obj)
            out = obj.Center.Position;
        end

        function set.Radius(obj,value)
            obj.Radius = value;
            obj.reshape()
        end
                
        function translate(obj,~,~)
            obj.Extent.Position = obj.Center.Position + obj.pt1_rel;
            
            xy = obj.coordsLine;
            obj.Line.XData = xy(:,1);
            obj.Line.YData = xy(:,2);

            obj.Outline.XData = [xy(1,1)-obj.x_rel xy(2,1)+obj.x_rel];
            obj.Outline.YData = [xy(1,2)-obj.y_rel xy(2,2)+obj.y_rel];
            
            notify(obj,'Updated');
        end
        
        function reshape(obj,~,~)
            dxy = diff(obj.coordsLine,1);
            m   = atan2(dxy(2),dxy(1)) + deg2rad(-90:5:90);
            obj.x_rel   = obj.Radius.*cos(m);
            obj.y_rel   = obj.Radius.*sin(m);

            obj.pt1_rel = obj.Extent.Position - obj.Center.Position;
            
            obj.translate()
        end
    end
end
