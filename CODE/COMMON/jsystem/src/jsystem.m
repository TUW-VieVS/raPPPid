function [ res, out, err ] = jsystem( cmd, shell, dir )
%JSYSTEM Execute a shell command
%   Executes a shell command as a subprocess using java's ProcessBuilder
%   class. This is much faster than using the builtin matlab 'system'
%   command.
%
%   Input arguments:
%   cmd -   A string, command to execute (with args and any shell
%           directives), e.g. 'ls -al /foo | grep bar > baz.txt'
%   shell - Optional. If specified and not empty, can be either a path of the shell to
%           invoke (e.g. '/bin/zsh') or the string 'noshell' in which case the command
%           will be run directly. In case this argument is omitted or empty,
%           defatuls to '/bin/sh -c' on linux/mac or 'cmd.exe /c' on windows.
%   dir -  Optional. Working directory for the process running the command.
%          If omitted defaults to the current matlab working
%          directory.
%
%   Output arguments:
%   res - The result code returned by the process.
%   out - The output of the process (stdout).
%   err - The stderr output of the process.
%
%   Global settings:
%   jsystem_path - Set this global variable to a cell array of paths that
%   will be prefixed to the PATH enviroment variable of the process running
%   the command. Example: global jsystem_path; jsystem_path = {'/foo', '/bar/baz'};

%% Platform-specific initialization
if (ispc)
    DEFAULT_SHELL = 'cmd.exe /c';
else
    DEFAULT_SHELL = '/bin/sh -c';
end

%% Handle input
global jsystem_path;
if (nargin == 0)
    error('No command specified');
end
if (~exist('shell', 'var') || isempty(shell))
    shell = DEFAULT_SHELL;
end
if (~exist('dir', 'var'))
    dir = pwd;
end

%% Run the command

% Create a java ProcessBuilder instance
pb = java.lang.ProcessBuilder({''});

% Set it's working directory to the current matlab dir
pb.directory(java.io.File(dir));

% Disable stderror redirection to stdout
pb.redirectErrorStream(false);

% If the user doesn't wan't to use a shell, split the command from it's
% arguments. Otherwise, prefix the shell invocation.
if (strcmpi(shell, 'noshell'))
    shellcmd = strsplit(cmd);
else
    shellcmd = [strsplit(shell), cmd];

    % Setup path for process (only relevant if using a shell)
    if (~isempty(jsystem_path) && iscellstr(jsystem_path))
        path = [strjoin(jsystem_path, pathsep()), pathsep(), char(pb.environment.get('PATH'))];
        pb.environment.put('PATH', path);
    end
end

% Set the command to run
pb.command(shellcmd);

% Start running the new process (non blocking)
process = pb.start();

%% Read output from the process

out = read_inputstream(process.getInputStream());
err = read_inputstream(process.getErrorStream());

% Get the result code from the process
res = process.waitFor();

%% Helper function: Reads a java input stream until it's end
function stream_content = read_inputstream(is)
    scanner = java.util.Scanner(is);
    scanner.useDelimiter('\A'); % '\A' is the start of input token
    if scanner.hasNext() % blocks until start of stream
        stream_content = scanner.next(); % blocks until end of stream
    else
        stream_content = '';
    end

    % Convert from java string to matlab string and trim trailing whitespace
    stream_content = strtrim(char(stream_content));
end

end
