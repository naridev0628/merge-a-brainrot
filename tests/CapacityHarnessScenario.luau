--!strict
-- Test-only population recipe. Inject production Core/Config/Catalog unchanged.
local Scenario={}

function Scenario.new(Core: any,Config: any,Catalog: any,cap: number,now: number): any
    assert(cap==50 or cap==96,'Capacity comparison supports only 50 or 96 Minis')
    local config=table.clone(Config)
    config.GroundCap=cap
    config.LuckyChance=0
    assert(config.Slots==50 and config.PlotCount==6,'This comparison requires six 50-producer farms')
    local core=Core.new(config,Catalog,function() return 1 end)
    local sessions={}
    for id=1,6 do
        -- Same keys and producer order at either cap preserve the first 50 IDs,
        -- species, deterministic pile jitter and authored plot positions.
        local seededAt=now-config.TransitSeconds-3
        local session=core:newSession(id,seededAt,'capacity-farm-'..id)
        local state=core:snapshot(session)
        state.coinUnits=0;state.starterClaimed=true;state.tutorialStep=7
        state.processorLevel=#config.ProcessorCosts
        for slot=1,50 do
            local speciesId=string.format('tier_%02d',(slot-1)%6+1)
            state.producers[slot]={id=core:id(session),speciesId=speciesId,slot=slot,due=seededAt+1}
            state.discoveries[speciesId]=true
        end
        assert(core:commit(session,state),'Invalid producer seed')
        core:step(session,seededAt+1)
        core:step(session,seededAt+2)
        assert(#session.state.tokens==cap,'Initial production did not fill the target pile')
        state=core:snapshot(session)
        for _,producer in state.producers do producer.due=now+config.Interval end
        assert(core:commit(session,state),'Invalid settled seed')
        sessions[id]=session
    end
    return {core=core,config=config,sessions=sessions,churning=false}
end

function Scenario.churn(run: any,enabled: boolean,now: number)
    run.churning=enabled
    for _,session in run.sessions do
        local state=run.core:snapshot(session)
        state.autoCollect=enabled;state.autoSell=enabled
        for _,producer in state.producers do producer.due=now+run.config.Interval end
        assert(run.core:commit(session,state),'Invalid churn transition')
    end
end

function Scenario.step(run: any,now: number): any
    local result={created=0,removed=0,changed={}}
    for id,session in run.sessions do
        local before=#session.state.tokens
        local sequence=session.sequence
        if run.core:step(session,now) then
            local created=session.sequence-sequence
            result.created+=created
            result.removed+=before+created-#session.state.tokens
            table.insert(result.changed,id)
        end
    end
    return result
end

return table.freeze(Scenario)
