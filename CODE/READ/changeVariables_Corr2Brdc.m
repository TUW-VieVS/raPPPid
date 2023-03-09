function input = changeVariables_Corr2Brdc(settings, input)
% This function changes the variables of the stream corrections to the
% broadcast message. It is only necessary saved read-in files from recorded
% correction streams where the old read-in function was used.
% time-stamps are all the same, so it makes no sense to save them all seperately
%
% INPUT:
%   settings
%	input
% OUTPUT:
%	input
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% initialize fields, instead of time-vectors of all GNSS (which should be
% identical), only one time-vector for one correction type is kept
input.ORBCLK.corr2brdc.t_orb   = [];
input.ORBCLK.corr2brdc.t_clk   = [];


%% GPS
if settings.INPUT.use_GPS
    if isempty(input.ORBCLK.corr2brdc.t_orb)
        input.ORBCLK.corr2brdc.t_orb   = input.ORBCLK.corr2brdc_GPS.t_orb;
        input.ORBCLK.corr2brdc.t_clk   = input.ORBCLK.corr2brdc_GPS.t_clk;
        input.ORBCLK.corr2brdc_GPS = rmfield(input.ORBCLK.corr2brdc_GPS,'t_orb');
        input.ORBCLK.corr2brdc_GPS = rmfield(input.ORBCLK.corr2brdc_GPS,'t_clk');
        try         % old saved data
            input.ORBCLK.corr2brdc.t_code  = input.ORBCLK.corr2brdc_GPS.t_dcb;
            input.ORBCLK.corr2brdc.t_phase = input.ORBCLK.corr2brdc_GPS.t_upd;
            input.ORBCLK.corr2brdc_GPS = rmfield(input.ORBCLK.corr2brdc_GPS,'t_dcb');
            input.ORBCLK.corr2brdc_GPS = rmfield(input.ORBCLK.corr2brdc_GPS,'t_upd');
        catch
            input.ORBCLK.corr2brdc.t_code  = input.ORBCLK.corr2brdc_GPS.t_code;
            input.ORBCLK.corr2brdc.t_phase  = input.ORBCLK.corr2brdc_GPS.t_phase;
        end
    end
end


%% Glonass
if settings.INPUT.use_GLO
    if isempty(input.ORBCLK.corr2brdc.t_orb)
        input.ORBCLK.corr2brdc.t_orb   = input.ORBCLK.corr2brdc_GLO.t_orb;
        input.ORBCLK.corr2brdc.t_clk   = input.ORBCLK.corr2brdc_GLO.t_clk;
        input.ORBCLK.corr2brdc_GLO = rmfield(input.ORBCLK.corr2brdc_GLO,'t_orb');
        input.ORBCLK.corr2brdc_GLO = rmfield(input.ORBCLK.corr2brdc_GLO,'t_clk');
        try         % old saved data
            input.ORBCLK.corr2brdc.t_code  = input.ORBCLK.corr2brdc_GLO.t_dcb;
            input.ORBCLK.corr2brdc.t_phase = input.ORBCLK.corr2brdc_GLO.t_upd;
            input.ORBCLK.corr2brdc_GLO = rmfield(input.ORBCLK.corr2brdc_GLO,'t_dcb');
            input.ORBCLK.corr2brdc_GLO = rmfield(input.ORBCLK.corr2brdc_GLO,'t_upd');
        catch
            input.ORBCLK.corr2brdc.t_code  = input.ORBCLK.corr2brdc_GLO.t_code;
            input.ORBCLK.corr2brdc.t_phase  = input.ORBCLK.corr2brdc_GLO.t_phase;
        end
    end
end


%% Galileo
if settings.INPUT.use_GAL
    if isempty(input.ORBCLK.corr2brdc.t_orb)
        input.ORBCLK.corr2brdc.t_orb   = input.ORBCLK.corr2brdc_GAL.t_orb;
        input.ORBCLK.corr2brdc.t_clk   = input.ORBCLK.corr2brdc_GAL.t_clk;
        input.ORBCLK.corr2brdc_GAL = rmfield(input.ORBCLK.corr2brdc_GAL,'t_orb');
        input.ORBCLK.corr2brdc_GAL = rmfield(input.ORBCLK.corr2brdc_GAL,'t_clk');
        try         % old saved data
            input.ORBCLK.corr2brdc.t_code  = input.ORBCLK.corr2brdc_GAL.t_dcb;
            input.ORBCLK.corr2brdc.t_phase = input.ORBCLK.corr2brdc_GAL.t_upd;
            input.ORBCLK.corr2brdc_GAL = rmfield(input.ORBCLK.corr2brdc_GAL,'t_dcb');
            input.ORBCLK.corr2brdc_GAL = rmfield(input.ORBCLK.corr2brdc_GAL,'t_upd');
        catch
            input.ORBCLK.corr2brdc.t_code  = input.ORBCLK.corr2brdc_GAL.t_code;
            input.ORBCLK.corr2brdc.t_phase  = input.ORBCLK.corr2brdc_GAL.t_phase;
        end
    end
end


%% BeiDou
if settings.INPUT.use_BDS
    if isempty(input.ORBCLK.corr2brdc.t_orb)
        input.ORBCLK.corr2brdc.t_orb   = input.ORBCLK.corr2brdc_BDS.t_orb;
        input.ORBCLK.corr2brdc.t_clk   = input.ORBCLK.corr2brdc_BDS.t_clk;
        input.ORBCLK.corr2brdc_BDS = rmfield(input.ORBCLK.corr2brdc_BDS,'t_orb');
        input.ORBCLK.corr2brdc_BDS = rmfield(input.ORBCLK.corr2brdc_BDS,'t_clk');
        try         % old saved data
            input.ORBCLK.corr2brdc.t_code  = input.ORBCLK.corr2brdc_BDS.t_dcb;
            input.ORBCLK.corr2brdc.t_phase = input.ORBCLK.corr2brdc_BDS.t_upd;
            input.ORBCLK.corr2brdc_BDS = rmfield(input.ORBCLK.corr2brdc_BDS,'t_dcb');
            input.ORBCLK.corr2brdc_BDS = rmfield(input.ORBCLK.corr2brdc_BDS,'t_upd');
        catch
            input.ORBCLK.corr2brdc.t_code  = input.ORBCLK.corr2brdc_BDS.t_code;
            input.ORBCLK.corr2brdc.t_phase  = input.ORBCLK.corr2brdc_BDS.t_phase;
        end
    end
end




