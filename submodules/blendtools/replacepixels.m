function outpict=replacepixels(newcolor,inpict,mask)
%   REPLACEPIXELS(NEWCOLOR, INPICT, MASK)
%   REPLACEPIXELS(NEWPICT, INPICT, MASK)
%       returns a copy of INPICT with all selected pixels replaced by NEWCOLOR.
%       alternatively, replacement can be sourced from NEWPICT
%       mask can be specified using multimask() or findpixels()
%
%       blendmask() and replacepixels() serve a similar purpose, 
%       but for logical masking, replacepixels() is about 3x faster.
%
%   INPICT is a 3-channel image array (m x n x 3) (uint8)
%       may also be a 4-D array of RGB images
%   NEWCOLOR is a 3-element row vector specifying the replacement color
%   NEWPICT is a 3-channel image array matching size of INPICT
%   MASK is a 2-D logical array specifying pixel locations to replace
%       when INPICT is 4-D, MASK may either be 2-D or 4-D
%
%   CLASS SUPPORT:
%       return class matches input class unless newcolor contains NaN
%       when sum(isnan(newcolor))~=0, return class is double

% all this reshaping is to make indexing possible during replacement
% otherwise, it's not simple to assign a page vector to pixels in 
% a 3D array using a 2D logical index map

numframes=1;
s=size(inpict);
if numel(s)==4 % are we working 4-D?
    numframes=s(4);
    if numel(size(mask))~=4
        % expand mask as necessary
        mask=repmat(mask,[1 1 1 numframes]);
    end
    if numel(size(newcolor))~=4 && numel(newcolor)>3
        % expand newcolor/bg as necessary
        newcolor=repmat(newcolor,[1 1 1 numframes]);
    else
        % what about triplets when 4D?
        newcolor=repmat(newcolor,[1 1 1 numframes]);
    end
end
    
% uint8 does not support NaN
if sum(isnan(newcolor))~=0
    inpict=double(inpict);
end

outpict=zeros(size(inpict),class(inpict));
for f=1:1:numframes;
    localmask=logical(reshape(mask(:,:,1,f),1,[]));
    localimg=inpict(:,:,:,f);
    localnc=newcolor(:,:,:,f);   
    maskpixels=sum(localmask);
    
    % reshape image 
    imstripe=permute(reshape(localimg,1,[],3),[3 2 1]);
    
    % is the last argument a color or a picture?
    if numel(localnc)>3 && all(size(localnc)==size(localimg))
        bgstripe=permute(reshape(localnc,1,[],3),[3 2 1]);
      
        % replace elements from new picture
        imstripe(:,localmask)=bgstripe(:,localmask);
    else
        % replace elements with new color
        imstripe(:,localmask)=repmat(localnc',1,maskpixels);
    end

    % reshape to original dimensions
    outpict(:,:,:,f)=reshape(permute(imstripe,[3 2 1]),s(1:3));

end

return











