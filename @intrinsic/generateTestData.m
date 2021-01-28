function generateTestData(obj,~,~)

% %obj.clearData
% 
% imSize      = obj.Camera.ROI;
% val_mean    = power(2,obj.Camera.BitDepth-1);
% n_frames    = obj.DAQ.nFrameTrigger;
% n_trials    = 2;
% amp_noise   = 50;
% 
% sigma   = 150;
% s       = sigma / imSize(1);
% X0      = ((1:imSize(2))/ imSize(1))-.5;
% Y0      = ((1:imSize(1))/ imSize(1))-.5;
% [Xm,Ym] = meshgrid(X0, Y0);
% gauss   = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );
% 
% sigma   = 300;
% s       = sigma / imSize(1)*2;
% X0      = ((1:imSize(1)*2)/ imSize(1)*2)-.5;
% Y0      = ((1:imSize(2)*2)/ imSize(2)*2)-.5;
% [Xm,Ym] = meshgrid(X0, Y0);
% gauss2  = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );
% gauss2  = gauss2(1:imSize(1),(1:imSize(2))+round(imSize(2)/5))./4;
% 
% %data_nostim = uint16(val_mean+randn(imSize(1),imSize(2),n_frames,n_trials)*amp_noise);
% tmp = ceil(gcd(imSize(1),imSize(2))/2);
% tmp = checkerboard(tmp,1,1)>0.5;
% tmp = int32(tmp * 20);
% 
% noise_stim  = int32(val_mean+randn(imSize(1),imSize(2),n_frames,n_trials)*amp_noise);
% noise_stim  = noise_stim + repmat(tmp,1,1,n_frames,n_trials);
% 
% data_stim = repmat((gauss-gauss2)./3,1,1,n_frames);
% lambda    = 3;
% mu        = 3;
% tmp       = obj.DAQ.OutputData.Trigger.Time([1; find(diff(obj.DAQ.OutputData.Trigger.Data)>0)+1])';
% %tmp       = obj.DAQ.OutputData.Trigger.Time(obj.DAQ.OutputData.Trigger.Data>0)';
% x         = tmp(tmp>0);
% amp_stim  = (lambda./(2*pi*x.^3)).^.5 .* exp((-lambda*(x-mu).^2)./(2*mu^2*x));
% amp_stim  = -[zeros(size(tmp(tmp<=0))) amp_stim] * 50;
% for ii = 1:size(data_stim,3)
%     data_stim(:,:,ii) = data_stim(:,:,ii) * amp_stim(ii);
% end
% data_stim = int32(data_stim * 3);
% 
% data_stim = repmat(data_stim,1,1,1,n_trials);
% data_stim = uint16(data_stim + noise_stim);
% clear noise_stim
% 
% for ii = 1:size(data_stim,4)
%     obj.Stack{ii} = data_stim(:,:,:,ii);
% end
% 
% obj.processStack
% obj.TimeStamp = now;
