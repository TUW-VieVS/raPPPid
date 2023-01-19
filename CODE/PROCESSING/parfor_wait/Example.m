function Example()
%Suppose one needs to run a loop, doing the same stuff for 1000 times. 
N = 100000;
%Before the loop, we need to construct the object. 
WaitMessage = parfor_wait(N, 'Waitbar', true);
%If you want a message printed on screen...
%WaitMessage = parfor_wait(N);
%If you want a message saved in a file...
%WaitMessage = parfor_wait(N, 'FileName', 'WaitMessage.txt');
%If you want to report more frequently...
%WaitMessage = parfor_wait(N, 'ReportInterval', 1);

parfor i = 1: N
    %Also valid for "for i = 1: N"
    %Send a message to the object. 
    WaitMessage.Send;
    pause(0.002);
end

%Destroy the object. 
WaitMessage.Destroy
end