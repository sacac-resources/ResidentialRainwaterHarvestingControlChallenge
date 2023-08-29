function [t, RW, AMW, ABW, HUreq, GUreq] = DisturbanceGenerator(in)
% >>> Requirements
% 'HUsamples.mat' file in current directory

% >>> Generator for disturbances:
% RW = rain water addition
% AMW = municipal water availability
% ABW = borehole water availability
% HUreq = household use required
% GUreq = garden use required

% >> Input structure:
% in.RWrates = vector; average daily rates for four types of rainfall
% e.g. in.RWrates = [20/30; 2.5/30; 1.2/30; 0.3/30];
% in.RWmagnitude = cell; magnitude intervals for four types of rainfall
% e.g. in.RWmagnitude = {[1 5],[6 15],[16 25],[26 55]};
% in.RWduration = cell; hour length intervals for four types of rainfall
% e.g. in.RWduration = {[1 5],[1 10],[1 15],[1, 20]};
% in.AMWrate = scalar; average hourly rate for municipal availability
% e.g. in.AMWrate = 15/(365*24);
% in.AMWduration = vector; duration interval for municpal availability
% e.g. in.AMWduration = [1 24];
% in.ABWrate = scalar; average hourly rate for borehole availability
% e.g. in.ABWrate = 30/(365*24);
% in.ABWduration = vector; duration interval for borehol availability
% e.g. in.ABWduration = [1 10];
% in.HUsamples = matrix; example 24 household use requirements
% in.GUrate = scalar; weekly watering rate [m^3/h]
% e.g. in.GUrate = 0.5;
% in.GUduration = scalar; number of hours per week for watering
% e.g. in.GUduration = 1;

% Generate time vector
t = (1:1:365*24)';

% >> Rainfall addition
% (inspired by Dyson, 2009)
% Allocate rainfall addition vector
RW = zeros(length(t),1);
% Allocate rainy and dry seasons (1 = rainy; 0 = dry)
RS = [ones(length(t)/4,1); zeros(length(t)/2,1); ones(length(t)/4,1)];
for ind = 1:24:(365*24)
    % Step in 24 hour increments
    if RS(ind)==1 % Rainy season
        RWrates = in.RWrates;
    else % Dry season
        RWrates = in.RWrates*0.10;
    end
    % Daily occurrence index: select rainfall type, or no rainfall
    % (empty)
    RWI = RWIndex(RWrates);
    if ~isempty(RWI) % Rainfall occured
        % Total magnitude of rainfall
        RWM = RWMag(RWI,in.RWmagnitude);
        % Rainfall distribution over 24 hours
        RWD = RWDist(RWI,in.RWduration,RWM);
        RW(ind:(ind+24-1)) = RWD;
    end
end
% Conversion from mm/h to m3/h
% Roof area: 100 m2
RW = (RW/1000)*100;

% >> Municipal water availability
% Average rate of outages
RMW = in.AMWrate;
% Lower and upper limit of outages
DMW = in.AMWduration;
% Allocate municipal water availability vector
AMW = Availability(t,RMW,DMW);

% >> Borehole water availability
% Average rate of outages
RBW = in.ABWrate;
% Lower and upper limit of outages
DBW = in.ABWduration;
% Allocate borehole water availability vector
ABW = Availability(t,RBW,DBW);

% >> Generate household use requirements
HUreq = zeros(length(t),1);
N = size(in.HUsamples,2);
for ind = 1:24:length(t)
    % Randomly select a sample
    dayInd = randi(N,1);
    % Add sample to household requirements
    HUreq(ind:(ind+24-1)) = in.HUsamples(:,dayInd)';
end

% >> Garden use generation
GUreq = zeros(length(t),1);
% Weekly garden watering
for ind = 18:24*7:length(t)
    GUreq(ind:(ind+in.GUduration-1)) = in.GUrate/in.GUduration;
end

end

% >>> Additional functions

% >>Generate daily occurence index for four types of rainfall
function RWI = RWIndex(RWrates)
% Likelihood
RWL = 1-exp(-RWrates);
% Occurence per type
RWO = RWL>rand(4,1);
% Highest rainfall type
RWI = find(RWO==1,1,'last');
end

% >> Generate daily magnitude of rainfall
function RWM = RWMag(RWI,RWmagnitude)
% Lower range
lr = RWmagnitude{RWI}(1);
% Upper range
ur = RWmagnitude{RWI}(2);
% Magnitude
RWM = (ur-lr)*rand(1,1)+lr;
end

% >> Spread daily rainfall over 24 hours
function RWD = RWDist(RWI,RWduration,RWM)
% 24 hours of possible rain
RWD = zeros(24,1);
% Lower range
lr = RWduration{RWI}(1);
% Upper range
ur = RWduration{RWI}(2);
% Generate duration
d = floor((ur-lr)*rand(1,1)+lr);
% Select start of rainfall
s = floor((24-d-1)*rand(1,1)+1);
% Distribute rainfall
for ind = s:(s+d-1)
    RWD(ind) = RWM/d;
end
end

% >> Availability generator
function A = Availability(t,R,D)
% t = vector, time vector
% R = scalar, average hourly rate
% D = vector, lower and upper limits of duration
% Poisson limit for availabity in next hour
APL = 1-exp(-R);
% Compare with random uniform number
AO = (APL<rand(size(t)));
% Add duration to events
A = ones(size(t));
for ind = 1:length(t)
    % Sample duration
    d = floor((D(2)-D(1))*rand(1,1)+D(1));
    % Add duration to occurences
    if and(AO(ind)==0,ind<(length(t)-d))
        A(ind:(ind+d)) = 0;
    end
end
end