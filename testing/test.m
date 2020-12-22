fs  = 1000;
d   = 10;
t   = (1:d*fs) / fs;

f = 1;

tmp = (sin(2*pi*f*t-.5*pi)/2+.5);
tmp2 = sinpi(2*f*t-.5)/2+.5;

plot(t,tmp)
hold all
plot(t,tmp2)



%%
t = linspace(0,3*pi)';

hold all
plot(t/pi,sin(t))
plot(t/pi,sinpi(t/pi))
plot(t/pi,squarepi(t,.25))
xlabel('t / \pi')
grid on

%%


