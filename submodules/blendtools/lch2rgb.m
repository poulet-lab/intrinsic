function outpict=lch2rgb(inpict,varargin)
%   LCH2RGB(INPICT, {MODE}, {LIMIT}, {NOGC}, {WP})
%       Convert a CIELCHuv or CIELCHab image to sRGB
%       
%   INPICT is a single LCH image (of known type)
%   MODE is either 'luv' (default), or 'lab'
%   LIMIT options include:
%       'truncatergb' limits color points to RGB data ranges when in RGB
%       'truncatelch' limits color points to RGB data ranges when in LCH 
%       'notruncate' performs no data truncation (default)
%   NOGC option can be used to disable gamma correction of the output
%       this is primarily intended to be used to speed up the calculations involved
%       in checking whether points are in-gamut.  (about 30% faster)
%   WP optionally allows the selection of the white point
%       'D65' (default) 
%       'D50' uses an adapted (Bradford) sRGB-XYZ matrix
%       D50 method is not compatible with 'truncatelch' option
%
%   This code formed as an interpretation of Pascal Getreuer's COLORSPACE() and other files.

% doing chroma limiting while in LCH is the only practical way I can think of to handle OOG points
% when converting back to sRGB.  Using a wider gamut doesn't solve the fact that the projection 
% of a cube isn't rotationally symmetric.  LUV can be bound with simple line intersection calculations
% since the level curves of the RGB gamut are straight lines in LUV.
% The edges, level curves and meridians of the projection in LAB are not straight lines.  
% segregation of faces can't be done by angle alone either.  
% I'm left to offload the bisection task and use a LUT.

for k=1:length(varargin);
    switch lower(varargin{k})
        case 'notruncate'
            truncate='none';
        case 'truncatergb'
            truncate='rgb';
        case 'truncatelch'
            truncate='lch';
        case 'truncatelchcalc'
            truncate='lchcalc';
        case {'lab','luv'}
            mode=varargin{k};
        case 'nogc'
            nogc=true;
        case 'd65'
            thiswp='d65';
        case 'd50'
            thiswp='d50'; 
        otherwise
            disp(sprintf('LCH2RGB: unknown option %s',varargin{k}))
            return
    end
end

if ~exist('truncate','var')
    truncate='none';
end
if ~exist('mode','var')
    mode='luv';
end
if ~exist('nogc','var')
    nogc=false;
end
if ~exist('thiswp','var')
    thiswp='d65';
end

H=inpict(:,:,3);
C=inpict(:,:,2);
L=inpict(:,:,1);

if strcmpi(truncate,'lch')
    switch lower(mode(mode~=' '))
        case 'luv'
            Cnorm=maxchroma('luv','l',L,'h',H);
        case 'lab'
            Cnorm=maxchroma('lab','l',L,'h',H);
    end
    C=min(max(C,0),Cnorm);
end
if strcmpi(truncate,'lchcalc')
    switch lower(mode(mode~=' '))
        case 'luv'
            Cnorm=maxchroma('luvcalc','l',L,'h',H);
        case 'lab'
            Cnorm=maxchroma('labcalc','l',L,'h',H);
    end
    C=min(max(C,0),Cnorm);
end

% convert to LUV/LAB from LCH
Hrad=H*pi/180;
inpict(:,:,3)=sin(Hrad).*C; % V/B
inpict(:,:,2)=cos(Hrad).*C; % U/A

switch thiswp
    case 'd65'
        WP=[0.950470 1 1.088830];
        
        % sRGB > XYZ (D65)
        Ainv=[3.240454162114103 -1.537138512797715 -0.49853140955601; ...   
            -0.96926603050518 1.876010845446694 0.041556017530349; ...
            0.055643430959114 -0.20402591351675 1.057225188223179];
        
        % Adobe 1998
        %Ainv=[ 2.0413690 -0.5649464 -0.3446944; ...
        %    -0.9692660  1.8760108  0.0415560; ...
        %    0.0134474 -0.1183897  1.0154096];
    case 'd50'
        WP=[0.964220 1 0.825210];
        % sRGB > XYZ (D50)
        Ainv=[3.1338561 -1.6168667 -0.4906146; ...
            -0.9787684  1.9161415  0.0334540; ...
            0.0719453 -0.2289914  1.4052427];
            
        % Wide Gamut RGB
        %Ainv=[1.4628067 -0.1840623 -0.2743606; ...
        %    -0.5217933  1.4472381  0.0677227; ...
        %     0.0349342 -0.0968930  1.2884099];
end

if strcmpi(mode,'luv')
    % CIELUV to CIEXYZ
    refd=dot([1 15 3],WP);
    refU=4*WP(1)/refd;
    refV=9*WP(2)/refd;
    
    U=inpict(:,:,2);
    V=inpict(:,:,3);
    
    fY=(L+16)/116;
    Y=invf(fY);
    
    mk=(L==0);
    U=U./(13*L + 1E-6*mk) + refU;
    V=V./(13*L + 1E-6*mk) + refV;
    
    X=-(9*Y.*U)./((U-4).*V - U.*V);
    Z=(9*Y - (15*V.*Y) - (V.*X))./(3*V);
    
elseif strcmpi(mode,'lab')
    % CIELAB to CIEXYZ   
    A=inpict(:,:,2);
    B=inpict(:,:,3);
    
    fY=(L+16)/116;
    fX=fY+A/500;
    fZ=fY-B/200;
    
    X=invf(fX);
    Y=invf(fY);
    Z=invf(fZ);
    
    X=X*WP(1);
    Z=Z*WP(3);
end

% CIEXYZ to RGB
R=X*Ainv(1,1)+Y*Ainv(1,2)+Z*Ainv(1,3);
G=X*Ainv(2,1)+Y*Ainv(2,2)+Z*Ainv(2,3);
B=X*Ainv(3,1)+Y*Ainv(3,2)+Z*Ainv(3,3);

if ~nogc
    R=gammac(R);
    G=gammac(G);
    B=gammac(B);
end

if strcmpi(truncate,'rgb')
    R=min(max(R,0),1);
    G=min(max(G,0),1);
    B=min(max(B,0),1);
end

outpict=cat(3,R,G,B);

end

function out=gammac(channel)
    out=zeros(size(channel));
    mk=(channel<=0.0031306684425005883);
    out(mk)=12.92*channel(mk);
    out(~mk)=real(1.055*channel(~mk).^0.416666666666666667-0.055);
end

function Y=invf(fY)
    ep=216/24389;
    kp=24389/27;
    Y=fY.^3;
    my=(Y<ep);
    Y(my)=(116*fY(my)-16)/kp;
end

