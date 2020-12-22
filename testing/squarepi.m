function x = squarepi(t,duty)

%x = sinpi(t) >= 0;
%x = (x - .5) * 2;

    r = mod(t/(2*pi), 1);    % generate a ramp over every cycle
    x = 1 - 2*(r > duty);       % output result from -1 to 1