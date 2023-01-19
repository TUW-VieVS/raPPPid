clear all, close all, clc

% Initial data
TX = NEQTime(4,0);
TX_1 = NEQTime(4,12);
BX = GalileoBroadcast(236.831641,-0.39362878,0.00402826613);
BX_1 = GalileoBroadcast(121.129893, 0.351254133, 0.0134635348);

% Nequick objects
NEQ_global = NequickG_global(TX, BX);
NEQ_global_1 = NequickG_global(TX, BX_1);
NEQ_global_2 = NequickG_global(TX_1, BX_1);

% ray objects: containing receiver and satellite position
ray = Ray(0.07811,82.49,297.66,20281.54618,54.29,8.23);
ray_1 = Ray(-0.02332,-3.00,40.19,20671.87164,-39.04,26.31); 
ray_2 = Ray(-0.02332,-3.00,40.19,20194.16822,-4.67 ,-13.11); 

ray_3 = Ray(-0.02332,-3.00,40.19, 20081.39825, -28.26 ,90.78);

STEC = NEQ_global_2.sTEC(ray_3,0)