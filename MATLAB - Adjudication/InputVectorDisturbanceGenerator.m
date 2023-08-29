in.RWrates = [20/30; 2.5/30; 1.2/30; 0.3/30];
in.RWmagnitude = {[1 5],[6 15],[16 25],[26 55]};
in.RWduration = {[1 5],[1 10],[1 15],[1, 20]};

in.AMWrate = 15/(365*24);
in.AMWduration = [1 24];

in.ABWrate = 30/(365*24);
in.ABWduration = [1 10];

in.GUrate = 0.5;
in.GUduration = 1;

load HUsamples;
% Note that household use samples need to be scaled for hourly rate
in.HUsamples = HUsamples/4;

[t, RW, AMW, ABW, HUreq, GUreq] = DisturbanceGenerator(in);
plot(RW);
sum(RW)
sum(AMW)
sum(ABW)
sum(HUreq)
sum(GUreq)

save('Test4','t','ABW','AMW','GUreq','HUreq','RW');