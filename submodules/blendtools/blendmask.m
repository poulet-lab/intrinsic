function outpict=blendmask(FG,BG,mask)
%   BLENDMASK(FG, BG, MASK)
%       returns a copy of BG opacity-blended with FG based on 
%       pixel values of MASK. This functions similar to using a Layer Mask
%       in GIMP in 'normal' blend mode.  As pixel values in MASK vary
%       from black to white, the output image is opacity blended from
%       BG toward FG. 
%
%       blendmask() and replacepixels() serve a similar purpose, 
%       but for logical masking, replacepixels() is about 3x faster.
%
%   FG/BG is a 1 or 3-channel image array (greyscale or rgb) (uint8)
%       may also be a 4-D array of RGB images
%       dimension mismatch on dims 3:4 results in array expansion
%       dimension mismatch on dims 1:2 are not supported
%   MASK is an image specifying pixel locations to replace
%       mask may be 2-D logical or greyscale, or can be 3-D (RGB)
%       when FG or BG is 4-D, MASK may optionally be specified as 4-D
%       logical masks can be specified using multimask() or findpixels()
%
%   EXAMPLE:
%       pretend we're in GIMP with a Layer Mask set on a 'multiply' layer
%       comicart=blendmask(imblend(lineart,fills,1,'multiply'),fills,layermask);
%
%   CLASS SUPPORT:
%       return class matches input class except when FG or BG contain NaNs.
%       if NaNs are present, return class is double

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if height & width match
sFG=size(FG);
sBG=size(BG); 
sMASK=size(mask); 
if any(sFG(1:2)~=sBG(1:2)) 
    disp('BLENDMASK: fg/bg dimension mismatch')
    return
elseif any(sFG(1:2)~=sMASK(1:2)) 
    disp('BLENDMASK: mask/image dimension mismatch')
    return
end

% expand along dimension 4 where necessary
if numel(sFG)~=4 && numel(sBG)~=4 % two single images
    numframes=1;
else
    if numel(sFG)~=4 % single FG, multiple BG
        FG=repmat(FG,[1 1 1 sBG(4)]);
    elseif numel(sBG)~=4 % multiple FG, single BG
        BG=repmat(BG,[1 1 1 sFG(4)]); sBG=size(BG);
    elseif sFG(4)~=sBG(4) % two unequal imagesets
        disp('BLENDMASK: imagesets of unequal length')
        return
    end
    numframes=sBG(4);
    % expand mask as necessary
    if numel(sMASK)~=4
        mask=repmat(mask,[1 1 1 numframes]);
    end
end
    
% expand mask along dimension 3 where necessary
if size(FG,3)==1
    FG=repmat(FG,[1 1 3 1]);
elseif size(FG,3)~=3
    disp('BLENDMASK: dim 3 of fg must have size 1 or 3')
    return
end
if size(BG,3)==1
    BG=repmat(BG,[1 1 3 1]); sBG=size(BG);
elseif size(BG,3)~=3
    disp('BLENDMASK: dim 3 of bg must have size 1 or 3')
    return
end
if size(mask,3)==1
    mask=repmat(mask,[1 1 3 1]);
elseif size(mask,3)~=3
    disp('BLENDMASK: dim 3 of mask must have size 1 or 3')
    return
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fix image classes and blah blah blah
inclassFG=class(FG);
inclassBG=class(BG);
inclassMASK=class(mask);

if strcmp(inclassFG,'uint8')
    fgmax=255;
elseif strcmp(inclassFG,'double')
    if max(max(max(FG)))<=1
        fgmax=1;
    else 
        fgmax=255;
    end
else
    disp('BLENDMASK: unsupported class for FG')
    return
end

if strcmp(inclassBG,'uint8')
    bgmax=255;
elseif strcmp(inclassBG,'double')
    if max(max(max(BG)))<=1
        bgmax=1;
    else 
        bgmax=255;
    end
else
    disp('BLENDMASK: unsupported class for BG')
    return
end

if strcmp(inclassMASK,'uint8')
    maskmax=255;
elseif strcmp(inclassMASK,'double')
    if max(max(max(mask)))<=1
        maskmax=1;
    else 
        maskmax=255;
    end
elseif strcmp(inclassMASK,'logical')
    maskmax=1;
else
    disp('BLENDMASK: unsupported class for MASK')
    return
end

% need to be able to pass NaNs (no support if uint8)
if all(all(all(isnan(FG))))~=false | all(all(all(isnan(BG))))~=false
    inclassBG='double';
    disp('BLENDMASK: inputs contain NaNs; Output class forced double.')
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do opacity blending
FG=double(FG)/fgmax;
BG=double(BG)/bgmax;
mask=double(mask)/maskmax;

outpict=zeros(sBG);    
for f=1:1:numframes;
    FGframe=mask(:,:,:,f).*FG(:,:,:,f);
    BGframe=(1-mask(:,:,:,f)).*BG(:,:,:,f);
    
    outpict(:,:,:,f)=bgmax*(FGframe + BGframe);
end

outpict=cast(outpict,inclassBG);

return











