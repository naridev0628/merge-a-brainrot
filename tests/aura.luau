local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local core=Core.new(Config,Catalog,function() return 1 end)

local function session(key)
    local s=core:newSession(1,0,key)
    s.state.tokens={{id='mini',owner=1,origin='producer',speciesId='tier_01',baseCoinValue=2,
        x=0,y=1.3,z=Config.TrayZ,startX=0,startY=1.3,startZ=Config.DisplayZ-2,spawnedAt=0,readyAt=4}}
    return s
end
local function collect(s,id,x,y,z,now)
    return core:dispatch(s,'CollectNearby',{id},{alive=true,now=now or 5,position={x=x,y=y,z=z},
        pickupPosition={x=x,y=y+3/Config.PlotScale,z=z}})
end

-- Approach from ten world studs away, without stepping on a Mini.
-- These cover all approach directions instead of a privileged tray entry edge.
assert(math.abs(Config.PickupRadius*Config.PlotScale-12)<1e-8,'Pickup sphere must remain twelve world studs')
for i,offset in {{10,0},{-10,0},{0,10},{0,-10},{7,7}} do
    local s=session('approach'..i)
    local x,z=offset[1]/Config.PlotScale,Config.TrayZ+offset[2]/Config.PlotScale
    local result=collect(s,'nearby',x,0,z)
    assert(result.code=='OK','Ready Mini should collect from nearby approach '..i..': '..result.code)
    assert(result.count==1 and Economy.count(s.state.bag)==1 and #s.state.tokens==0)
    local replay=collect(s,'nearby',x,0,z)
    assert(replay.replayed and Economy.count(s.state.bag)==1,'Replaying aura must not duplicate Minis')
end

-- Reject a diagonal outside the sphere, even if each horizontal axis is within range.
local diagonal=session('diagonal')
assert(collect(diagonal,'outside',11/Config.PlotScale,0,Config.TrayZ+11/Config.PlotScale).code=='NothingNearby','Aura must be spherical, not a square')
assert(#diagonal.state.tokens==1 and #diagonal.state.bag==0)
local high=session('high')
assert(collect(high,'outside',0,26,Config.TrayZ).code=='NothingNearby','Aura must include vertical distance')
local rootCentered=session('root-centered')
assert(core:dispatch(rootCentered,'CollectNearby',{'root'},
    {alive=true,now=5,position={x=0,y=0,z=Config.TrayZ},pickupPosition={x=0,y=27,z=Config.TrayZ}}).code=='NothingNearby',
    'Aura must use actual character center independently of the foot position used by pads')
assert(core:dispatch(rootCentered,'CollectNearby',{'invalid-root'},
    {alive=true,now=5,position={x=0,y=0,z=Config.TrayZ},pickupPosition={x=0/0,y=0,z=Config.TrayZ}}).code=='NotAlive')

local transit=session('transit')
assert(collect(transit,'arriving',0,0,Config.TrayZ,3.99).code=='OK','A nearby arriving Mini is eligible before landing')
local landed=session('landed')
assert(collect(landed,'ready',10/Config.PlotScale,0,Config.TrayZ,4).code=='OK','Landing remains immediately eligible')

local foreign=session('foreign')
foreign.state.tokens[1].owner=2
assert(collect(foreign,'owner',0,0,Config.TrayZ).code=='NothingNearby','Aura cannot collect another owner\'s Mini')
assert(#foreign.state.tokens==1 and #foreign.state.bag==0)

local cappedConfig=table.clone(Config); cappedConfig.BagCap=2
local capped=Core.new(cappedConfig,Catalog)
local full=session('capacity')
full.state.bag={{speciesId='tier_01',baseCoinValue=2,count=1}}
local second=table.clone(full.state.tokens[1]); second.id='second'; table.insert(full.state.tokens,second)
local one=capped:dispatch(full,'CollectNearby',{'room'},{alive=true,now=5,position={x=10/Config.PlotScale,y=0,z=Config.TrayZ}})
assert(one.code=='OK' and one.count==1 and Economy.count(full.state.bag)==2 and #full.state.tokens==1)
assert(capped:dispatch(full,'CollectNearby',{'full'},{alive=true,now=5,position={x=0,y=0,z=Config.TrayZ}}).code=='BagFull')
assert(#full.state.tokens==1,'Full bag must leave remaining Minis in the world')
print('PASS nearby aura approaches, true sphere, landing, ownership, replay and capacity')
