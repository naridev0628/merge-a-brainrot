local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local core=Core.new(Config,Catalog,function()return 1 end)
local s=core:newSession(1,0,'cap')
local function command(action,args,now)
    return core:dispatch(s,action,args,{now=now or 0,alive=true,position={x=Config.BuyPads[args[2] or '1'] or 0,y=0,z=Config.BuyZ}})
end
s.state.coinUnits=1000000
assert(command('Buy',{'starter','1'}).code=='OK')
for i=1,49 do assert(command('Buy',{'buy'..i,'1'}).code=='OK') end
local before=s.state.coinUnits
assert(command('Buy',{'fifty-first','1'}).code=='PlotFull','A 51st producer must be rejected')
assert(s.state.coinUnits==before and #s.state.producers==50)
assert(core:slotPosition(50).y==Config.DisplayPlatformHeight+4*Config.RowHeight,'All fifty producers must fit five rows')
s.state.lucky={id='held',baseTier=2,held=true}
assert(command('OpenLucky',{'full-lucky','held','2160'}).code=='PlotFull','Lucky rewards cannot exceed the placed cap')
assert(s.state.lucky.id=='held' and s.state.coinUnits==before,'Full-plot Lucky opening must preserve the block and cash')
assert(command('Merge',{'merge',s.state.producers[1].id,s.state.producers[2].id}).code=='OK')
assert(#s.state.producers==49)
assert(command('OpenLucky',{'room-lucky','held','2120'}).code=='OK')
assert(#s.state.producers==50 and not s.state.lucky and s.state.coinUnits==before-2120)
assert(command('Buy',{'still-full','5'}).code=='PlotFull')
core:step(s,1)
assert(#s.state.tokens==50,'Airborne Minis must share the fifty-item cap')
for _,token in s.state.tokens do assert(token.readyAt>1) end
core:step(s,2);assert(#s.state.tokens==50,'Further drops cannot exceed cap while in transit')
-- Remove one airborne Mini and let its replacement coexist with 49 landed Minis.
local removed=s.state.tokens[1]
assert(core:dispatch(s,'Collect',{removed.id},{now=1,alive=true,position={x=removed.startX,y=removed.startY,z=removed.startZ}}).code=='OK')
core:step(s,5)
local airborne,grounded=0,0
for _,token in s.state.tokens do if token.readyAt>5 then airborne+=1 else grounded+=1 end end
assert(airborne==1 and grounded==49,'Transit and ground tokens must count against one common limit')
core:step(s,10000);assert(#s.state.tokens==50)
for _,producer in s.state.producers do assert(producer.due==10001,'Blocked production must discard backlog') end
-- Clear via actual pickups, then use seven producers so a backlog burst would stay below the global cap.
while #s.state.tokens>0 do
    local token=s.state.tokens[1]
    assert(core:dispatch(s,'Collect',{token.id},{now=10000,alive=true,position={x=token.x,y=token.y,z=token.z}}).code=='OK')
end
local fresh=core:newSession(2,0,'discard')
fresh.state.starterClaimed=true
for slot=1,7 do table.insert(fresh.state.producers,{id='p'..slot,speciesId='tier_01',slot=slot,due=1}) end
for second=1,20 do core:step(fresh,second) end
assert(#fresh.state.tokens==50)
core:step(fresh,10000)
while #fresh.state.tokens>0 do
    local token=fresh.state.tokens[1]
    assert(core:dispatch(fresh,'Collect',{token.id},{now=10000,alive=true,position={x=token.x,y=token.y,z=token.z}}).code=='OK')
end
core:step(fresh,10000.5);assert(#fresh.state.tokens==0,'Clearing capacity must not release blocked work immediately')
core:step(fresh,10001);assert(#fresh.state.tokens==7,'Only one fresh drop per producer may follow a capped stall')
local invalid=core:snapshot(s)
table.insert(invalid.producers,{id='overflow',speciesId='tier_01',slot=51,due=1})
assert(not core:validate(invalid,s.owner),'Validation must reject an over-cap snapshot')
print('PASS fifty placed Brainrots, full Lucky rejection, merge frees space, shared transit/ground cap and no burst backlog')
