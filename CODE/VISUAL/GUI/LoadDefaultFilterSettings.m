function handles = LoadDefaultFilterSettings(handles)
% Function to load default filter settings into GUI. These values are
% usually suitable for geodetic GNSS equpiment and static applications. 
% However, they might be  optimized depending on the specific case or the 
% use of low-cost devices (e.g., smartphones)
%
% INPUT:
%   handles         from GUI
% OUTPUT:
%   handles         manipulated, for GUI
%
% Revision
%   2024/12/19, MFWG: adding distinction for decoupled clock model
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% check filter settings
value = get(handles.popupmenu_filter, 'Value');
string_all = get(handles.popupmenu_filter, 'String');
filter_type = string_all{value};		% 'No Filter' or 'Kalman Filter' or 'Kalman Filter Iterative'

% check selected ionosphere model
decoupled_clock_model = contains(handles.buttongroup_models_ionosphere.SelectedObject.String, 'Estimate, decoupled clock');

% Standard deviation of observations
handles.edit_Std_CA_Code.String = sprintf('%.3f', F.std_code);
handles.edit_Std_Phase.String = sprintf('%.3f', F.std_phase);
handles.edit_Std_Iono.String = sprintf('%.3f', F.std_iono);

% GNSS Weights
handles.edit_weight_GPS.String = sprintf('%.2f', F.weight_GPS);
handles.edit_weight_GLO.String = sprintf('%.2f', F.weight_GLO);
handles.edit_weight_GAL.String = sprintf('%.2f', F.weight_GAL);
handles.edit_weight_BDS.String = sprintf('%.2f', F.weight_BDS);
handles.edit_weight_QZSS.String = sprintf('%.2f', F.weight_QZSS);

if strcmp(filter_type, 'Kalman Filter Iterative')
    % coordinates
    handles.edit_filter_coord_sigma0.String = sprintf('%.0f', F.KFI_coord_std);
    handles.edit_filter_coord_Q.String = num2str(F.KFI_coord_noise);
    handles.popupmenu_filter_coord_dynmodel.Value = F.KFI_coord_model + 1;
    
    % zwd
    handles.edit_filter_zwd_sigma0.String = num2str(F.KFI_zwd_std);
    handles.edit_filter_zwd_Q.String = num2str(F.KFI_zwd_noise);
    handles.popupmenu_filter_zwd_dynmodel.Value = F.KFI_zwd_model + 1;
    
    % receiver clocks
    % - GPS
    handles.edit_filter_rec_clock_sigma0.String = sprintf('%.0f', F.KFI_clk_std);
    handles.edit_filter_rec_clock_Q.String = sprintf('%.0f', F.KFI_clk_noise);
    handles.popupmenu_filter_rec_clock_dynmodel.Value = F.KFI_clk_model + 1;
    % - Glonass
    handles.edit_filter_glonass_offset_sigma0.String = sprintf('%.0f', F.KFI_clk_std);
    handles.edit_filter_glonass_offset_Q.String = sprintf('%.0f', F.KFI_clk_noise);
    handles.popupmenu_filter_glonass_offset_dynmodel.Value = F.KFI_clk_model + 1;
    % - Galileo
    handles.edit_filter_galileo_offset_sigma0.String = sprintf('%.0f', F.KFI_clk_std);
    handles.edit_filter_galileo_offset_Q.String = sprintf('%.0f', F.KFI_clk_noise);
    handles.popupmenu_filter_galileo_offset_dynmodel.Value = F.KFI_clk_model + 1;
    % - BeiDou
    handles.edit_filter_beidou_offset_sigma0.String = sprintf('%.0f', F.KFI_clk_std);
    handles.edit_filter_beidou_offset_Q.String = sprintf('%.0f', F.KFI_clk_noise);
    handles.popupmenu_filter_beidou_offset_dynmodel.Value = F.KFI_clk_model + 1;
    % - QZSS
    handles.edit_filter_qzss_offset_sigma0.String = sprintf('%.0f', F.KFI_clk_std);
    handles.edit_filter_qzss_offset_Q.String = sprintf('%.0f', F.KFI_clk_noise);
    handles.popupmenu_filter_qzss_offset_dynmodel.Value = F.KFI_clk_model + 1;
    
    % receiver biases
    if ~decoupled_clock_model
        handles.edit_filter_dcbs_sigma0.String = num2str(F.KFI_dcb_std);
        handles.edit_filter_dcbs_Q.String = num2str(F.KFI_dcb_noise);
    else
        handles.edit_filter_dcbs_sigma0.String = num2str(F.KFI_dcb_std_dcm);
        handles.edit_filter_dcbs_Q.String = num2str(F.KFI_dcb_noise_dcm);
    end
    handles.popupmenu_filter_dcbs_dynmodel.Value = F.KFI_dcb_model + 1;
    
    % float ambiguities
    if ~decoupled_clock_model
        handles.edit_filter_ambiguities_sigma0.String = num2str(F.KFI_amb_std);
        handles.edit_filter_ambiguities_Q.String = num2str(F.KFI_amb_noise);
    else
        handles.edit_filter_ambiguities_sigma0.String = num2str(F.KFI_amb_std_dcm);
        handles.edit_filter_ambiguities_Q.String = num2str(F.KFI_amb_noise_dcm);
    end
    handles.popupmenu_filter_ambiguities_dynmodel.Value = F.KFI_amb_model + 1;
    
    % ionospheric delay
    if ~decoupled_clock_model
        handles.edit_filter_iono_sigma0.String = num2str(F.KFI_iono_std);
        handles.edit_filter_iono_Q.String = num2str(F.KFI_iono_noise);
    else
        handles.edit_filter_iono_sigma0.String = num2str(F.KFI_iono_std_dcm);
        handles.edit_filter_iono_Q.String = num2str(F.KFI_iono_noise_dcm);
    end
    handles.popupmenu_filter_iono_dynmodel.Value = F.KFI_iono_model + 1;
    
elseif strcmp(filter_type, 'Kalman Filter')
    % coordinates
    handles.edit_filter_coord_sigma0.String = num2str(F.K_coord_std);
    handles.edit_filter_coord_Q.String = num2str(F.K_coord_noise);
    handles.popupmenu_filter_coord_dynmodel.Value = F.K_coord_model + 1;
    
    % zwd
    handles.edit_filter_zwd_sigma0.String = num2str(F.K_zwd_std);
    handles.edit_filter_zwd_Q.String = num2str(F.K_zwd_noise);
    handles.popupmenu_filter_zwd_dynmodel.Value = F.K_zwd_model + 1;
    
    % receiver clocks
    % - GPS
    handles.edit_filter_rec_clock_sigma0.String = sprintf('%.0f', F.K_clk_std);
    handles.edit_filter_rec_clock_Q.String = sprintf('%.0f', F.K_clk_noise);
    handles.popupmenu_filter_rec_clock_dynmodel.Value = F.K_clk_model + 1;
    % - Glonass
    handles.edit_filter_glonass_offset_sigma0.String = sprintf('%.0f', F.K_clk_offset_std);
    handles.edit_filter_glonass_offset_Q.String = sprintf('%.0f', F.K_clk_offset_noise);
    handles.popupmenu_filter_glonass_offset_dynmodel.Value = F.K_clk_offset_model + 1;
    % - Galileo
    handles.edit_filter_galileo_offset_sigma0.String = sprintf('%.0f', F.K_clk_offset_std);
    handles.edit_filter_galileo_offset_Q.String = sprintf('%.0f', F.K_clk_offset_noise);
    handles.popupmenu_filter_galileo_offset_dynmodel.Value = F.K_clk_offset_model + 1;
    % - BeiDou
    handles.edit_filter_beidou_offset_sigma0.String = sprintf('%.0f', F.K_clk_offset_std);
    handles.edit_filter_beidou_offset_Q.String = sprintf('%.0f', F.K_clk_offset_noise);
    handles.popupmenu_filter_beidou_offset_dynmodel.Value = F.K_clk_offset_model + 1;
    % - QZSS
    handles.edit_filter_qzss_offset_sigma0.String = sprintf('%.0f', F.K_clk_offset_std);
    handles.edit_filter_qzss_offset_Q.String = sprintf('%.0f', F.K_clk_offset_noise);
    handles.popupmenu_filter_qzss_offset_dynmodel.Value = F.K_clk_offset_model + 1;
    
    % receiver biases
    if ~decoupled_clock_model
        handles.edit_filter_dcbs_sigma0.String = num2str(F.K_dcb_std);
        handles.edit_filter_dcbs_Q.String = num2str(F.K_dcb_noise);
    else
        handles.edit_filter_dcbs_sigma0.String = num2str(F.K_dcb_std_dcm);
        handles.edit_filter_dcbs_Q.String = num2str(F.K_dcb_noise_dcm);
    end
    handles.popupmenu_filter_dcbs_dynmodel.Value = F.K_dcb_model + 1;
    
    % float ambiguities
    if ~decoupled_clock_model
        handles.edit_filter_ambiguities_sigma0.String = num2str(F.K_amb_std);
        handles.edit_filter_ambiguities_Q.String = num2str(F.K_amb_noise);
    else
        handles.edit_filter_ambiguities_sigma0.String = num2str(F.K_amb_std_dcm);
        handles.edit_filter_ambiguities_Q.String = num2str(F.K_amb_noise_dcm);
    end
    handles.popupmenu_filter_ambiguities_dynmodel.Value = F.K_amb_model + 1;
    
    % ionospheric delay
    if ~decoupled_clock_model
        handles.edit_filter_iono_sigma0.String = num2str(F.K_iono_std);
        handles.edit_filter_iono_Q.String = num2str(F.K_iono_noise);
    else
        handles.edit_filter_iono_sigma0.String = num2str(F.K_iono_std_dcm);
        handles.edit_filter_iono_Q.String = num2str(F.K_iono_noise_dcm);
    end
    handles.popupmenu_filter_iono_dynmodel.Value = F.K_iono_model_dcm + 1;
    
    
end