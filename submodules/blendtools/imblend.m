function  outpict=imblend(FG,BG,opacity,blendmode,amount)
%   IMBLEND(FG, BG, OPACITY, BLENDMODE,{AMOUNT})
%       blend images or imagesets as one would blend layers in GIMP or
%       Photoshop.  
%
%   FG, BG are RGB image arrays of same H,V dimension
%       both can be single images or 4-D imagesets of equal length
%       can also blend a single image with a 4-D imageset
%       mismatches of dimensions 3:4 result in array expansion
%       allows blending static overlays with an entire animation
%       mismatches of dimensions 1:2 are not supported
%   OPACITY is a scalar from 0 to 1
%       defines mixing of blended result and original BG
%   AMOUNT is a scalar (optional, default 1)
%       used to internally scale the influence of blend calculations
%       modes which accept 'amount' argument are marked with effective range
%   BLENDMODE is a string assignment (see list) 
%       this parameter is insensitive to case and spacing
%
%   ============================= MODES =============================
%   Opacity
%       normal  
%
%   Light & Contrast
%       overlay     (standard method)
%       soft light   (GIMP overlay)
%       hard light
%       vivid light
%       pin light
%       hard mix     (similar to posterization)                  amount:[0 1]
%       posterize    (stronger influence from mask)
%       phoenix
%       reflect
%       glow
%       freeze
%       heat
%       scale add       (add bg to fg deviation from mean)     amount:(-inf to +inf)
%       scale mult      (scale bg by mean-normalized fg)       amount:(-inf to +inf)
%       contrast        (adjust bg contrast by mean-normalized fg) amount:[0 to +inf)
%
%   Dodge & Burn
%       color dodge  (similar to GIMP dodge)                     amount:[0 1]
%       color burn   (similar to GIMP burn)                      amount:[0 1]
%       linear dodge                                             amount:[0 1]
%       linear burn                                              amount:[0 1]
%       soft dodge
%       soft burn
%
%   Relational
%       lighten RGB     (lighten only (RGB))
%       darken RGB      (darken only (RGB))
%       lighten Y       (lighten only (test luma only))
%       darken Y        (darken only (test luma only))
%   
%   Arithmetic
%       multiply
%       screen
%       divide
%       addition
%       subtraction
%       difference
%       exclusion 
%       negation
%       interpolate     (cosine interpolation)
%       average         (linear interpolation, same as 'normal' at 50% opacity)
%       grain extract
%       grain merge
%
%   Component
%       hue             (H in CIELCHab)
%       saturation      (C in CIELCHab)
%       color           (HS in HSL, preserve Y)
%       color lch       (CH in CIELCHab)
%       color hsl       (HS in HSL)
%       color hsyp      (HS in HSYp)
%       value           (max(R,G,B))
%       luma            (0.299*R + 0.587*G + 0.114*B)
%       lightness       (mean(min(R,G,B),max(R,G,B))
%       intensity       (mean(R,G,B))
%       transfer inchan>outchan   (directly transfer any channel to another)
%       permute inchan>H     (rotate hue)                         amount:(-inf to +inf)
%       permute inchan>HS    (rotate hue and blend chroma)        amount:(-inf to +inf)
%
%   NOTE:
%       HUE & SATURATION modes are derived from LCHab instead of HSL as in GIMP.
%       If H or S modes are desired in LCH, HSI or HSV, use 'transfer' instead.
%
%       COLOR MODES: 
%       'color' is a variant of the HSL method with an attempt to enforce luma preservation (fastest)
%       'color hsyp' attempts to provide best uniformity, at the cost of maximum chroma range.
%       'color hsl' matches the legacy 'color' blend mode in GIMP
%        Based only on experiment, LCHab method best approximates Photoshop behavior.
%
%       TRANSFER MODES:
%       mode accepts channel strings based on RGB, HuSLuv, HSY, HSYp, HSI, HSL, HSV, or CIELCHab models
%           'y', 'r', 'g', 'b'
%           'h_husl', 's_husl', 'l_husl'
%           'h_hsy', 's_hsy', 'y_hsy'
%           'h_hsyp', 's_hsyp', 'y_hsyp'
%           'h_hsi', 's_hsi', 'i_hsi'
%           'h_hsl', 's_hsl', 'l_hsl'
%           'h_hsv', 's_hsv', 'v_hsv'
%           'l_lch', 'c_lch', 'h_lch'
%       non-rgb symmetric channel transfers (e.g. V>V or Y>Y) are easier applied otherwise
%           (e.g. 'value' or 'luma' blend modes)
%  
%       PERMUTATION MODES:
%       modes can accept input channel strings 'h', 's', 'y', 'dh', 'ds', 'dy'
%       permutations actually occur on H and S in the HuSLuv model
%       dH>H and dH>HS permutations are same as 'hue' when amount==-1
%       color permutations (inchan>HS) combine hue rotation and chroma blending
%           chroma blending is maximized when abs(amount)==1
%
%   CLASS SUPPORT:
%       Accepts images of 'uint8', 'double', and 'logical'
%       Return type is inherited from BG
%       In the case of a 'double' input, any image containing values >1
%       is assumed to have a white value of 255. 

%   SOURCES:
%       https://www.ffmpeg.org/doxygen/2.4/vf__blend_8c_source.html
%       http://dunnbypaul.net/blends/
%       http://www.pegtop.net/delphi/articles/blendmodes/
%       http://www.venture-ware.com/kevin/coding/lets-learn-math-photoshop-blend-modes/
%       http://www.deepskycolors.com/archive/2010/04/21/formulas-for-Photoshop-blending-modes.html
%       http://en.wikipedia.org/wiki/Blend_modes
%       http://en.wikipedia.org/wiki/YUV
%       http://www.kineticsystem.org/?q=node/13
%       http://www.simplefilter.de/en/basics/mixmods.html

if nargin ~= 5
    amount=1;
end


% i had intended to make this more class-insensitive, but i never need it
% output type is inherited from BG, assumes white value of either 1 or 255
inclassFG=class(FG);
inclassBG=class(BG);
if strcmp(inclassFG,'uint8')
    fgmax=255;
elseif strcmp(inclassFG,'double')
    if max(max(max(FG)))<=1
        fgmax=1;
    else 
        fgmax=255;
    end
elseif strcmp(inclassFG,'logical')
    fgmax=1;
else
    disp('IMBLEND: unsupported class for FG')
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
elseif strcmp(inclassBG,'logical')
    bgmax=1;
else
    disp('IMBLEND: unsupported class for BG')
    return
end


% expand along dimension 3 where necessary
s3FG=size(FG,3);
s3BG=size(BG,3);
if s3FG<s3BG
    FG=repmat(FG,[1 1 s3BG 1]);
elseif s3FG>s3BG
    BG=repmat(BG,[1 1 s3FG 1]);
end

% check if height & width match
sFG=size(FG);
sBG=size(BG);  
if any(sFG(1:2)~=sBG(1:2)) 
    disp('IMBLEND: images of mismatched dimension')
    return
end

% check frame count and expand as necessary
if length(sFG)~=4 && length(sBG)~=4 % two single images
    images=1;
else
    if length(sFG)~=4 % single FG, multiple BG
        FG=repmat(FG,[1 1 1 sBG(4)]);
    elseif length(sBG)~=4 % multiple FG, single BG
        BG=repmat(BG,[1 1 1 sFG(4)]); sBG=size(BG);
    elseif sFG(4)~=sBG(4) % two unequal imagesets
        disp('IMBLEND: imagesets of unequal length')
        return
    end
    images=sBG(4);
end

% perform blend operations
modestring=lower(blendmode(blendmode~=' '));
outpict=zeros(sBG);    
for f=1:1:images
    I=double(BG(:,:,:,f))/bgmax;
    M=double(FG(:,:,:,f))/fgmax;

    switch modestring
        case 'normal'
            R=M;

        case 'screen'
            R=1-((1-M).*(1-I));

        case 'overlay'  % actual standard overlay mode 
            hi=I>0.5; lo=~hi;
            R=zeros(size(I));
            R(lo)=2*I(lo).*M(lo);
            R(hi)=1-2*(1-M(hi)).*(1-I(hi));

        case 'softlight' % same as GIMP 'overlay' due to legacy bug
            Rs=1-((1-M).*(1-I));
            R=(I.*((1-I).*M+Rs));

        case 'hardlight'
            hi=M>0.5; lo=~hi;
            R=zeros(size(I));
            R(lo)=2*I(lo).*M(lo);
            R(hi)=1-2*(1-M(hi)).*(1-I(hi));

        case 'vividlight'  % test this; example formulae are inconsistent
            hi=M>0.5; lo=~hi;
            R=zeros(size(I));
            R(lo)=1-(1-I(lo))./(2*M(lo));
            R(hi)=I(hi)./(1-2*(M(hi)-0.5));
            
        case 'pinlight'
            hi=M>0.5; lo=~hi;
            R=zeros(size(M));
            R(hi)=max(I(hi),2*(M(hi)-0.5));
            R(lo)=min(I(lo),2*M(lo));
            
        case 'phoenix'
            R=min(M,I)-max(M,I)+1;
            
        case 'reflect'
            R=min(1,(M.*M./(1-I)));
            R(I==1)=1;
            
        case 'glow'
            R=min(1,(I.*I./(1-M)));
            R(M==1)=1;
            
        case 'freeze'
            R=min(1,((1-M).*(1-M)./I));
            R=1-R;
            
        case 'heat'
            R=min(1,((1-I).*(1-I)./M));
            R=1-R;
            
        case 'posterize'  % actually a broken version of vividlight
            hi=M>0.5; lo=~hi;
            R=zeros(size(I));
            R(lo)=(1-I(lo))./(2*(M(lo)-0.5));
            R(hi)=1-I(hi)./(1-2*M(hi));

        case 'hardmix' % ps mode similar to posterization
            amount=max(min(amount,1),0);
            Rs=M+I;
            R=Rs;
            R(Rs>1)=1*amount;
            R(Rs<1)=0;

        % DODGES/BURNS    
        case'colordodge'
            amount=max(min(amount,1),0);
            R=I./(1-M*amount);

        case 'colorburn'
            amount=max(min(amount,1),0);
            R=1-(1-I)./(M*amount+(1-amount));

        case 'lineardodge' % addition
            amount=max(min(amount,1),0);
            R=M*amount+I;

        case 'linearburn' 
            amount=max(min(amount,1),0);
            R=M*amount+I-1*amount;
            
        case 'softdodge'
            pm=(M+I)<1;
            R=zeros(size(M));
            R(pm)=0.5*M(pm)./(1-I(pm));
            R(~pm)=1-0.5*(1-I(~pm))./M(~pm);

        case 'softburn'
            pm=(M+I)<1;
            R=zeros(size(M));
            R(pm)=0.5*I(pm)./(1-M(pm));
            R(~pm)=1-0.5*(1-M(~pm))./I(~pm);

        % SIMPLE MATH OPS    
        case 'lightenrgb' % lighten only (RGB, no luminance)
            R=max(I,M);

        case 'darkenrgb' % darken only (RGB, no luminance)
            R=min(I,M);

        case 'lighteny' % lighten only (based on luminance)
            factors=[0.299 0.587 0.114];
            osize=size(M(:,:,1));
            cscale=repmat(reshape(factors,1,1,3),[osize 1]);
            mask=sum(M.*cscale,3)>sum(I.*cscale,3);
            R=double(replacepixels(255*M,255*I,mask))/255;
            
        case 'darkeny' % darken only (based on luminance)
            factors=[0.299 0.587 0.114];
            osize=size(M(:,:,1));
            cscale=repmat(reshape(factors,1,1,3),[osize 1]);
            mask=sum(M.*cscale,3)<sum(I.*cscale,3);
            R=double(replacepixels(255*M,255*I,mask))/255;

        case 'multiply'
            R=M.*I;

        case 'divide'
            R=I./(M+1E-3);

        case 'addition' % same as lineardodge
            R=M+I;

        case 'subtraction'
            R=I-M;

        case 'difference'
            R=abs(M-I);

        case 'exclusion'
            R=M+I-2*M.*I;
            
        case 'negation'
            R=1-abs(1-M-I);
            
        case 'grainextract'
            R=I-M+0.5;
            
        case 'grainmerge'
            R=I+M-0.5;
            
        case 'interpolate'
            R=0.25-cos(M*pi)/4 + 0.25-cos(I*pi)/4;
            
        case 'average'
            R=(M+I)/2;

        case 'hue' % bounded LCHab operation
            Mlch=rgb2lch(M,'lab');
            Rlch=rgb2lch(I,'lab');
            Rlch(:,:,3)=Mlch(:,:,3);
            R=lch2rgb(Rlch,'lab','truncatelch');
            
        case 'saturation' % bounded LCHab operation
            Mlch=rgb2lch(M,'lab');
            Rlch=rgb2lch(I,'lab');
            Rlch(:,:,2)=Mlch(:,:,2);
            R=lch2rgb(Rlch,'lab','truncatelch');
                
        % COLOR BLEND MODES
        % COLOR_HSL matches legacy GIMP mode
        % COLOR_HSY uses a chroma-normalized variant of YPbPr
        % COLOR_HuSL uses chroma-normalized CIELCHab or CIELCHuv as specified
        
        case 'color' % swap H & S in HSL; preserve initial Y
            cst=exist('colorspace','file');
            if cst~=0
                factors=[0.299 0.587 0.114];
                osize=size(M(:,:,1));
                cscale=repmat(reshape(factors,1,1,3),[osize 1]);
                Y=sum(I.*cscale,3);
                Mhsl=colorspace('RGB->HSL',M);
                Rhsl=colorspace('RGB->HSL',I);
                Rhsl(:,:,1:2)=Mhsl(:,:,1:2);
                R=colorspace('RGB<-HSL',Rhsl);
                Ryiq=colorspace('YIQ<-RGB',R);
                Ryiq(:,:,1)=Y;
                R=colorspace('RGB<-YIQ',Ryiq);
            else
                disp('IMBLEND: COLORSPACE() is required for ''color'' blend mode');
                disp('https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations');
                return
            end
                        
        case 'colorhsyp' % swap H & S in HSYp
            Mhsy=rgb2hsy(M,'pastel');
            Rhsy=rgb2hsy(I,'pastel');
            Rhsy(:,:,1:2)=Mhsy(:,:,1:2);
            R=hsy2rgb(Rhsy,'pastel');
          
        case 'colorlchab' % bounded LCHab operation
            Mlch=rgb2lch(M,'lab');
            Rlch=rgb2lch(I,'lab');
            Rlch(:,:,2:3)=Mlch(:,:,2:3);
            R=lch2rgb(Rlch,'lab','truncatelch');
            
        case 'colorhsl' % swap H & S in HSL
            cst=exist('colorspace','file');
            if cst~=0
                Mhsl=colorspace('RGB->HSL',M);
                Rhsl=colorspace('RGB->HSL',I);
                Rhsl(:,:,1:2)=Mhsl(:,:,1:2);
                R=colorspace('RGB<-HSL',Rhsl);
            else
                disp('IMBLEND: COLORSPACE() is required for ''color hsl'' blend mode');
                disp('https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations');
                return
            end

            
        % V=max([R G B])
        % L=mean(max([R G B]),min([R G B]))
        % I=mean([R G B])
        % Y=[0.299 0.587 0.114]*[R G B]'

        case 'value'
            Mhsv=rgb2hsv(M);
            Rhsv=rgb2hsv(I);
            Rhsv(:,:,3)=Mhsv(:,:,3);
            R=hsv2rgb(Rhsv); 

        % all colorspace() Y-swaps produce identical results within 1 LSB
        % (YUV, YIQ, YCbCr, YPbPr, YDbDr)
        case {'luma', 'luma1', 'luma2'} % swaps fg bg luma
            cst=exist('colorspace','file');
            if cst~=0
                Myiq=colorspace('RGB->YIQ',M);
                Ryiq=colorspace('RGB->YIQ',I);
                Ryiq(:,:,1)=Myiq(:,:,1);
                R=colorspace('RGB<-YIQ',Ryiq);
            else
                Myiq=rgb2ntsc(M);
                Ryiq=rgb2ntsc(I);
                Ryiq(:,:,1)=Myiq(:,:,1);
                R=ntsc2rgb(Ryiq);
            end
  
        case 'lightness' % swaps fg bg lightness
            cst=exist('colorspace','file');
            if cst~=0
                Mhsl=colorspace('RGB->HSL',M);
                Rhsl=colorspace('RGB->HSL',I);
                Rhsl(:,:,3)=Mhsl(:,:,3);
                R=colorspace('RGB<-HSL',Rhsl);
            else
                disp('IMBLEND: COLORSPACE() is required for ''lightness'' blend mode');
                disp('https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations');
                return
            end

        % for some reason COLORSPACE() maps 'HSI' input parameters to 'HSL' 
        % until that's fixed, I'm using my own conversions
        case 'intensity' % swaps fg bg intensity 
            Mhsi=rgb2hsi(M);
            Rhsi=rgb2hsi(I);
            Rhsi(:,:,3)=Mhsi(:,:,3);
            R=hsi2rgb(Rhsi);
                        
            
        % SCALING and CONTRAST FUNCTION CONCOCTIONS
        %   this may not be ideal because it doesn't easily permit absolute-scaled inputs
        %   but it's what i wanted for my own purposes
            
        % SCALE ADD treats FG as an additive gain map with a null point at its mean
        case 'scaleadd'
            Mstretch=imadjust(M,stretchlim(M));
            centercolor=mean(mean(Mstretch,1),2);
            R=zeros(size(I));
            for c=1:1:3;
                R(:,:,c)=I(:,:,c)+(Mstretch(:,:,c)-centercolor(:,:,c))*amount;
            end

        % SCALE MULT treats FG as a gain map with a null point at its mean
        case 'scalemult'
            Mstretch=imadjust(M,stretchlim(M));
            centercolor=mean(mean(Mstretch,1),2);
            R=zeros(size(I));
            for c=1:1:3;
                R(:,:,c)=I(:,:,c).*(Mstretch(:,:,c)./centercolor(:,:,c))*amount;
            end
            
        % CONTRAST uses a stretched copy of FG to map [IN_LO and IN_HI] for stretching BG contrast
        %   treats FG as a gain map with a null point at its mean
        case 'contrast'
            amount=max(amount,0);
            Mstretch=imadjust(M,stretchlim(M));
            centercolor=mean(mean(Mstretch,1),2);
            R=zeros(size(I));
            for c=1:1:3;
                lo=-min(Mstretch(:,:,c)-centercolor(c),0)*amount;
                hi=1-max(Mstretch(:,:,c)-centercolor(c),0)*amount;
                R(:,:,c)=(I(:,:,c)-lo)./max(hi-lo,0);
            end
            
        otherwise
            % PARAMETRIC MODES
            if numel(modestring)>=11 && strcmp(modestring(1:8),'transfer')
                % CHANNEL TRANSFER
                com=modestring(9:end);
                com=com(com~='_');
                [inchan outchan]=strtok(com,'>');
                outchan=outchan(outchan~='>');
                R=I;
                
                switch inchan
                    case 'r'
                        pass=M(:,:,1);
                    case 'g'
                        pass=M(:,:,2);
                    case 'b'
                        pass=M(:,:,3); 
                    case 'hhsl'
                        cst=exist('colorspace','file');
                        if cst~=0
                            Mhsl=colorspace('RGB->HSL',M);
                            pass=Mhsl(:,:,1)/360;
                        else
                            disp('IMBLEND: COLORSPACE() is required for HSL operations in ''transfer'' blend mode');
                            disp('https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations');
                            return
                        end
                    case 'shsl'
                        cst=exist('colorspace','file');
                        if cst~=0
                            Mhsl=colorspace('RGB->HSL',M);
                            pass=Mhsl(:,:,2);
                        else
                            disp('IMBLEND: COLORSPACE() is required for HSL operations in ''transfer'' blend mode');
                            disp('https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations');
                            return
                        end
                    case 'lhsl'
                        cst=exist('colorspace','file');
                        if cst~=0
                            Mhsl=colorspace('RGB->HSL',M);
                            pass=Mhsl(:,:,3);
                        else
                            disp('IMBLEND: COLORSPACE() is required for HSL operations in ''transfer'' blend mode');
                            disp('https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations');
                            return
                        end
                    case 'hhsi'
                        Mhsi=rgb2hsi(M);
                        pass=Mhsi(:,:,1)/360;
                    case 'shsi'
                        Mhsi=rgb2hsi(M);
                        pass=Mhsi(:,:,2);
                    case {'ihsi','i'}
                        Mhsi=rgb2hsi(M);
                        pass=Mhsi(:,:,3);                        
                    case 'hhsv'
                        Mhsv=rgb2hsv(M);
                        pass=Mhsv(:,:,1);
                    case 'shsv'
                        Mhsv=rgb2hsv(M);
                        pass=Mhsv(:,:,2);
                    case {'vhsv','v'}
                        Mhsv=rgb2hsv(M);
                        pass=Mhsv(:,:,3);
                    case {'llch','l'}
                        Mlch=rgb2lch(M,'lab');
                        pass=Mlch(:,:,1)/100;
                    case {'clch','c'}
                        Mlch=rgb2lch(M,'lab');
                        pass=Mlch(:,:,2)/134.2;
                    case 'hlch'
                        Mlch=rgb2lch(M,'lab');
                        pass=Mlch(:,:,3)/360;
                    case 'hhusl'
                        Mhusl=rgb2husl(M);
                        pass=Mhusl(:,:,1)/360;
                    case 'shusl'
                        Mhusl=rgb2husl(M);
                        pass=Mhusl(:,:,2)/100;
                    case 'lhusl'
                        Mhusl=rgb2husl(M);
                        pass=Mhusl(:,:,3)/100;
                    case {'y','yhsy','yhsyp'}
                        factors=[0.299 0.587 0.114];
                        osize=size(M(:,:,1));
                        cscale=repmat(reshape(factors,1,1,3),[osize 1]);
                        pass=sum(M.*cscale,3);
                    case {'hhsy','hhsyp'}
                        Mhsy=rgb2hsy(M);
                        pass=Mhsy(:,:,1)/360;
                    case 'shsy'
                        Mhsy=rgb2hsy(M);
                        pass=Mhsy(:,:,2);
                    case 'shsyp'
                        Mhsy=rgb2hsy(M,'pastel');
                        pass=Mhsy(:,:,2);
                    otherwise
                        disp('IMBLEND: unknown INCHAN parameter for TRANSFER mode');
                        return
                end  
                        
                switch outchan
                    case 'r'
                        R(:,:,1)=pass;
                    case 'g'
                        R(:,:,2)=pass;
                    case 'b'
                        R(:,:,3)=pass; 
                    case 'hhsl'
                        cst=exist('colorspace','file');
                        if cst~=0
                            Rhsl=colorspace('RGB->HSL',R);
                            Rhsl(:,:,1)=pass*360;
                            R=colorspace('RGB<-HSL',Rhsl);
                        else
                            disp('IMBLEND: COLORSPACE() is required for HSL operations in ''transfer'' blend mode');
                            disp('https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations');
                            return
                        end
                    case 'shsl'
                        cst=exist('colorspace','file');
                        if cst~=0
                            Rhsl=colorspace('RGB->HSL',R);
                            Rhsl(:,:,2)=pass;
                            R=colorspace('RGB<-HSL',Rhsl);
                        else
                            disp('IMBLEND: COLORSPACE() is required for HSL operations in ''transfer'' blend mode');
                            disp('https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations');
                            return
                        end
                    case 'lhsl'
                        cst=exist('colorspace','file');
                        if cst~=0
                            Rhsl=colorspace('RGB->HSL',R);
                            Rhsl(:,:,3)=pass;
                            R=colorspace('RGB<-HSL',Rhsl);
                        else
                            disp('IMBLEND: COLORSPACE() is required for HSL operations in ''transfer'' blend mode');
                            disp('https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations');
                            return
                        end
                    case 'hhsi'
                        Rhsi=rgb2hsi(R);
                        Rhsi(:,:,1)=pass*360;
                        R=hsi2rgb(Rhsi);
                    case 'shsi'
                        Rhsi=rgb2hsi(R);
                        Rhsi(:,:,2)=pass;
                        R=hsi2rgb(Rhsi);
                    case {'ihsi','i'}
                        Rhsi=rgb2hsi(R);
                        Rhsi(:,:,3)=pass;
                        R=hsi2rgb(Rhsi);
                    case 'hhsv'
                        Rhsv=rgb2hsv(R);
                        Rhsv(:,:,1)=pass;
                        R=hsv2rgb(Rhsv);
                    case 'shsv'
                        Rhsv=rgb2hsv(R);
                        Rhsv(:,:,2)=pass;
                        R=hsv2rgb(Rhsv);
                    case {'vhsv','v'}
                        Rhsv=rgb2hsv(R);
                        Rhsv(:,:,3)=pass;
                        R=hsv2rgb(Rhsv);
                    case {'llch','l'}
                        Rlch=rgb2lch(R,'lab');
                        Rlch(:,:,1)=pass*100;
                        R=lch2rgb(Rlch,'lab','truncatelch');
                    case {'clch','c'}
                        Rlch=rgb2lch(R,'lab');
                        Rlch(:,:,2)=pass*134.2;
                        R=lch2rgb(Rlch,'lab','truncatelch');
                    case 'hlch'
                        Rlch=rgb2lch(R,'lab');
                        Rlch(:,:,3)=pass*360;
                        R=lch2rgb(Rlch,'lab','truncatelch');
                    case 'hhusl'
                        Rhusl=rgb2husl(R);
                        Rhusl(:,:,1)=pass*360;
                        R=husl2rgb(Rhusl);
                    case 'shusl'
                        Rhusl=rgb2husl(R);
                        Rhusl(:,:,2)=pass*100;
                        R=husl2rgb(Rhusl);
                    case 'lhusl'
                        Rhusl=rgb2husl(R);
                        Rhusl(:,:,3)=pass*100;
                        R=husl2rgb(Rhusl);
                    case {'y','yhsy','yhsyp'}
                        Rhsy=rgb2hsy(R);
                        Rhsy(:,:,3)=pass;
                        R=hsy2rgb(Rhsy);
                    case {'hhsy','hhsyp'}
                        Rhsy=rgb2hsy(R);
                        Rhsy(:,:,1)=pass*360;
                        R=hsy2rgb(Rhsy);   
                    case 'shsy'
                        Rhsy=rgb2hsy(R);
                        Rhsy(:,:,2)=pass;
                        R=hsy2rgb(Rhsy); 
                    case 'shsyp'
                        Rhsy=rgb2hsy(R,'pastel');
                        Rhsy(:,:,2)=pass;
                        R=hsy2rgb(Rhsy,'pastel'); 
                    otherwise
                        disp('IMBLEND: unknown OUTCHAN parameter for TRANSFER mode');
                        return
                end 
                
            elseif numel(modestring)>=10 && strcmp(modestring(1:7),'permute')
                % HUE/COLOR PERMUTATION
                com=modestring(8:end);
                [inchan outchan]=strtok(com,'>');
                outchan=outchan(outchan~='>');
                                
                Rhusl=rgb2husl(I);
                Rhusl(:,:,1)=Rhusl(:,:,1)/360;
                Rhusl(:,:,2)=Rhusl(:,:,2)/100;
                Rhusl(:,:,3)=Rhusl(:,:,3)/100;
                
                switch inchan
                    case 'h'
                        Mhusl=rgb2husl(M);
                        pass=Mhusl(:,:,1)/360;
                    case 'dh'
                        Mhusl=rgb2husl(M);
                        pass=Rhusl(:,:,1)-Mhusl(:,:,1)/360;
                    case 's'
                        Mhusl=rgb2husl(M);
                        pass=Mhusl(:,:,2)/100;
                    case 'ds'
                        Mhusl=rgb2husl(M);
                        pass=Rhusl(:,:,2)-Mhusl(:,:,2)/100;
                    case 'y'
                        factors=[0.299 0.587 0.114];
                        osize=size(M(:,:,1));
                        cscale=repmat(reshape(factors,1,1,3),[osize 1]);
                        pass=sum(M.*cscale,3);
                    case 'dy'
                        factors=[0.299 0.587 0.114];
                        osize=size(M(:,:,1));
                        cscale=repmat(reshape(factors,1,1,3),[osize 1]);
                        Ym=sum(M.*cscale,3);
                        Yi=sum(I.*cscale,3);
                        pass=Yi-Ym;
                    otherwise
                        disp('IMBLEND: unknown INCHAN parameter for PERMUTE mode');
                        return
                end  
                        
                switch outchan
                    case 'h'
                        Rhusl(:,:,1)=mod(Rhusl(:,:,1)+pass*amount,1)*360;
                        Rhusl(:,:,2)=Rhusl(:,:,2)*100;
                        Rhusl(:,:,3)=Rhusl(:,:,3)*100;
                        R=husl2rgb(Rhusl);
                    case 'hs'
                        if any(inchan=='y')
                            Mhusl=rgb2husl(M);
                            Mhusl(:,:,1)=Mhusl(:,:,1)/360;
                            Mhusl(:,:,2)=Mhusl(:,:,2)/100;
                        end
                        amt=max(min(abs(amount),1),0); % needed since S-blending has limited range
                        Rhusl(:,:,1)=mod(Rhusl(:,:,1)+pass*amount,1)*360;
                        Rhusl(:,:,2)=amt*Mhusl(:,:,2)+(1-amt)*Rhusl(:,:,2);
                        Rhusl(:,:,2)=Rhusl(:,:,2)*100;
                        Rhusl(:,:,3)=Rhusl(:,:,3)*100;
                        R=husl2rgb(Rhusl);
                    otherwise
                        disp('IMBLEND: unknown OUTCHAN parameter for PERMUTE mode');
                        return
                end 
                
            else
                disp('IMBLEND: unknown blend mode');
                return
            end
            
    end

    R(isnan(R))=1;
    R=min(R,1); 
    R=max(R,0);
    outpict(:,:,:,f)=bgmax*(opacity*R + I*(1-opacity));
end

outpict=cast(outpict,inclassBG);

return