function roitest2

clf

w = 800;
h = 500;


hfig = figure(...
    'WindowButtonMotionFcn', @pointerMovement);
hax = axes;
i = imagesc(hax,ones(h,w));
hold on

axis tight
axis equal
xlim([0 w])
ylim([0 h])

roi = roi_intrinsic(hax);
roi.Outline.Visible = 'off';
t = timer('TimerFcn',@pointerMovement);

    function pointerMovement(~,~)
        persistent visible
        if isempty(visible)
            visible = false;
        end
        
        pointer = hax.CurrentPoint(2,1:2)';
        limits  = [hax.XLim; hax.YLim];
        inaxes  = all(pointer>=limits(:,1) & pointer<=limits(:,2));
        
        
        
        if xor(inaxes,visible)
            visible = ~visible;
            roi.Outline.Visible = visible;
            roi.Extent.Visible  = visible;
            if visible, t.start, end
        end
    end

end

% function roitest2
% 
% clf
% 
% w = 800;
% h = 500;
% 
% 
% hfig = figure(...
%     'WindowButtonMotionFcn', @pointerMovement);
% hax = axes;
% i = imagesc(hax,ones(h,w));
% hold on
% 
% axis tight
% axis equal
% xlim([0 w])
% ylim([0 h])
% 
% roi = roi_intrinsic(hax);
% roi.Outline.Visible = 'off';
% t = timer('TimerFcn',@pointerMovement);
% 
%     function pointerMovement(~,~)
%         persistent visible
%         if isempty(visible)
%             visible = false;
%         end
%         
%         if xor(~isempty(overobj(obj.Axes)),visible)
%             visible = ~visible;
%             roi.Outline.Visible = visible;
%             roi.Extent.Visible  = visible;
%             if visible, t.start, end
%         end
%     end
% 
% end