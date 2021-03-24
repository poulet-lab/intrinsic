function out = MD5(in)
% Calculate MD5 for a given input

hash = java.security.MessageDigest.getInstance('MD5').digest(double(in));
out  = char(java.lang.String.format('%032x',java.math.BigInteger(1,hash)));