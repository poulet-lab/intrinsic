clear
clf
clc

fs    = 10; % Hz

imSize      = repmat(1040,2,1);
val_mean    = 2^11;
tax         = -2:(1/fs):8;
n_frames    = numel(tax);
n_trials    = 1;
amp_noise   = 75;

sigma   = 150;
s       = sigma / imSize(1);
X0      = ((1:imSize(2))/ imSize(1))-.5;
Y0      = ((1:imSize(1))/ imSize(1))-.5;
[Xm,Ym] = meshgrid(X0, Y0);
gauss   = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );

sigma   = 300;
s       = sigma / imSize(1)*2;
X0      = ((1:imSize(1)*2)/ imSize(1)*2)-.5;
Y0      = ((1:imSize(2)*2)/ imSize(2)*2)-.5;
[Xm,Ym] = meshgrid(X0, Y0);
gauss2  = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );
gauss2  = gauss2(1:imSize(1),(1:imSize(2))+round(imSize(2)/5))./4;

tmp = ceil(gcd(imSize(1),imSize(2))/2);
tmp = checkerboard(tmp,1,1)>0.5;
tmp = int32(tmp * 20);

noise_stim  = int32(val_mean+randn(imSize(1),imSize(2),n_frames,n_trials)*amp_noise);
noise_stim  = noise_stim + repmat(tmp,1,1,n_frames,n_trials);

data = repmat((gauss-gauss2)./3,1,1,n_frames);
lambda    = 3;
mu        = 3;
tmp       = tax;
x         = tmp(tmp>0);
amp_stim  = (lambda./(2*pi*x.^3)).^.5 .* exp((-lambda*(x-mu).^2)./(2*mu^2*x));
amp_stim  = -[zeros(size(tmp(tmp<=0))) amp_stim] * 50;
for ii = 1:size(data,3)
    data(:,:,ii) = data(:,:,ii) * amp_stim(ii);
end
data = int32(data * 3);

data = repmat(data,1,1,1,n_trials);
data = uint16(data + noise_stim);

%%
clf
clc
fc    = [.05 1]/(fs/2);
[b,a] = myButter(1,fc,'bandpass');

data2 = double(data);

% tic
% tmp  = mean(data2(:));
% filt = FiltFiltM(b,a,double(data2) - tmp,3);
% filt = filt + tmp;
% toc

filt = imgaussfilt(double(data),20);

% filt = imgaussfilt(filt,5);
% data2 = imgaussfilt(data2,5);

base = mean(data2(:,:,tax<0),3);
stim = data2;
data2 = (stim - base) ./ base;

base = mean(filt(:,:,tax<0),3);
stim = filt;
filt = (stim - base) ./ base;

h(1) = subplot(2,1,1);
tmp  = squeeze(data2(imSize(1)/2,imSize(2)/2,:));
plot(h(1),tax,squeeze(data2(imSize(1)/2,imSize(2)/2,:)));
hold all
plot(h(1),tax,squeeze(filt(imSize(1)/2,imSize(2)/2,:)));

%%

win = tax>=0.75 & tax<=1.25;

h(2) = subplot(2,3,4);
tmp  = mean(data2(:,:,win),3);
imagesc(h(2),tmp)
set(h(2),'CLim',[min(tmp(:)) 0])

h(3) = subplot(2,3,5);
tmp2 = mean(filt(:,:,win),3);
imagesc(h(3),tmp2)
set(h(3),'CLim',[min(tmp2(:)) 0])

h(4) = subplot(2,3,6);
imagesc(double(tmp)-double(tmp2))

%set(h(2:4),'CLim',[min(tmp(:)) max(tmp(:))])
colormap(gray)

%%
clf
clc

win = tax>=0.75 & tax<=1.25;
g = 10;

if g > 0
    filt = imgaussfilt(double(data),g);
else
    filt = double(data);
end

filt = FiltFiltM(b,a,filt,3);

base = mean(filt(:,:,tax<0),3);
stim = filt;
filt = (stim - base) ./ base;
tmp2 = mean(filt(:,:,win),3);

hax(1) = subplot(121);
imagesc(hax(1),tmp2)
axis square
set(hax(1),'CLim',[min(tmp2(:)) 0])
set(hax(1),'XTick',[],'YTick',[])
if g>0
    title(sprintf('spatial response, %dpx Gaussian',g))
else
    title('spatial response, unfiltered')
end

hax(2) = subplot(122);
plot(hax(2),tax,squeeze(filt(imSize(1)/2,imSize(2)/2,:)),'k');
hold on
xlim(hax(2),tax([1 end]))
box off
axis square
set(hax(2),'tickdir','out','box','off')
xlabel('time / s')
ylabel('\DeltaF/F')
title('temporal response')