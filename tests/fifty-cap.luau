local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Motion=require('../src/shared/MiniMotion')
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
local invalid=core:snapshot(s)
table.insert(invalid.producers,{id='overflow',speciesId='tier_01',slot=51,due=1})
assert(not core:validate(invalid,s.owner),'Validation must reject an over-cap snapshot')

-- Producer capacity stays fifty. Test physical Mini capacity independently,
-- retaining the original fifty-Mini boundary alongside the configured limit.
assert(Config.Slots==50 and Config.GroundPerProducer==8)
local capacities={50}
if Config.GroundCap~=50 then table.insert(capacities,Config.GroundCap) end
for _,cap in capacities do
    local config=table.clone(Config);config.GroundCap=cap
    local engine=Core.new(config,Catalog,function() return 1 end)
    local full=engine:newSession(10,0,'physical-'..cap)
    full.state=core:snapshot(s)
    engine:step(full,1)
    assert(#full.state.tokens==math.min(50,cap),'First production tick must respect physical capacity')
    engine:step(full,2)
    assert(#full.state.tokens==cap,'Two ticks must fill the proposed physical capacity')
    for _,token in full.state.tokens do assert(token.readyAt>2,'A full tray must count in-flight reservations') end
    engine:step(full,3);assert(#full.state.tokens==cap,'Further drops cannot exceed cap during transit')
    local overflow=engine:snapshot(full)
    local extra=table.clone(overflow.tokens[1]);extra.id='over-cap';extra.owner=full.owner
    table.insert(overflow.tokens,extra)
    assert(not engine:validate(overflow,full.owner),'Validation must reject cap+1 physical Minis')
    -- Remove one moving Mini using its current position. Its replacement must
    -- coexist with every survivor after both original production batches land.
    local removed=full.state.tokens[1]
    assert(engine:dispatch(full,'Collect',{removed.id},
        {now=3,alive=true,position=Motion.position(config,removed,3)}).code=='OK')
    engine:step(full,6)
    local airborne,grounded=0,0
    for _,token in full.state.tokens do if token.readyAt>6 then airborne+=1 else grounded+=1 end end
    assert(airborne==1 and grounded==cap-1,'Moving and resting Minis must share one common capacity')
    engine:step(full,10000);assert(#full.state.tokens==cap)
    for _,producer in full.state.producers do assert(producer.due==10001,'Blocked production must discard backlog') end

    -- Eleven producers can store only 88 Minis; twelve can fill a 96-Mini tray.
    -- This verifies the per-producer limit still applies below the global cap.
    for _,count in {11,12} do
        local limited=engine:newSession(20+count,0,'producer-limit-'..cap..'-'..count)
        limited.state.starterClaimed=true
        for slot=1,count do limited.state.producers[slot]={id='p'..slot,speciesId='tier_01',slot=slot,due=1} end
        for second=1,20 do engine:step(limited,second) end
        assert(#limited.state.tokens==math.min(cap,count*8),'Each producer must stop after its eighth physical Mini')
        assert(engine:validate(limited.state,limited.owner))
        if cap>count*8 then
            local overProducer=engine:snapshot(limited)
            local ninth=table.clone(overProducer.tokens[1]);ninth.id='ninth'
            table.insert(overProducer.tokens,ninth)
            assert(not engine:validate(overProducer,limited.owner),'A ninth Mini from one producer must be rejected below global cap')
        end
    end

    -- Use the minimum producer count that fills this cap so a catch-up burst
    -- would remain below the global limit and cannot hide behind clipping.
    local producerCount=math.ceil(cap/config.GroundPerProducer)
    local fresh=engine:newSession(2,0,'discard-'..cap)
    fresh.state.starterClaimed=true
    for slot=1,producerCount do fresh.state.producers[slot]={id='p'..slot,speciesId='tier_01',slot=slot,due=1} end
    for second=1,20 do engine:step(fresh,second) end
    assert(#fresh.state.tokens==cap)
    engine:step(fresh,10000)
    local clear=engine:dispatch(fresh,'CollectNearby',{'clear'},
        {now=10000,alive=true,position={x=0,y=0,z=config.TrayZ}})
    assert(clear.code=='OK' and clear.count==cap and #fresh.state.tokens==0,'Clear the full tray through real collection')
    engine:step(fresh,10000.5);assert(#fresh.state.tokens==0,'Clearing capacity must not release blocked work immediately')
    engine:step(fresh,10001);assert(#fresh.state.tokens==producerCount,'Only one fresh drop per producer may follow a capped stall')
    assert(engine:validate(fresh.state,fresh.owner))
end
print('PASS fifty producers, Lucky/merge boundaries, legacy/configured Mini caps, eleven/twelve-producer limits, shared transit capacity and no backlog')
