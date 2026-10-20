--!strict
-- Original adaptation, not measured Chicken Farm reward/cooldown values.
-- Coordinates are unscaled hub-space FOOT positions at each platform's top.
local checkpoints={}
for index=1,10 do
    table.insert(checkpoints,table.freeze({
        x=math.cos(index*.7)*14,y=index*3+.5,z=math.sin(index*.7)*14,
        halfX=2.5,halfZ=2.5,
    }))
end
return table.freeze({
    Checkpoints=table.freeze(checkpoints),
    Finish=table.freeze({x=math.cos(7.7)*14,y=33.5,z=math.sin(7.7)*14,halfX=4.5,halfZ=4.5}),
    BonusHundredths=25, -- Add +0.25x Mini production to the world event; passes apply afterward.
    BoostSeconds=300,
    CooldownSeconds=600, -- Starts when the server awards the completed run.
    LandingHoldSeconds=.1,
    MinimumCheckpointSeconds=.25,
    MinimumJumpRise=.75,
    FootBelowTolerance=.25,
    FootAboveTolerance=.35,
    FootEdgeTolerance=.05,
    FallBelowCheckpoint=2,
    MaximumHorizontalSpeed=40, -- Normal/sprint speeds are 16/24; allow replication jitter.
    MaximumVerticalSpeed=90,
    MovementSlack=1.25,
    MaximumObservationGap=2,
    MaximumRunSeconds=120,
    Bounds=table.freeze({minX=-24,maxX=24,minY=-4,maxY=44,minZ=-24,maxZ=24}),
    MaximumCoordinate=100000,
    MaximumTimestamp=1e12,
})
