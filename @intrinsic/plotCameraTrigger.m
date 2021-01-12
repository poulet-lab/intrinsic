function plotCameraTrigger(obj)

gridx = repmat(obj.DAQ.tTrigger,3,1);
gridx(3,:) = NaN;
gridx = gridx(:);
gridy = repmat([0 .01 NaN]',length(gridx)/3,1);

obj.h.plot.grid.XData = gridx;
obj.h.plot.grid.YData = gridy;