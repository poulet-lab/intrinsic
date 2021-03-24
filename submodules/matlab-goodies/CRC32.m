function out = CRC32(in)
% Calculate CRC32 for a given input string

crc = java.util.zip.CRC32();
crc.update(double(in))
out = dec2hex(crc.getValue(),8);