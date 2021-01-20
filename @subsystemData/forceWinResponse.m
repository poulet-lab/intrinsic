function out = forceWinResponse(obj,in)

validateattributes(in,{'numeric'},{'size',[1 2],'real','nonnan'})
if isempty(obj.P.DAQ.tTrigger)
    out = in;
    return
end

pCam    = obj.P.DAQ.pTrigger;
tCam    = [obj.P.DAQ.tTrigger obj.P.DAQ.tTrigger(end) + pCam];
if any(isnan(obj.WinResponse))
    changes = [0 1];
else
    changes	= round(diff([obj.WinResponse; in])/pCam) * pCam;
end

if ~any(changes)
    out = obj.WinResponse;
    return;
end

if ~diff(changes)
    % Response window has been MOVED
    % Limit the windows position to valid trigger times >= 0
    if in(1) < 0
        out = obj.WinResponse - obj.WinResponse(1);
    elseif in(2) > tCam(end)
        out = tCam(end) - diff(obj.WinResponse) * [1 0];
    else
        out = in;
    end    
else
    % Response window has been RESIZED
    % Limit the window's width to valid values.
    
    % Limit to valid trigger times >= 0
    out = [max([0 in(1)]) min([in(2) tCam(end)])];

	% Define the window's minimum & maximum width
    minWidth = pCam;
    maxWidth = abs(tCam(1));
    if obj.UseControl
        maxWidth = maxWidth / 2;
    end
    
    % Restrict the window's width to the defined limits
    if diff(in) < minWidth
        if changes(1)
            out(1) = out(2) - minWidth;
        else
            out(2) = out(1) + minWidth;
        end
    elseif diff(in) > maxWidth
        if changes(1)
            out(1) = out(2) - maxWidth;
        else
            out(2) = out(1) + maxWidth;
        end
    end
end

% snap to camera triggers
[~,idxNew] = arrayfun(@(x) min(abs(tCam-x)),out);
out = tCam(idxNew);