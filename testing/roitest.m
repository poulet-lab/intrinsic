function roitest()

    clear
    clf
    hax = axes;

    disableDefaultInteractivity(hax)
    
    roiline = images.roi.Line(hax, ...
        'Position',     [[1/3 .5]; [2/3 .5]], ...
        'Color',        'k', ...
        'DrawingArea', 'auto', ...
        'Deletable',    false);
    roiline.addlistener('MovingROI',@update);
    p = patch(hax,NaN,NaN,'w', ...
        'FaceAlpha',    0, ...
        'EdgeAlpha',	1, ...
        'LineWidth',    1 , ...
        'LineStyle',    '--', ...
        'Marker',       'none', ...
        'SelectionHighlight',   'off');
    axis xy
    axis equal
    xlim([0 1])
    ylim([0 1])
    update()


    function update(~,~)
        % calculate coordinates of whiskers
        r = 0.05;                       % radius
        
        x_in  = roiline.Position(:,1);   % x coordinates
        y_in  = roiline.Position(:,2);   % y coordinates

        % calculate angles:
        dxy   = diff(roiline.Position,1);
        m     = atan2(dxy(2),dxy(1)) + deg2rad(-90:5:90);
        
        x_rel = r.*cos(m);
        y_rel = r.*sin(m);
        
        x_out = [x_in(1)-x_rel x_in(2)+x_rel];
        y_out = [y_in(1)-y_rel y_in(2)+y_rel];

        p.XData = x_out;
        p.YData = y_out;
    end
end