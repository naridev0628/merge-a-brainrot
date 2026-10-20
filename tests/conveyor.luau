local Economy=require('../src/shared/Economy')
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local core=Core.new(Config,Catalog,function() return 1 end)
local s=core:newSession(12,0,'conveyor')
local function cmd(action,args,now,x,z)
    return core:dispatch(s,action,args,{now=now,alive=true,position={x=x,y=3,z=z}})
end
assert(Config.BuyPads['1']>Config.BuyPads['5'] and Config.BuyPads['5']>Config.BuyPads['10'])
assert(core:slotPosition(1).x>core:slotPosition(10).x)
assert(cmd('Buy',{'free'},0,Config.BuyPads['1'],Config.BuyZ).code=='OK')
core:step(s,Config.Interval)
local t=s.state.tokens[1]
assert(t.startX==core:slotPosition(1).x and t.startZ>Config.BeltZ)
assert(t.readyAt==Config.Interval+Config.TransitSeconds)
assert(math.abs(t.x)<=10.31+1e-8 and math.abs(t.z-Config.TrayZ)<=5.385+1e-8)
assert(cmd('Collect',{t.id},Config.Interval,t.x,t.z).code=='TooFar','Pickup must use the airborne location rather than the remote tray target')
assert(Economy.count(s.state.bag)==0 and #s.state.tokens==1)
assert(cmd('Collect',{t.id},Config.Interval,t.startX,t.startZ).code=='OK','New Mini is collectible immediately at its producer')
assert(Economy.count(s.state.bag)==1)
core:setPasses(s,{autoCollect=true})
local nextDrop=t.readyAt+Config.Interval
s.state.producers[1].due=nextDrop
core:step(s,nextDrop)
assert(#s.state.tokens==1,'Auto Collect must wait for the conveyor')
local arrivingId=s.state.tokens[1].id
core:step(s,nextDrop+Config.TransitSeconds)
for _,mini in s.state.tokens do assert(mini.id~=arrivingId,'Arrived Mini must be collected while newer Minis remain in transit') end
assert(#s.state.saleQueue>0)
print('PASS conveyor ordering, tray bounds, immediate producer pickup, remote-target rejection and automation arrival gate')

-- A full tray must never reuse the same resting place, and collecting the
-- bottom of the pile must compact the survivors into supported lower slots.
local pile=core:newSession(13,0,'pile')
pile.state.coinUnits=1000000; pile.state.rebirths=3
local buyContext={now=0,alive=true,position={x=Config.BuyPads['1'],y=3,z=Config.BuyZ}}
assert(core:dispatch(pile,'Buy',{'starter'},buyContext).code=='OK')
buyContext.position.x=Config.BuyPads['50']
assert(core:dispatch(pile,'Buy',{'full','50'},buyContext).code=='OK')
for index,producer in pile.state.producers do producer.speciesId=string.format('tier_%02d',(index-1)%6+1) end
local fillCycles=math.ceil(Config.GroundCap/#pile.state.producers)
for cycle=1,fillCycles do core:step(pile,cycle*Config.Interval) end
assert(#pile.state.tokens==Config.GroundCap,'Full-pile coverage must use the entire configured physical capacity')
local settledAt=fillCycles*Config.Interval+Config.TransitSeconds
local seen={}; local heights={}; local speciesSpread={}; local topId=pile.state.tokens[Config.GroundCap].id
local topY=pile.state.tokens[Config.GroundCap].y
for _,mini in pile.state.tokens do
    local key=string.format('%.3f:%.3f:%.3f',mini.x,mini.y,mini.z)
    assert(not seen[key],'Minis must occupy distinct resting places at full capacity')
    seen[key]=true; heights[math.floor(mini.y)]=true
    assert(mini.y>0 and mini.y<6,'Pile must stack above the tray within reach')
    assert(math.abs(mini.x)<=10.31+1e-8 and math.abs(mini.z-Config.TrayZ)<=5.385+1e-8,'Pile must stay inside tray walls')
    assert(mini.y<=Config.CollectDistance,'Every resting mini must be reachable while walking underneath it on the ground')
    if mini.y==pile.state.tokens[1].y then
        local spread=speciesSpread[mini.speciesId] or {low=mini.x,high=mini.x}
        spread.low=math.min(spread.low,mini.x); spread.high=math.max(spread.high,mini.x)
        speciesSpread[mini.speciesId]=spread
    end
end
local heightCount=0
for _ in heights do heightCount+=1 end
assert(heightCount==math.ceil(Config.GroundCap/32),'Full tray must fill every required 32-position layer')
assert(pile.state.tokens[33].y-pile.state.tokens[1].y>=1.9,'Stacked mini bodies need vertical clearance')
for _,spread in speciesSpread do assert(spread.high-spread.low>3,'Repeated species must not form identical columns across each layer') end
for _,mini in pile.state.tokens do
    local snapshot=core:newSession(pile.owner,0,'pickup-check')
    snapshot.state=core:snapshot(pile)
    assert(core:dispatch(snapshot,'Collect',{mini.id},{now=settledAt,alive=true,position={x=mini.x,y=0,z=mini.z}}).code=='OK','Ground-level pickup must reach every height in the full pile')
end
for _=1,32 do
    local mini=pile.state.tokens[1]
    assert(core:dispatch(pile,'Collect',{mini.id},{now=settledAt,alive=true,position={x=mini.x,y=mini.y,z=mini.z}}).code=='OK')
end
local remaining=Config.GroundCap-32
assert(#pile.state.tokens==remaining)
assert(pile.state.tokens[remaining].id==topId and pile.state.tokens[remaining].y<topY,'Surviving top minis must settle after lower minis are collected')
local survivor=pile.state.tokens[remaining]
assert(core:dispatch(pile,'Collect',{survivor.id},{now=settledAt,alive=true,position={x=survivor.x,y=survivor.y,z=survivor.z}}).code=='OK','Pickup must use the new authoritative pile position')
print('PASS '..Config.GroundCap..' unique full-cap pile positions, tray bounds, stacked heights and authoritative settling after pickup')
