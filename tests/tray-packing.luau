-- Exercise actual committed positions, accounting and pickup against the wider tray.
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local PadGeometry=require('../src/shared/PadGeometry')
local config=table.clone(Config)
config.LuckyChance=0
local rolls=0
local core=Core.new(config,Catalog,function() rolls+=1;return 1 end)
local function seed(mode,key)
    local session=core:newSession(41,0,key)
    local state=core:snapshot(session)
    state.starterClaimed=true
    for slot=1,50 do
        local species=if mode=='mixed' then string.format('tier_%02d',(slot-1)%6+1) else 'tier_06'
        state.producers[slot]={id=core:id(session),speciesId=species,slot=slot,due=1}
        state.discoveries[species]=true
    end
    assert(core:commit(session,state))
    assert(core:step(session,1) and core:step(session,2))
    assert(#session.state.tokens==96)
    return session
end
local function context(now,x,z,height)
    return {now=now,alive=true,position={x=x,y=0,z=z},
        pickupPosition={x=x,y=(height or 3)/config.PlotScale,z=z}}
end
local function collectAt(session,id,x,z)
    return core:dispatch(session,'CollectNearby',{id},context(20,x,z))
end
local furthest=0
for _,mode in {'mixed','tier_06'} do
    for run=1,4 do
        local session=seed(mode,'wide-tray-'..mode..'-'..run)
        local saved=core:snapshot(session)
        local totalQuantity=Economy.count(saved.tokens)
        local layers,seen,expected={},{},{}
        local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
        for _,token in saved.tokens do
            assert(token.y<=5.3+1e-8,'A full 96-Mini tray must fit three layers, not the former four-layer tower')
            layers[token.y]=(layers[token.y] or 0)+1
            local key=string.format('%.6f:%.6f:%.6f',token.x,token.y,token.z)
            assert(not seen[key],'Each Mini needs a distinct authoritative resting position')
            seen[key]=true
            assert(math.abs(token.x)<=10.31+1e-8 and math.abs(token.z-67)<=5.385+1e-8,
                'Jittered centers must stay clear of the enlarged tray rims')
            minX=math.min(minX,token.x);maxX=math.max(maxX,token.x)
            minZ=math.min(minZ,token.z);maxZ=math.max(maxZ,token.z)
            expected[token.speciesId]=(expected[token.speciesId] or 0)+(token.count or 1)
            assert(token.baseCoinValue==Catalog[token.speciesId].value)
            -- Ground nodes are before the front collider, outside all action pads.
            -- Check short/tall root heights without changing the existing aura.
            for _,height in {2,3,4} do
                local best=math.huge
                for _,x in {-8,0,8} do
                    local center=context(20,x,56,height).pickupPosition
                    local distance=math.sqrt((center.x-token.x)^2+(center.y-token.y)^2+(center.z-token.z)^2)
                    best=math.min(best,distance*config.PlotScale)
                end
                assert(best<12,'Every resting Mini must remain reachable from the front ground approach')
                furthest=math.max(furthest,best)
            end
        end
        assert(layers[1.3]==32 and layers[3.3]==32 and layers[5.3]==32,
            'A full tray must distribute 32 distinct cells across each of three layers')
        assert(maxX-minX>18 and maxZ-minZ>8,'Packing must use the broader floor, not merely lower the old pile')
        for index,token in saved.tokens do
            for other=index+1,#saved.tokens do
                local neighbor=saved.tokens[other]
                if neighbor.y==token.y then
                    assert((neighbor.x-token.x)^2+(neighbor.z-token.z)^2>4,
                        'A cell permutation must not reuse or crowd a cell within a layer')
                end
            end
        end
        -- Recommitting must retain deterministic positions and never consume RNG.
        local beforeRolls=rolls
        assert(core:commit(session,core:snapshot(session)))
        for index,token in session.state.tokens do
            local previous=saved.tokens[index]
            assert(token.id==previous.id and token.x==previous.x and token.y==previous.y and token.z==previous.z)
        end
        assert(rolls==beforeRolls,'Packing must not advance the Lucky RNG stream')
        -- Removing a complete lower layer moves the surviving top down exactly one layer.
        local top=saved.tokens[96]
        for _=1,32 do
            local token=session.state.tokens[1]
            assert(core:dispatch(session,'Collect',{token.id},{now=20,alive=true,
                position={x=token.x,y=0,z=token.z}}).code=='OK')
        end
        assert(#session.state.tokens==64 and session.state.tokens[64].id==top.id)
        assert(math.abs(session.state.tokens[64].y-(top.y-2))<1e-8,'A removed layer must settle its survivors')
        local successful
        for _,x in {-8,0,8} do
            local result=collectAt(session,'front-'..x,x,56)
            assert(result.code=='OK' or result.code=='NothingNearby')
            if result.code=='OK' then successful=x end
        end
        assert(#session.state.tokens==0 and Economy.count(session.state.bag)==totalQuantity)
        for _,good in session.state.bag do
            assert(good.count==expected[good.speciesId] and good.baseCoinValue==Catalog[good.speciesId].value)
        end
        local revision=session.state.revision
        assert(successful and collectAt(session,'front-'..successful,successful,56).replayed)
        assert(session.state.revision==revision and Economy.count(session.state.bag)==totalQuantity)
        assert(rolls==beforeRolls and core:validate(session.state,session.owner))
    end
end

-- A normal approach through the two inner corridors must not trigger a Buy pad.
local route={{x=-15,z=56},{x=-15,z=67},{x=0,z=56},{x=15,z=67},{x=0,z=67}}
local previous={x=-15,z=49}
for _,node in route do
    for step=0,40 do
        local position={x=previous.x+(node.x-previous.x)*step/40,y=0,
            z=previous.z+(node.z-previous.z)*step/40}
        for quantity in config.BuyPads do
            assert(not PadGeometry.contains(config,'Buy',position,quantity),'Collection route must not cross a purchase footprint')
        end
    end
    previous=node
end
-- Sample the same five walking legs against real Core pickup/repack, with
-- enough intermediate points to catch survivors moving after a partial pickup.
for _,mode in {'mixed','tier_06'} do
    local session=seed(mode,'wide-tray-route-'..mode)
    local totalQuantity=Economy.count(session.state.tokens)
    local origin={x=-15,z=49}
    local serial,total,partial,repacked=0,0,false,false
    for _,node in route do
        local distance=math.sqrt((node.x-origin.x)^2+(node.z-origin.z)^2)
        local samples=math.ceil(distance*config.PlotScale/1.2)
        for step=1,samples do
            local x=origin.x+(node.x-origin.x)*step/samples
            local z=origin.z+(node.z-origin.z)*step/samples
            local old={}
            for _,token in session.state.tokens do old[token.id]=token.y end
            serial+=1
            local result=collectAt(session,'walking-'..serial,x,z)
            assert(result.code=='OK' or result.code=='NothingNearby')
            if result.code=='OK' then
                total+=result.count
                partial=partial or #session.state.tokens>0
                for _,token in session.state.tokens do
                    assert(token.y<=old[token.id],'A collection must not lift a survivor')
                    repacked=repacked or token.y<old[token.id]
                end
            end
        end
        origin=node
    end
    assert(total==totalQuantity and #session.state.tokens==0 and Economy.count(session.state.bag)==totalQuantity)
    assert(partial and repacked,'The real walking route must exercise partial collection and settling')
end
local lucky=seed('mixed','wide-tray-lucky')
lucky.state.lucky={id='front-block',baseTier=2}
local cash=lucky.state.coinUnits
assert(core:dispatch(lucky,'PickupLucky',{'outside-front','front-block'},
    context(20,0,57)).code=='OK','Lucky must be collectable before stepping over the front rim')
assert(lucky.state.lucky.held and lucky.state.coinUnits==cash,'Repositioning Lucky must preserve free pickup')
assert(config.PickupRadius*config.PlotScale==12 and config.LuckyPickupRadius*config.PlotScale==6)
print(string.format('PASS broad three-layer tray, eight seeded mixed/Crocodilo piles, deterministic repack/accounting, clear walking route and Lucky reach; furthest aura approach %.3f / 12 world studs',furthest))
