function plotCameraTrigger(obj)

tcam  = obj.DAQvec.time(obj.DAQvec.cam);
gridx = repmat(tcam,3,1);
gridx(3,:) = NaN;
gridx = gridx(:);
gridy = repmat([0 .01 NaN]',length(gridx)/3,1);

obj.h.plot.grid.XData = gridx;
obj.h.plot.grid.YData = gridy;

xlim(obj.h.axes.temporalBg,tcam([obj.WarmupN+1 end]))