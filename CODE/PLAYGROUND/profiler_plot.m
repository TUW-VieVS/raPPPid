profile on -detail builtin -timestamp;

% CALL FUNCTION (e.g., PPP_calc(settings) or merge_rinex())

% PPP_calc(settings)

profile off;
profData = profile('info');         % get profiler data as struct
% profview(0,profData);
histData = profData.FunctionHistory;
startTime = histData(3,1) + histData(4,1)/1e6;
relativeTimes = histData(3,:) + histData(4,:)/1e6 - startTime;

figure
plot(relativeTimes);
xlabel('Function calls')
ylabel('Time from profiling start (s)')