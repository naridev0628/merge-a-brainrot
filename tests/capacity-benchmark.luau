-- Pure CPU and gameplay-capacity probe. Timings are diagnostic, never an FPS claim.
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local Pickup=require('../src/shared/PickupGeometry')
local scenarios={{50,50},{50,96},{50,100},{50,200},{100,50},{100,100},{200,100},{200,200},{200,300},{500,200}}
local seconds=40
for _,scenario in scenarios do
    local producerCap,miniCap=table.unpack(scenario)
    local config=table.clone(Config)
    config.Slots=producerCap
    config.GroundCap=miniCap
    config.LuckyChance=0
    local core=Core.new(config,Catalog,function()return 1 end)
    local sessions={}
    for id=1,6 do
        local session=core:newSession(id,0,'capacity-'..id)
        session.state.coinUnits=0
        session.state.starterClaimed=true
        session.state.autoCollect=true
        session.state.autoSell=true
        session.state.processorLevel=#config.ProcessorCosts
        for slot=1,producerCap do
            session.state.producers[slot]={id='producer-'..slot,speciesId='tier_01',slot=slot,due=1}
        end
        assert(core:validate(session.state,id),'Benchmark setup must use a valid expanded configuration')
        table.insert(sessions,session)
    end
    local elapsed=0
    local slowest=0
    local changed=0
    local peakTokens=0
    local snapshots=0
    for tick=1,seconds/config.Cadence do
        local started=os.clock()
        for _,session in sessions do
            if core:step(session,tick*config.Cadence) then
                changed+=1
                local snapshot=core:snapshot(session)
                snapshots+=#snapshot.tokens+#snapshot.producers
            end
            peakTokens=math.max(peakTokens,#session.state.tokens)
            assert(#session.state.tokens<=miniCap and #session.state.producers==producerCap)
        end
        local duration=os.clock()-started
        elapsed+=duration
        slowest=math.max(slowest,duration)
    end
    local representative=sessions[1]
    local delivered=representative.state.coinUnits/8+representative.state.soldUnits/8
        +Economy.count(representative.state.saleQueue)+Economy.count(representative.state.bag)
    assert(delivered>0,'Auto Collect must keep making progress at the tested capacity')
    assert(core:validate(representative.state,1),'Expanded simulation ended in an invalid state')
    -- Examine a full resting pile separately: no animation/GPU assumptions.
    local pile=core:newSession(7,0,'pile')
    pile.state.starterClaimed=true
    for slot=1,producerCap do pile.state.producers[slot]={id='producer-'..slot,speciesId='tier_01',slot=slot,due=1} end
    for second=1,math.ceil(miniCap/producerCap) do core:step(pile,second) end
    local reachable=0
    local top=0
    for _,token in pile.state.tokens do
        top=math.max(top,token.y)
        if Pickup.contains({x=0,y=3,z=config.TrayZ},token,config.PickupRadius) then reachable+=1 end
    end
    assert(#pile.state.tokens==miniCap,'Capacity probe did not reach its target pile')
    print(string.format(
        'CAPACITY producers=%d minis=%d | six-farm avg %.3fms peak %.3fms/tick | delivered %.2f/s/farm | peak %d | pile top %.1f logical | center aura %d/%d | snapshots %d entities',
        producerCap,miniCap,elapsed/(seconds/config.Cadence)*1000,slowest*1000,delivered/seconds,peakTokens,top,reachable,miniCap,snapshots))
    assert(changed>0)
end
print('PASS expanded pure simulation remains valid; runtime rendering/network/device profiling still required')
