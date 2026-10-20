local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local core=Core.new(Config,Catalog)
local preciseConfig=table.clone(Config);preciseConfig.PickupRadius=.01
local preciseCore=Core.new(preciseConfig,Catalog)
local function session()
    local s=core:newSession(1,0,'airborne')
    s.state.tokens={{id='mini',owner=1,origin='producer',speciesId='tier_01',baseCoinValue=2,
        x=0,y=1.3,z=Config.TrayZ,startX=29.25,startY=30,startZ=Config.DisplayZ,spawnedAt=10,readyAt=14}}
    return s
end
local function at(s,action,id,now,x,y,z,engine)
    return (engine or core):dispatch(s,action,{id},{alive=true,now=now,position={x=x,y=y,z=z},pickupPosition={x=x,y=y,z=z}})
end
-- Catch at the producer immediately; the landing location is over 40 logical studs away.
for _,action in {'CollectNearby','Collect'} do
    local s=session()
    assert(at(s,action,if action=='Collect' then 'mini' else 'spawn',10,29.25,30,Config.DisplayZ).code=='OK','Newly spawned Mini must be collectible beside its producer')
    assert(#s.state.tokens==0 and s.state.bag[1].count==1)
end
-- Halfway through falling, the animation has traversed one quarter of its fall.
local dropY=1.4+29.25*.032
local falling=session()
assert(at(falling,'CollectNearby','fall',10+.11*4,29.25,30+(dropY-30)*.25,Config.DisplayZ+(Config.BeltZ-Config.DisplayZ)*.25,preciseCore).code=='OK')
-- Sliding halfway along the red lane is also eligible before the tray is reached.
local sliding=session()
assert(at(sliding,'CollectNearby','slide',10+(.22+.55/2)*4,29.25/2,(dropY+.75)/2,Config.BeltZ,preciseCore).code=='OK')
local arc=session()
assert(at(arc,'CollectNearby','arc',10+(.77+.23/2)*4,0,(.75+1.3)/2+3,(Config.BeltZ+Config.TrayZ)/2,preciseCore).code=='OK')
for _,action in {'CollectNearby','Collect'} do
    local s=session()
    local result=at(s,action,if action=='Collect' then 'mini' else 'remote',10,0,1.3,Config.TrayZ)
    assert(result.code==(if action=='Collect' then 'TooFar' else 'NothingNearby'),'A remote tray location must not collect an airborne Mini')
    assert(#s.state.tokens==1)
    result=at(s,action,if action=='Collect' then 'mini' else 'future',9.99,29.25,30,Config.DisplayZ)
    assert(result.code~='OK' and #s.state.tokens==1,'Future-spawned Minis must not be collectible')
end
local boundary=session()
assert(at(boundary,'CollectNearby','outside',10,29.25+Config.PickupRadius+.01,30,Config.DisplayZ).code=='NothingNearby')
assert(at(boundary,'CollectNearby','edge',10,29.25+Config.PickupRadius,30,Config.DisplayZ).code=='OK','Airborne pickup must retain the inclusive spherical boundary')
print('PASS pickup at spawn, fall, slide and arc; remote landing and future-spawn rejection; airborne sphere boundary')
