import numpy as np

def DisturbanceGenerator(in_):
    """Generate disturbances

    >>> Requirements
    'HUsamples.mat' file in current directory

    >>> Generator for disturbances:
    RW = rain water addition
    AMW = municipal water availability
    ABW = borehole water availability
    HUreq = household use required
    GUreq = garden use required

    >> Input structure:
    in.RWrates = list average daily rates for four types of rainfall
    e.g. in.RWrates = [20/30, 2.5/30, 1.2/30, 0.3/30]
    in.RWmagnitude = list magnitude intervals for four types of rainfall
    e.g. in.RWmagnitude = [[1, 5], [6, 15], [16, 25], [26, 55]]
    in.RWduration = list hour length intervals for four types of rainfall
    e.g. in.RWduration = [[1, 5], [1, 10], [1, 15], [1, 20]]
    in.AMWrate = scalar average hourly rate for municipal availability
    e.g. in.AMWrate = 15/(365*24)
    in.AMWduration = list duration interval for municpal availability
    e.g. in.AMWduration = [1, 24]
    in.ABWrate = scalar average hourly rate for borehole availability
    e.g. in.ABWrate = 30/(365*24)
    in.ABWduration = list duration interval for borehol availability
    e.g. in.ABWduration = [1, 10]
    in.HUsamples = matrix example 24 household use requirements
    in.GUrate = scalar weekly watering rate [m^3/h]
    e.g. in.GUrate = 0.5
    in.GUduration = scalar number of hours per week for watering
    e.g. in.GUduration = 1"""

    # Generate time vector
    t = (arange(1, dot(365, 24), 1)).T
    # >> Rainfall addition
    # (inspired by Dyson, 2009)
    # Allocate rainfall addition vector
    RW = zeros(length(t), 1)
    # Allocate rainy and dry seasons (1 = rainy; 0 = dry)
    RS = concat(
        [[ones(length(t) / 4, 1)], [zeros(length(t) / 2, 1)], [ones(length(t) / 4, 1)]]
    )
    for ind in arange(1, (dot(365, 24)), 24).reshape(-1):
        # Step in 24 hour increments
        if RS(ind) == 1:
            RWrates = in_.RWrates
        else:
            RWrates = dot(in_.RWrates, 0.1)
        # Daily occurrence index: select rainfall type, or no rainfall
        # (empty)
        RWI = RWIndex(RWrates)
        if logical_not(isempty(RWI)):
            # Total magnitude of rainfall
            RWM = RWMag(RWI, in_.RWmagnitude)
            RWD = RWDist(RWI, in_.RWduration, RWM)
            RW[arange(ind, (ind + 24 - 1))] = RWD

    # Conversion from mm/h to m3/h
    # Roof area: 100 m2
    RW = dot((RW / 1000), 100)
    # >> Municipal water availability
    # Average rate of outages
    RMW = in_.AMWrate
    # Lower and upper limit of outages
    DMW = in_.AMWduration
    # Allocate municipal water availability vector
    AMW = Availability(t, RMW, DMW)
    # >> Borehole water availability
    # Average rate of outages
    RBW = in_.ABWrate
    # Lower and upper limit of outages
    DBW = in_.ABWduration
    # Allocate borehole water availability vector
    ABW = Availability(t, RBW, DBW)
    # >> Generate household use requirements
    HUreq = zeros(length(t), 1)
    N = size(in_.HUsamples, 2)
    for ind in arange(1, length(t), 24).reshape(-1):
        # Randomly select a sample
        dayInd = randi(N, 1)
        HUreq[arange(ind, (ind + 24 - 1))] = in_.HUsamples(arange(), dayInd).T

    # >> Garden use generation
    GUreq = zeros(length(t), 1)
    # Weekly garden watering
    for ind in arange(18, length(t), dot(24, 7)).reshape(-1):
        GUreq[arange(ind, (ind + in_.GUduration - 1))] = in_.GUrate / in_.GUduration

    return t, RW, AMW, ABW, HUreq, GUreq


#  Additional functions

def RWIndex(RWrates, *args, **kwargs):
    """Generate daily occurence index for four types of rainfall"""
    # Likelihood
    RWL = 1 - exp(-RWrates)
    # Occurence per type
    RWO = RWL > rand(4, 1)
    # Highest rainfall type
    RWI = find(RWO == 1, 1, "last")
    return RWI


def RWMag(RWI, RWmagnitude):
    """Generate daily magnitude of rainfall"""
    # Lower range
    lr = RWmagnitude[RWI](1)
    # Upper range
    ur = RWmagnitude[RWI](2)
    # Magnitude
    RWM = dot((ur - lr), rand(1, 1)) + lr
    return RWM


def RWDist(RWI, RWduration, RWM):
    """Spread daily rainfall over 24 hours"""
    # 24 hours of possible rain
    RWD = zeros(24, 1)
    # Lower range
    lr = RWduration[RWI](1)
    # Upper range
    ur = RWduration[RWI](2)
    # Generate duration
    d = floor(dot((ur - lr), rand(1, 1)) + lr)
    # Select start of rainfall
    s = floor(dot((24 - d - 1), rand(1, 1)) + 1)
    # Distribute rainfall
    for ind in arange(s, (s + d - 1)).reshape(-1):
        RWD[ind] = RWM / d

    return RWD


def Availability(t, R, D, *args, **kwargs):
    """Availability generator"""
    varargin = Availability.varargin
    nargin = Availability.nargin

    # t = vector, time vector
    # R = scalar, average hourly rate
    # D = vector, lower and upper limits of duration
    # Poisson limit for availabity in next hour
    APL = 1 - exp(-R)
    # Compare with random uniform number
    AO = APL < rand(size(t))
    # Add duration to events
    A = ones(size(t))
    for ind in arange(1, length(t)).reshape(-1):
        # Sample duration
        d = floor(dot((D(2) - D(1)), rand(1, 1)) + D(1))
        if and_(AO(ind) == 0, ind < (length(t) - d)):
            A[arange(ind, (ind + d))] = 0

    return A


if __name__ == "__main__":
    pass
