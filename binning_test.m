close all
clc

data = repmat(1:100,100,1);
%data = [1 1 2 2; 1 1 2 2; 3 3 4 4; 3 3 4 4];

subplot(1,3,1)
imagesc(data)
axis square

reps = 100;
f    = 2;

tic
for reps = 1:reps
    %out1 = colfilt(data,[f f],'distinct',@mean);
end
toc

tic
for reps = 1:reps
    out2 = blockproc(data,[f f], @(x) mean(x.data(:)),'UseParallel',1);
end
toc


subplot(1,3,2)
imagesc(out1)
axis square

subplot(1,3,3)
imagesc(out2)
axis square