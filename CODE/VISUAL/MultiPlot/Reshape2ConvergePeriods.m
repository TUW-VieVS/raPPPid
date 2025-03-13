function [d] = Reshape2ConvergePeriods(storeData, dN, dE, dH, dZTD, ...
    reset_epochs, no_epochs, d, PlotStruct)
% This function reshapes the processing results stored in the variable
% storeData as, for example, vectors to a matrix. In this matrix each row
% corresponds to a convergence period without reset. The entries of a
% specific column have the same time passed after the last reset. 
%
% INPUT:
%	storeData       struct, saved results from processing    
%   dN              vector, North coordinate error   (all processed epochs)
%   dE              vector, East coordinate error    (all processed epochs)    
%   dH              vector, Height coordinate error  (all processed epochs)
%   dZTD            vector, Zenith Total Delay error (all processed epochs)
%   reset_epochs    vector, North coordinate error of current processing
%   no_epochs       total number of epochs of current processing 
%   d               struct, collecting all convergence periods
%   PlotStruct      struct, settings for Multi Plots
% 
% OUTPUT:
%	d               struct, updated with new convergence periods
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% number of resets of current processing
no_resets = numel(reset_epochs);

% determine the number of epochs between two resets
eps_reset = no_epochs;
if numel(reset_epochs) > 1
    eps_reset = mode(diff(reset_epochs));
end


% convert vectors to matrices where each convergence period is a row
if eps_reset*no_resets == no_epochs && no_resets~=1 && eps_reset == size(d.dT,2)
    % this does work only if all convergence periods have the same
    % amount of epochs (previous and current processing(s))
    d.dT      = [  d.dT; reshape(storeData.dt_last_reset, eps_reset, no_resets)'];
    d.Time    = [d.Time; reshape(storeData.gpstime,       eps_reset, no_resets)'];
    d.N     = [ d.N; reshape(dN, eps_reset, no_resets)'];
    d.E     = [ d.E; reshape(dE, eps_reset, no_resets)'];
    d.H     = [ d.H; reshape(dH, eps_reset, no_resets)'];
    if PlotStruct.tropo
        d.ZTD   = [ d.ZTD; reshape(dZTD, eps_reset, no_resets)'];
    end
    if PlotStruct.fixed
        d.FIXED = [ d.FIXED; reshape(storeData.fixed, eps_reset, no_resets)'];
    end
    
elseif no_resets==1
    d.dT  (end+1,1:no_epochs) = storeData.dt_last_reset;
    d.Time(end+1,1:no_epochs) = storeData.gpstime;
    d.N( end+1,1:no_epochs) = dN;
    d.E( end+1,1:no_epochs) = dE;
    d.H( end+1,1:no_epochs) = dH;
    if PlotStruct.tropo
        d.ZTD( end+1,1:no_epochs) = dZTD;
    end
    if PlotStruct.fixed
        d.FIXED(end+1,1:no_epochs) = storeData.fixed;
    end
    
else
    % not all convergence periods have the same amount of epochs,
    % preapre and extend save variables for new convergence periods
    [old_rows, old_cols] = size(d.dT);
    d.dT     = extend_variable(d.dT,      old_rows, old_cols, no_resets, eps_reset);
    d.Time   = extend_variable(d.Time,    old_rows, old_cols, no_resets, eps_reset);
    d.N    = extend_variable(d.N,     old_rows, old_cols, no_resets, eps_reset);
    d.E    = extend_variable(d.E,     old_rows, old_cols, no_resets, eps_reset);
    d.H    = extend_variable(d.H,     old_rows, old_cols, no_resets, eps_reset);
    if PlotStruct.tropo
        d.ZTD  = extend_variable(d.ZTD,   old_rows, old_cols, no_resets, eps_reset);
    end
    if PlotStruct.fixed
        d.FIXED   = extend_variable(d.FIXED,       old_rows, old_cols, no_resets, eps_reset);
    end
    k = old_rows + 1;       % row to save convergence periods
    for iii = 1:no_resets   % loop over resets to put the convergence periods into matrices
        if no_resets ~= 1
            switch iii      % switch type of reset
                case 1              % first reset
                    eps = 1 : (reset_epochs(iii+1))-1;
                case no_resets      % last reset
                    eps = reset_epochs(iii) : 1 : no_epochs;
                otherwise           % all other resets
                    eps = reset_epochs(iii) : 1 : (reset_epochs(iii+1)-1);
            end
        else
            eps = 1:no_epochs;
        end
        % save current convergence period
        d.dT(k,1:numel(eps))   = storeData.dt_last_reset(eps);
        d.Time(k,1:numel(eps)) = storeData.gpstime(eps);
        d.N(k,1:numel(eps))    = dN(eps);
        d.E(k,1:numel(eps))    = dE(eps);
        d.H(k,1:numel(eps))    = dH(eps);
        if PlotStruct.tropo
            d.ZTD(k,1:numel(eps))  = dZTD(eps);
        end
        if PlotStruct.fixed
            d.FIXED(k,1:numel(eps)) = storeData.fixed(eps);      % boolean, true if fixed position was achieved
        end
        k = k + 1;
    end
end





function variable = extend_variable(variable, old_rows, old_cols, new_rows, new_cols)
% Function to extend variables for new file
cols = max(old_cols, new_cols);
% build matrices
right = NaN(old_rows, cols-old_cols);
bottom = NaN(new_rows, cols);
% put matrices together
variable = [variable, right; bottom];