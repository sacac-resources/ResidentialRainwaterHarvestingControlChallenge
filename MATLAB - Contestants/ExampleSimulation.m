%% Load example, pre-allocate vectors
load Example1;
N = 365*24;
L = zeros(N+1,1);
MWspec = zeros(N,1);
BWspec = zeros(N,1);
MW = zeros(N,1);
BW = zeros(N,1);
HU = zeros(N,1);
GU = zeros(N,1);
OF = zeros(N,1);

%% Initialize model
% Tank is halfway full
L(1:2) = 2.155/2;
% No MW or BW specified or used
MW(1) = 0;
BW(1) = 0;
MWspec(1) = 0;
BWspec(1) = 0;

%% Run model
for ind = 2:N
    % Controller inputs
    % Level
    if ind < 24
        Linput = [L(ind:-1:1); zeros(24-ind,1)];
    else
        Linput = L(ind:-1:(ind-23));
    end
    % Usage and availability
    if ind < 25
        AMWinput = [AMW((ind-1):-1:1); zeros(24-ind,1)];
        ABWinput = [ABW((ind-1):-1:1); zeros(24-ind,1)];
        HUinput = [HU((ind-1):-1:1); zeros(24-ind,1)];
        GUinput = [GU((ind-1):-1:1); zeros(24-ind,1)];
    else
        AMWinput = AMW((ind-1):-1:(ind-24));
        ABWinput = ABW((ind-1):-1:(ind-24));
        HUinput = HU((ind-1):-1:(ind-24));
        GUinput = GU((ind-1):-1:(ind-24));        
    end
    
    % Controller action
    [MWspec(ind),BWspec(ind)] = Controller(Linput,AMWinput,ABWinput,HUinput,GUinput);
    
    % Mass balance
    [L(ind+1),MW(ind),BW(ind),HU(ind),GU(ind),OF(ind)] ...
    = TanksMassBalance(L(ind),RW(ind),AMW(ind),ABW(ind),...
    MWspec(ind),BWspec(ind),HUreq(ind),GUreq(ind));
end
% Trim level vector
L(end) = [];

%% Assess performance
cMW = 25;
cBW = 60;
cHU = 150;
cGU = 70;
J = sum(cMW*MW + cBW*BW + cHU*(HUreq-HU) + cGU*(GUreq-GU));

%% Plots
% Disturbances
figure;
subplot(5,1,1), plot(RW)
ylabel('RW')
axis tight
subplot(5,1,2), plot(HUreq)
ylabel('HU_r_e_q')
axis tight
subplot(5,1,3), plot(GUreq)
ylabel('GU_r_e_q')
axis tight
subplot(5,1,4), plot(AMW)
ylabel('AMW')
axis tight
subplot(5,1,5), plot(ABW)
ylabel('ABW')
axis tight
xlabel('Time step')

% Control results
figure;
subplot(5,1,1), plot(L)
ylabel('L')
axis tight
subplot(5,1,2), plot(MW)
ylabel('MW')
axis tight
subplot(5,1,3), plot(BW)
ylabel('BW')
axis tight
subplot(5,1,4), plot(HUreq-HU)
ylabel('\DeltaHU')
axis tight
subplot(5,1,5), plot(GUreq-GU)
ylabel('\DeltaGU')
axis tight
xlabel('Time step')
