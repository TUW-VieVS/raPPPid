function [pathname] = uigetfile_n_dir(start_path, dialog_title)
% Pick multiple directories and/or files

import javax.swing.JFileChooser;

if nargin == 0 || isempty(start_path)       % changed following comment on download site
    start_path = pwd;
elseif numel(start_path) == 1
    if start_path == 0 % Allow a null argument.
        start_path = pwd;
    end
end

jchooser = javaObjectEDT('javax.swing.JFileChooser', start_path);

jchooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
if nargin > 1
    jchooser.setDialogTitle(dialog_title);
end

jchooser.setMultiSelectionEnabled(true);

status = jchooser.showOpenDialog([]);

if status == JFileChooser.APPROVE_OPTION
    jFile = jchooser.getSelectedFiles();
	pathname{size(jFile, 1)}=[];
    for i=1:size(jFile, 1)
		pathname{i} = char(jFile(i).getAbsolutePath);
	end
	
elseif status == JFileChooser.CANCEL_OPTION
    pathname = [];
else
    error('Error occured while picking file.');
end
