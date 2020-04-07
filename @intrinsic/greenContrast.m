function greenContrast(obj,~,~)

% copy values from check-boxes
obj.Settings.greenContrast = obj.h.check.greenContrast.Value;
obj.Settings.greenLog      = obj.h.check.greenLog.Value;

% copy (log) image data to CData
im = obj.ImageGreen(:,:,1);                 % get green image data
if obj.Settings.greenLog
    im = log2(double(im));                  % log2 version of green image
    im(isinf(im)) = 0;                      % sanitize inf values
end
obj.h.image.green.CData = im;               % update green image CData

if obj.Settings.greenContrast               % OPTIMIZE CONTRAST
    clip  = [.01 .99];                      % clip lower/upper percent
    clim  = sort(im(:));
    clim  = clim(round(numel(clim)*clip));  % new limits of caxis
    if clim(1) == clim(2)
        clim(2) = clim(1) + 1;              % sanitize clim
    end
    set(obj.h.axes.green,'Clim',clim);      % set clim
    
else                                        % FULL BIT RANGE
    if obj.Settings.greenLog
        set(obj.h.axes.green,'Clim',[0 log2(2^obj.VideoBits-1)]);
    else
        set(obj.h.axes.green,'Clim',[0 2^obj.VideoBits-1]);
    end
end