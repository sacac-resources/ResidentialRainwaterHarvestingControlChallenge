function [MWspec,BWspec] = Controller(L,AMW,ABW,HU,GU)
% Notes:
% AMW, ABW, HU, GU refering to previous time step values

% Set relevant model parameters -------------------------------------------
MWmax = 0.18;
BWmax = 0.1;
Lmax = 2.155;
Lmin = 0;

%% Set setpoint -----------------------------------------------------------
% Emptier tank
% Lsp = 0.2*Lmax;
% Half-full tank
% Lsp = 0.5*Lmax;
% Fuller tank
Lsp = 0.8*Lmax;

%% Very simple controller -------------------------------------------------
% If level too low: If AMW==1; MW = MWmax; Else BW = BWmax
if L(1) < Lsp % fill to set point
    if AMW(1)==1
        MWspec = MWmax;
        BWspec = 0;
    else
        MWspec = 0;
        BWspec = BWmax;
    end
else % don't consume more MW or BW
    MWspec = 0;
    BWspec = 0;
end
