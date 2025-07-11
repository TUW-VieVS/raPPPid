classdef F
% Class for default Filter settings
%  
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

    properties (Constant = true)
        
        % default settings for standard deviation of raw observations
        std_code = 0.300;
        std_phase = 0.002;
        std_iono = 0.150;
        
        % default GNSS weights
        weight_GPS = 1;
        weight_GLO = 1;
        weight_GAL = 1;
        weight_BDS = 1;
        weight_QZSS = 1;
        
        %% default settings for Kalman Filter Iterative [m]
        % coordinates
        KFI_coord_std       = 1e4;
        KFI_coord_noise     = 0;
        KFI_coord_model 	= 1;
        
        % coordinates
        KFI_velocity_std  	= 1000;
        KFI_velocity_noise 	= 10;
        KFI_velocity_model 	= 1;
        
        % zenith wet delay
        KFI_zwd_std         = 0.10;
        KFI_zwd_noise       = 0.005;
        KFI_zwd_model       = 1;
        
        % receiver clock
        KFI_clk_std         = 3e5;
        KFI_clk_noise       = 3e5;
        KFI_clk_model       = 1;
        
        % receiver biases
        KFI_dcb_std         = 3;
        KFI_dcb_noise       = 0;
        KFI_dcb_model       = 1;
        % receiver biases (decoupled clock model)
        KFI_dcb_std_dcm     = 300000;
        KFI_dcb_noise_dcm   = 300000;
       
        % float ambiguities
        KFI_amb_std         = 20;
        KFI_amb_noise       = 0;
        KFI_amb_model       = 1;
        % float ambiguities (decoupled clock model)
        KFI_amb_std_dcm     = 100;
        KFI_amb_noise_dcm   = 0;
        
        % slant ionospheric delay
        KFI_iono_std        = 1;
        KFI_iono_noise      = 1;
        KFI_iono_model      = 1;   
        % slant ionospheric delay in the decoupled clock model absorbs
        % receiver code biases -> larger values!
        KFI_iono_std_dcm     = 1000;
        KFI_iono_noise_dcm   = 1000;
        KFI_iono_model_dcm   = 1;   
        
        
        %% default settings for Kalman Filter [m]
        % coordinates
        K_coord_std         = 100;
        K_coord_noise       = 0;
        K_coord_model       = 1;
        
        % coordinates
        K_velocity_std    	= 100;
        K_velocity_noise 	= 0;
        K_velocity_model  	= 1;
        
        % zenith wet delay
        K_zwd_std           = 0.10;
        K_zwd_noise         = 0.005;
        K_zwd_model         = 1;
        
        % receiver clock
        K_clk_std           = 30000;
        K_clk_noise         = 300;
        K_clk_model         = 1;
        % receiver clock (decoupled clock model)
        K_clk_std_dcm       = 300000;
        K_clk_noise_dcm     = 300000;
        K_clk_model_dcm     = 1;
        
        % receiver clock offset from GPS to GNSS
        K_clk_offset_std    = 30;
        K_clk_offset_noise  = 5;
        K_clk_offset_model  = 1;
        % receiver clock offset from GPS to GNSS (decoupled clock model)
        K_clk_offset_std_dcm    = 300000;
        K_clk_offset_noise_dcm  = 300000;
        K_clk_offset_model_dcm  = 1;
        
        % receiver biases
        K_dcb_std           = 10;
        K_dcb_noise         = 0;
        K_dcb_model         = 1;
        % receiver biases (decoupled clock model)
        K_dcb_std_dcm       = 300000;
        K_dcb_noise_dcm     = 300000;
        K_dcb_model_dcm     = 1;
        
        % float ambiguities
        K_amb_std           = 2;
        K_amb_noise         = 0;
        K_amb_model         = 1;
        % float ambiguities (decoupled clock model)
        K_amb_std_dcm       = 100;
        K_amb_noise_dcm     = 0;
        
        % ionospheric delay
        K_iono_std          = 1;
        K_iono_noise        = 1;
        K_iono_model        = 1;      
        % ionospheric delay (decoupled clock model)
        K_iono_std_dcm       = 1000;
        K_iono_noise_dcm     = 1000;
        K_iono_model_dcm     = 1;            
    end
    
    methods (Access = public)
        
    end
end

