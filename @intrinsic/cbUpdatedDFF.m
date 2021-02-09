function cbUpdatedDFF(obj,~,~)

obj.h.image.colorbar.Visible = ~all(isnan(obj.Data.DFF(:)));