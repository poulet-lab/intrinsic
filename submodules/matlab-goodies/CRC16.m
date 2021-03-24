function out = CRC16(in)
% Calculate CRC-CCITT for a given input

in  = double(in);
crc = 0;
for i = 1:length(in)
    crc = bitxor(crc,bitshift(in(i),8));
    for bit = 1:8
        if bitand(crc,hex2dec('8000'))
            crc = bitxor(bitshift(crc,1),hex2dec('1021'));
        else
            crc = bitshift(crc,1);
        end
        crc = bitand(crc,hex2dec('ffff'));
    end
end
out = dec2hex(crc,4);