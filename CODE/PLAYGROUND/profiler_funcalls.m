profile on -history;

% CALL FUNCTION (e.g., PPP_calc(settings))

% PPP_calc(settings)

profile off;
profData = profile('info');
% profview(0,profData);         % show profiler report
history = profData.FunctionHistory;     
% 1st row: 0 = function entry, 1 = function exit
% 2nd row: index of the called function (profData.FunctionTable)
offset = cumsum(1-2*history(1,:)) - 1;      % calling depth
entryIdx = history(1,:) == 1;               % history items of function entries
funcIdx = history(2,entryIdx);              % indexes of the relevant functions
funcNames = {profData.FunctionTable(funcIdx).FunctionName};
for i = 1:length(funcNames)
    disp([repmat('  ',1,offset(i)), funcNames{i}]);
end