local Scenario=require('./CapacityHarnessScenario')
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local shipped=table.clone(Config)
for _,cap in {50,96} do
    local run=Scenario.new(Core,Config,Catalog,cap,100)
    assert(run.config~=Config and run.config.GroundCap==cap,'The harness must use an independent comparison configuration')
    for key,value in shipped do assert(Config[key]==value,'The harness mutated shipped configuration: '..key) end
    assert(#run.sessions==6)
    for _,session in run.sessions do
        assert(run.core:validate(session.state,session.owner),'Seeded farm must be valid')
        assert(#session.state.producers==50 and #session.state.tokens==cap,'Every farm must start fully populated')
        local species={}
        for _,producer in session.state.producers do species[producer.speciesId]=true end
        for tier=1,6 do assert(species[string.format('tier_%02d',tier)],'Every farm must exercise all six species') end
        for _,token in session.state.tokens do assert(token.readyAt<100,'The initial pile must already be settled') end
    end
    Scenario.churn(run,true,100)
    local created,removed=0,0
    for step=1,80 do
        local delta=Scenario.step(run,100+step*.25)
        created+=delta.created;removed+=delta.removed
        for _,session in run.sessions do
            assert(run.core:validate(session.state,session.owner))
            assert(#session.state.tokens<=cap and #session.state.producers==50)
        end
    end
    assert(created>cap*6 and removed>cap*6,'Churn must complete repeated production and collection cycles')
    Scenario.churn(run,false,120)
    for step=1,32 do Scenario.step(run,120+step*.25) end
    for _,session in run.sessions do
        assert(#session.state.tokens==cap,'Turning churn off must refill the resting pile')
        for _,token in session.state.tokens do assert(token.readyAt<=128) end
    end
end
for key,value in shipped do assert(Config[key]==value,'Churn mutated shipped configuration: '..key) end
assert(not pcall(Scenario.new,Core,Config,Catalog,200,100),'Only the two approved comparison capacities may run')
print('PASS six mixed-tier full farms, immutable shipped limits, valid commits, repeated churn and settled refills at 50/50 and 50/96')
