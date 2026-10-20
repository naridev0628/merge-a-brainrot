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
assert(math.abs(t.x)<=7.5 and t.z>=Config.TrayZ-6 and t.z<=Config.TrayZ+6)
assert(cmd('Collect',{t.id},Config.Interval,t.x,t.z).code=='InTransit')
assert(Economy.count(s.state.bag)==0 and #s.state.tokens==1)
assert(cmd('Collect',{t.id},t.readyAt,t.x,t.z).code=='OK')
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
print('PASS conveyor ordering, tray bounds, transit pickup rejection and automation arrival gate')

-- A full tray must never reuse the same resting place, and collecting the
-- bottom of the pile must compact the survivors into supported lower slots.
local pile=core:newSession(13,0,'pile')
pile.state.coinUnits=1000000; pile.state.rebirths=3
local buyContext={now=0,alive=true,position={x=Config.BuyPads['1'],y=3,z=Config.BuyZ}}
assert(core:dispatch(pile,'Buy',{'starter'},buyContext).code=='OK')
buyContext.position.x=Config.BuyPads['100']
assert(core:dispatch(pile,'Buy',{'full','100'},buyContext).code=='OK')
for index,producer in pile.state.producers do producer.speciesId=string.format('tier_%02d',(index-1)%6+1) end
core:step(pile,Config.Interval)
assert(#pile.state.tokens==96)
local seen={}; local heights={}; local speciesSpread={}; local topId=pile.state.tokens[96].id
local topY=pile.state.tokens[96].y
for _,mini in pile.state.tokens do
    local key=string.format('%.3f:%.3f:%.3f',mini.x,mini.y,mini.z)
    assert(not seen[key],'Minis must occupy distinct resting places at full capacity')
    seen[key]=true; heights[math.floor(mini.y)]=true
    assert(mini.y>0 and mini.y<8,'Pile must stack above the tray within reach')
    assert(math.abs(mini.x)<=7.5 and math.abs(mini.z-Config.TrayZ)<=6,'Pile must stay inside tray walls')
    assert(mini.y<=Config.CollectDistance,'Every resting mini must be reachable while walking underneath it on the ground')
    if mini.y==pile.state.tokens[1].y then
        local spread=speciesSpread[mini.speciesId] or {low=mini.x,high=mini.x}
        spread.low=math.min(spread.low,mini.x); spread.high=math.max(spread.high,mini.x)
        speciesSpread[mini.speciesId]=spread
    end
end
local heightCount=0
for _ in heights do heightCount+=1 end
assert(heightCount>=3,'Full tray must stack minis above neighboring minis')
assert(pile.state.tokens[25].y-pile.state.tokens[1].y>=1.9,'Stacked mini bodies need vertical clearance')
for _,spread in speciesSpread do assert(spread.high-spread.low>3,'Repeated species must not form identical columns across each layer') end
for _,mini in pile.state.tokens do
    local snapshot=core:newSession(pile.owner,0,'pickup-check')
    snapshot.state=core:snapshot(pile)
    assert(core:dispatch(snapshot,'Collect',{mini.id},{now=10,alive=true,position={x=mini.x,y=0,z=mini.z}}).code=='OK','Ground-level pickup must reach every height in the full pile')
end
for _=1,24 do
    local mini=pile.state.tokens[1]
    assert(core:dispatch(pile,'Collect',{mini.id},{now=10,alive=true,position={x=mini.x,y=mini.y,z=mini.z}}).code=='OK')
end
assert(#pile.state.tokens==72)
assert(pile.state.tokens[72].id==topId and pile.state.tokens[72].y<topY,'Surviving top minis must settle after lower minis are collected')
local survivor=pile.state.tokens[72]
assert(core:dispatch(pile,'Collect',{survivor.id},{now=10,alive=true,position={x=survivor.x,y=survivor.y,z=survivor.z}}).code=='OK','Pickup must use the new authoritative pile position')
print('PASS 96 unique pile positions, tray bounds, stacked heights and authoritative settling after pickup')
