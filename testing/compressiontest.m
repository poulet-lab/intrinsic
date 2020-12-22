clear
clc
close all

data = imread('corn.tif',3);
data = uint16(data) * power(2,4);
data = repmat(data,1,1,100);
data = data + uint16(randn(size(data))*10+10) - 10;
fprintf('Size: %d x %d x %d\n',size(data))

depth = size(data,3);

options.color = false;
options.compress = 'adobe';
options.overwrite = true;
options.message = false;

methods = {'tiff_adobe','tiff_uncompressed','dicom_jpeg2000_lossless',...
    'bf_lzw','bf_uncompressed','bf_zlib','tiff2_adobe'};
ext = {'tiff','tiff','dcm','tiff','tiff','tiff','tiff'};
for ii = 7%1:numel(methods)
    
    fprintf('\nMethod: %s\n',methods{ii})
    fn = fullfile(pwd,sprintf('compressiontest_%s.%s',methods{ii},ext{ii}));
    switch ii
        case 1
            tic
            saveastiff(data,fn,options);
        case 2
            tic
            options.compress = 1;
            saveastiff(data,fn,options);
        case 3
            data2 = reshape(data,size(data,1),size(data,2),1,[]);
            tic
            dicomwrite(data2,fn,'CompressionMode','JPEG2000 lossless')
        case 4
            if exist(fn,'file')
                delete(fn)
            end
            data2 = reshape(data,size(data,1),size(data,2),1,1,[]);
            tic
            bfsave(data,fn,'compression','LZW');
        case 5
            if exist(fn,'file')
                delete(fn)
            end
            data2 = reshape(data,size(data,1),size(data,2),1,1,[]);
            tic
            bfsave(data,fn,'compression','Uncompressed');
        case 6
            if exist(fn,'file')
                delete(fn)
            end
            data2 = reshape(data,size(data,1),size(data,2),1,1,[]);
            tic
            bfsave(data,fn,'compression','zlib');
        case 7
            t = Tiff(fn,'w');
            options = struct( ...
            	'ImageWidth',          size(data,2), ...
            	'ImageLength',         size(data,1), ...
            	'Photometric',         Tiff.Photometric.MinIsBlack, ...
            	'Compression',         Tiff.Compression.AdobeDeflate, ...
            	'PlanarConfiguration', Tiff.PlanarConfiguration.Chunky, ...
            	'BitsPerSample',       16, ...
            	'SamplesPerPixel',     1, ...
            	'XResolution',         200, ...
            	'YResolution',         200, ...
                'ResolutionUnit',      Tiff.ResolutionUnit.Centimeter, ...
            	'Software',            'Intrinsic Imaging', ...
            	'Make',                'adaptor', ...
            	'Model',               'device', ...
            	'DateTime',            datestr(now,'yyyy:mm:dd HH:MM:SS'), ...
                'ImageDescription',    sprintf('ImageJ=\nimages=100\nframes=50\nslices=2\nhyperstack=true\nunit=cm\nfinterval=0.1\nfps=10\n'), ...
                'SampleFormat',        Tiff.SampleFormat.UInt, ...
            	'RowsPerStrip',        512);
            data2 = reshape(data,size(data,1),size(data,2),2,[]);
            data2(:,:,2,:) = flipud(data2(:,:,2,:));
            tic
            for d = 1:size(data2,4)
                for slice = 1:size(data2,3)
                    t.setTag(options);
                    t.write(data2(:, :, slice, d));
                    if ~(d==size(data2,4) && slice==size(data2,3))
                       t.writeDirectory();
                    end
                end
            end
            t.close()
            a = Tiff(fn);
            a.getTag('ImageDescription')
    end
    toc
    
    tmp = dir(fn);
    fprintf('Filesize: %0.2f MB\n',tmp.bytes/1024/1024)
end

%%
a = Tiff('compressiontest_bf_uncompressed.tiff');
a.getTag('ImageDescription')
%%
a = Tiff('mitosis.tif');
a.getTag('ImageDescription')
%%
a = Tiff('compressiontest_tiff2_adobe-1.tif');
a.getTag('ImageDescription')