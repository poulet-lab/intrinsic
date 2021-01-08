function out = cmean(m1,m2,n1,n2)
% CMEAN  Combine means.
%   CMEAN(M1,M2,N1,N2) returns the combined mean for two sets of data with
%   individual means M1 and M2, and numbers of elements N1 and N2. Also
%   works with arrays (as long as they have identical dimensions).
%
% (c) 2016 Florian Rau

% Validate input arguments
if ~isequal(size(m1),size(m2))
    error('Expected M1 and M2 to be of equal size.')
end
validateattributes(m1,{'numeric'},{'nonnan'},'','M1')
validateattributes(m2,{'numeric'},{'nonnan'},'','M1')
validateattributes(n1,{'numeric'},{'scalar','nonnan','positive','integer'},'','N1')
validateattributes(n2,{'numeric'},{'scalar','nonnan','positive','integer'},'','N2')

% Compute output
out = (n1.*m1 + n2.*m2) ./ (n1 + n2);
