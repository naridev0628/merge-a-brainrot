-- Domain acceptance for the proposed physical Mini cap. Does not promote Config.
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local Pickup=require('../src/shared/PickupGeometry')
local Motion=require('../src/shared/MiniMotion')
local originalCap=Config.GroundCap
local config=table.clone(Config)
config.GroundCap=96
config.LuckyChance=0
local core=Core.new(config,Catalog,function() return 1 end)
assert(config.Slots==50 and config.GroundPerProducer==8,'This proposal changes physical Mini capacity only')
local serial=0
local function seed(count)
    serial+=1
    local session=core:newSession(serial,0,'accept-96-'..serial)
    local state=core:snapshot(session)
    state.starterClaimed=true
    for slot=1,count do
        local species=string.format('tier_%02d',(slot-1)%6+1)
        state.producers[slot]={id=core:id(session),speciesId=species,slot=slot,due=1}
        state.discoveries[species]=true
    end
    assert(core:commit(session,state))
    return session
end
local function copySession(session)
    local copy=core:newSession(session.owner,0,session.key..'-probe')
    copy.state=core:snapshot(session)
    return copy
end
local function context(now,x,z)
    return {now=now,alive=true,position={x=x,y=0,z=z},
        pickupPosition={x=x,y=3/config.PlotScale,z=z}}
end
local function aura(session,id,now,x,z)
    return core:dispatch(session,'CollectNearby',{id},context(now,x,z))
end
local function speciesCounts(tokens)
    local counts={}
    for _,token in tokens do counts[token.speciesId]=(counts[token.speciesId] or 0)+1 end
    return counts
end
local function checkBag(session,expected)
    assert(Economy.count(session.state.bag)==96)
    for _,good in session.state.bag do
        assert(good.count==expected[good.speciesId] and good.baseCoinValue==Catalog[good.speciesId].value,
            'Every species keeps its count and captured cash value, including Crocodilo')
    end
end

-- All nodes lie on the ground in front of the tray's front rim (z = TrayZ-6).
-- They avoid walking through the pile or requiring a jump onto its top layer.
local walkNodes={{x=-6,z=config.TrayZ-9},{x=0,z=config.TrayZ-9},{x=6,z=config.TrayZ-9}}
local furthest=0
for farm=1,6 do
    local full=seed(50)
    assert(core:step(full,1) and #full.state.tokens==50)
    assert(core:step(full,2) and #full.state.tokens==96)
    for _,token in full.state.tokens do assert(token.readyAt>2,'The global cap includes all airborne reservations') end
    assert(core:step(full,3) and #full.state.tokens==96,'Production must stop at the common transit/resting cap')
    local expected=speciesCounts(full.state.tokens)
    for tier=1,6 do assert(expected[string.format('tier_%02d',tier)]>0,'Full farms must include every species') end
    local seen,origins,layers={},{},{}
    local maximumY=0
    for _,token in full.state.tokens do
        local key=string.format('%.6f:%.6f:%.6f',token.x,token.y,token.z)
        assert(not seen[key],'96 Minis must retain unique logical resting positions')
        seen[key]=true;layers[token.y]=true;maximumY=math.max(maximumY,token.y)
        origins[token.origin]=(origins[token.origin] or 0)+1
        assert(origins[token.origin]<=8)
        assert(math.abs(token.x)<7.5 and math.abs(token.z-config.TrayZ)<6,
            'Logical centers must remain within the existing tray footprint')
        local best,bestDistance=nil,math.huge
        for _,node in walkNodes do
            local center=context(10,node.x,node.z).pickupPosition
            local distance=math.sqrt((center.x-token.x)^2+(center.y-token.y)^2+(center.z-token.z)^2)
            if distance<bestDistance then best=node;bestDistance=distance end
        end
        furthest=math.max(furthest,bestDistance*config.PlotScale)
        assert(best and Pickup.contains(context(10,best.x,best.z).pickupPosition,token,config.PickupRadius),
            'Every Mini must fit the aura from a reasonable ground-level approach')
        -- Verify the actual dispatch semantics for every resting height/species.
        local probe=copySession(full)
        local result=aura(probe,'walk-check',10,best.x,best.z)
        assert(result.code=='OK')
        for _,remaining in probe.state.tokens do assert(remaining.id~=token.id,'Reachable target was not collected') end
    end
    local layerCount=0
    for _ in layers do layerCount+=1 end
    assert(layerCount==4 and math.abs(maximumY-7.3)<1e-8,'96 must occupy exactly four complete 24-slot layers')

    -- A side approach collects only part of the pile. The remaining IDs keep
    -- their values and immediately compact before the next real pickup.
    local previous={}
    for _,token in full.state.tokens do previous[token.id]=table.clone(token) end
    local partial=aura(full,'left-edge',10,-18,config.TrayZ)
    assert(partial.code=='OK' and partial.count>0 and partial.count<96)
    local lowered=false
    for _,token in full.state.tokens do
        local old=previous[token.id]
        assert(old and token.speciesId==old.speciesId and token.baseCoinValue==old.baseCoinValue)
        assert(token.y<=old.y,'Removing Minis must never lift a survivor to a higher layer')
        lowered=lowered or token.y<old.y
    end
    assert(lowered and core:validate(full.state,full.owner),'Surviving upper Minis must repack into lower vacancies')
    local final=aura(full,'front-walk',10.1,0,config.TrayZ-9)
    assert(final.code=='OK' and final.count+partial.count==96 and #full.state.tokens==0)
    checkBag(full,expected)
    local revision=full.state.revision
    assert(aura(full,'front-walk',10.2,0,config.TrayZ-9).replayed)
    assert(Economy.count(full.state.bag)==96 and full.state.revision==revision,'Aura replay must not duplicate inventory')
end

-- Mixed airborne and landed Minis share the same cap and remain collectible by
-- their current motion position. A remote landing target must not grant pickup.
local airborne=seed(50)
core:step(airborne,1);core:step(airborne,2)
local expectedAir=speciesCounts(airborne.state.tokens)
assert(aura(airborne,'too-early',2,0,config.TrayZ-9).code=='NothingNearby')
local highest=airborne.state.tokens[#airborne.state.tokens]
assert(core:dispatch(airborne,'Collect',{highest.id},context(2,0,config.TrayZ-9)).code=='TooFar')
local moving,landed,eligible=0,0,0
local collectAt=5.6
local center=context(collectAt,0,config.TrayZ-9).pickupPosition
for _,token in airborne.state.tokens do
    if token.readyAt>collectAt then moving+=1 else landed+=1 end
    local position=Motion.position(config,token,collectAt)
    if position and Pickup.contains(center,position,config.PickupRadius) then eligible+=1 end
end
assert(moving>0 and landed>0 and eligible==96,'Fixture must cover both the final airborne arc and the settled pile')
local caught=aura(airborne,'catch-arc',collectAt,0,config.TrayZ-9)
assert(caught.code=='OK' and caught.count==eligible and #airborne.state.tokens==0)
checkBag(airborne,expectedAir)
assert(core:validate(airborne.state,airborne.owner))

-- Six producers retain their own limit (48 total); twelve can fill 96. After a
-- long blocked interval the next fresh tick must not release hidden catch-up.
for _,count in {6,12,50} do
    local capped=seed(count)
    for second=1,10 do core:step(capped,second) end
    local expectedTotal=math.min(96,count*8)
    assert(#capped.state.tokens==expectedTotal)
    core:step(capped,10000)
    assert(#capped.state.tokens==expectedTotal)
    for _,producer in capped.state.producers do assert(producer.due==10001) end
    local removed=aura(capped,'clear-stall',10000,0,config.TrayZ-9)
    assert(removed.code=='OK' and removed.count==expectedTotal and #capped.state.tokens==0)
    assert(not core:step(capped,10000.5) and #capped.state.tokens==0,'Clearing capacity must not release blocked work')
    assert(core:step(capped,10001) and #capped.state.tokens==count,'Only one new drop per producer follows a blocked stall')
    assert(core:validate(capped.state,capped.owner))
end
assert(Config.GroundCap==originalCap and Config.Slots==50 and Config.GroundPerProducer==8,'Acceptance must leave shipped limits unchanged')
print(string.format('PASS 96 mixed Minis across six farms: four layers, all six species, actual aura/airborne pickup, repack/replay and no backlog; furthest ground approach %.2f / 12 world studs',furthest))
