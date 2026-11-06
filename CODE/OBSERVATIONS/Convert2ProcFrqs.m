function corr_ = Convert2ProcFrqs(settings, j, corr, f1, f2, f3, corr_)
% This function converts a specific correction from the raw frequencies to
% the processed frequency, for example, of the ionosphere-free linear
% combination.
%
% INPUT:
%   settings        struct, processing settings from GUI
%   j               indices of processed frequencies
%   corr            correction on the raw frequencies
%   f1, f2, f3      raw signal frequencies
%   corr_           initialized vector
% OUTPUT:
%	corr_           correction converted to the processed signal frequency
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


switch settings.IONO.model

    case '2-Frequency-IF-LCs'
        [k1, k2] = coeff_2IF(f1, f2);
        corr_(1) = k1.*corr(j(1)) + k2.*corr(j(2));
        if settings.INPUT.proc_freqs == 2 && numel(j) >= 3
            % 2nd IF-LC only if 3rd frequency is processed for this GNSS
            [k3, k4] = coeff_2IF(f2, f3);
            corr_(2) = k3.*corr(j(2)) + k4.*corr(j(3));
        end

    case '3-Frequency-IF-LC'
        [e1, e2, e3] = coeff_3IF(f1, f2, f3);   % coefficients of 3-Frequency-IF-LC
        corr_(1) = e1.*corr(j(1)) + e2.*corr(j(2)) + e3.*corr(j(3));

    otherwise        % uncombined signals are processed (no linear combination)
        corr_(1:numel(j)) = corr(j);
        
end