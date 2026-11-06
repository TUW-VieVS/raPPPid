function outfile = websaveChecked(filename, url, varargin)
% When a server cannot serve the requested file it often returns an HTML
% error page (e.g. a 404) with Content-Type 'text/html'. MATLAB websave 
% saves a stray file then and does not throw an error.
% This wrapper detects that situation: if websave saved to a different name
% than requested, the response was not the expected file. The stray file is
% deleted and an error is thrown.
%
% INPUT:
%   filename    string, target path/filename to save to
%   url         string, URL to download
%   varargin    optional, additional arguments passed to websave (weboptions)
% OUTPUT:
%   outfile     string, path of the saved file (equals filename on success)
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

outfile = websave(filename, url, varargin{:});

% websave changed the filename -> server returned unexpected content type
% (typically an HTML error page saved as *.html)
% compare only name and extension: websave returns an absolute path, while
% filename can be relative (e.g., Path.DATA = '../DATA/') or use other slashes
[~, name_req, ext_req] = fileparts(filename);
[~, name_out, ext_out] = fileparts(outfile);
if ~strcmp([name_out ext_out], [name_req ext_req])
    if isfile(outfile)
        delete(outfile);
    end
    error('websaveChecked:unexpectedContent', ...
        'Server returned unexpected content (not the requested file) for: %s', url);
end
