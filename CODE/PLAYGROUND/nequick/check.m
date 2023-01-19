function seas = check(month)

if ismember(month, [1,2,11,12])
               seas = -1;
elseif ismember(month, [3,4,9,10])
               seas = 0;
elseif ismember(month, [5,6,7,8])
               seas = 1;
else
               print('ValueError(Month must be an integer between 1 and 12')
                             
end