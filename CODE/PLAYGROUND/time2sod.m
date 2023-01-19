function sod = time2sod(time)
% time....vector, [hour minute second]

h = time(1);
m = time(2);
s = time(3);

sod = s + m*60 + h*3600;

end


