function [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
    vis_removeGNSS(AZ, EL, SNR, C_res, P_res, I_res, MP, isGPS, isGLO, isGAL, isBDS, isQZSS)
% replace zeros with NaN
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

AZ(AZ==0) = NaN;
EL(EL==0) = NaN;
SNR(SNR==0) = NaN;
C_res(C_res==0) = NaN;
P_res(P_res==0) = NaN;
I_res(I_res==0) = NaN;
MP(MP==0) = NaN;

% shrink matrixes of unused GNSS
if ~isQZSS
    idx_start = 400;
    [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
        delete_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_start);
    MP = delete(MP, idx_start);
    if ~isBDS
        idx_start = 300;
        [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
            delete_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_start);
        MP = delete(MP, idx_start);
        if ~isGAL
            idx_start = 200;
            [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
                delete_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_start);
            if ~isGLO
                idx_start = 100;
                [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
                    delete_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_start);
            end
        end
    end
end

% overwrite values of unused GNSS
if ~isGPS
    idx_S = 1;      idx_E = 99;
    [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
        overwrite_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_S, idx_E);
end
if ~isGLO
    idx_S = 101;    idx_E = 199;
    [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
        overwrite_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_S, idx_E);
end
if ~isGAL
    idx_S = 201;    idx_E = 299;
    [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
        overwrite_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_S, idx_E);
end
if ~isBDS
    idx_S = 301;    idx_E = 399;
    [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
        overwrite_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_S, idx_E);
end
if ~isQZSS
    idx_S = 401;    idx_E = 410;
    [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
        overwrite_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_S, idx_E);
end



function [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
    overwrite_all(AZ, EL, SNR, C_res, P_res, I_res, MP, from, to)
AZ = overwrite(AZ, from, to);
EL = overwrite(EL, from, to);
SNR = overwrite(SNR, from, to);
C_res = overwrite(C_res, from, to);
P_res = overwrite(P_res, from, to);
I_res = overwrite(I_res, from, to);
MP = overwrite(MP, from, to);

function M = overwrite(M, from, to)
if to > size(M,2)
    to = size(M,2);
end
M(:,from:to) = NaN;



function [AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
    delete_all(AZ, EL, SNR, C_res, P_res, I_res, MP, idx_start)
AZ = delete(AZ, idx_start);
EL = delete(EL, idx_start);
SNR = delete(SNR, idx_start);
C_res = delete(C_res, idx_start);
P_res = delete(P_res, idx_start);
I_res = delete(I_res, idx_start);
MP = delete(MP, idx_start);

function M = delete(M, from)
M(:,from:end) = [];

