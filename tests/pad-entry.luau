local Geometry=require('../src/shared/PadGeometry')
local Config=require('../src/shared/Config')
local function entry(x,z,vx,vz,y)
    return Geometry.entryPosition(Config,'Buy',{x=x,y=y or 0,z=z},{x=vx,y=0,z=vz},'1')
end
local edge=Config.BuyPads['1']+5.35
local z=Config.BuyZ
local moved=entry(edge+1,z,-16/Config.PlotScale,0)
assert(Geometry.contains(Config,'Buy',moved,'1'),'Approaching edge replication lag should reconcile immediately')
assert(moved.x==edge,'Reconciliation only reaches nearest surface edge')
-- Actual Studio walks: client entered the pad while the server foot was still
-- around Z59.4 / Z60.5. Normal 16-stud walking must cover that replication gap.
for _,sample in {{'5',22.095,59.383},{'10',-22,60.464}} do
    local reconciled=Geometry.entryPosition(Config,'Buy',{x=sample[2],y=0,z=sample[3]},
        {x=0,y=0,z=16/Config.PlotScale},sample[1])
    assert(Geometry.contains(Config,'Buy',reconciled,sample[1]),'Measured walk entry must succeed without a TooFar retry')
end
local maxReach=4/Config.PlotScale
assert(Geometry.contains(Config,'Buy',entry(edge+maxReach-1e-6,z,-1000,0),'1'),'Fast movement can reach the bounded four-stud edge')
assert(not Geometry.contains(Config,'Buy',entry(edge+2,z,-4,0),'1'),'Slow movement only receives a quarter-second of travel')
for _,sample in {{edge+maxReach+.01,z,-1000,0,0},{edge+1,z,16,0,0},{edge+1,z,0,16,0},{edge+1,z,0,0,0},{edge+1,z,-1000,0,8},{edge+1,z,-1000,0,-1}} do
    local pos=entry(table.unpack(sample))
    assert(not Geometry.contains(Config,'Buy',pos,'1'),'Far, stationary, sideways, outgoing or airborne requests cannot extend pad access')
end
local inside={x=Config.BuyPads['1'],y=0,z=z}
assert(Geometry.entryPosition(Config,'Buy',inside,{x=0,y=0,z=0},'1')==inside)
assert(Geometry.entryPosition(Config,'Rebirth',inside,{x=1000,y=0,z=0})==inside)
assert(Geometry.entryPosition(Config,'Buy',inside,{x=1000,y=0,z=0},'invalid')==inside)
print('PASS server-observed inward edge reconciliation, bounded distance and unchanged unrelated requests')
