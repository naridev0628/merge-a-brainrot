local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')
local Motion=require('../src/shared/MiniMotion')
local config=table.clone(Config)
config.BuyPads={['1']=44,['5']=22,['10']=-22,['100']=-44}
config.BuyUnlocks={['1']=0,['5']=0,['10']=0,['100']=1}
local function fixture(count,tier,rebirths)
    local core=Core.new(config,Catalog,function() return 1 end)
    local s=core:newSession(1,0,'bulk')
    s.state.starterClaimed=true;s.state.rebirths=rebirths or 1;s.state.coinUnits=100000000000
    for slot=1,count do
        s.state.producers[slot]={id='existing'..slot,speciesId=string.format('tier_%02d',tier or 1),slot=slot,due=1}
    end
    assert(core:validate(s.state,s.owner))
    return core,s
end
local function buy(core,s,key,quantity)
    return core:dispatch(s,'Buy',{key,quantity or '100'},{now=1,alive=true,position={x=-44,y=0,z=config.BuyZ}})
end
local function mass(producers)
    local total=0
    for _,p in producers do total+=3^(Catalog[p.speciesId].tier-1) end
    return total
end
local core,s=fixture(50)
assert(core:step(s,1))
local token=table.clone(s.state.tokens[1])
local initialMass=mass(s.state.producers)
local oldState=s.state
local quote=Economy.purchaseQuote(config,s.state,'100')
assert(quote.code=='OK' and quote.amount==100 and quote.mergePlan and #quote.mergePlan<=config.Slots,
    'A full plot must quote 100 purchases against the compact final merge plan')
assert(s.state==oldState and #s.state.producers==50,'Quote must not mutate the source')
local coins,sequence=s.state.coinUnits,s.sequence
local result=buy(core,s,'first')
assert(result.code=='OK' and result.count==100 and result.mergedCount==(150-#quote.mergePlan)/2)
assert(#s.state.producers==#quote.mergePlan and #s.state.producers==6)
assert(mass(s.state.producers)==initialMass+100 and s.state.coinUnits==coins-quote.cost)
assert(s.state.purchased==100 and s.sequence-sequence<=#s.state.producers,
    'Allocate IDs for final survivors only, never 100 temporary producers')
for i,p in s.state.producers do
    assert(p.speciesId==quote.mergePlan[i].speciesId and p.id==quote.mergePlan[i].sourceId)
    assert(p.due==1+config.Interval,'Promoted existing IDs get a fresh production cadence')
end
for tier=2,5 do assert(s.state.discoveries[string.format('tier_%02d',tier)],'Every intermediate merge tier is discovered') end
local after=s.state
assert(buy(core,s,'first').replayed and s.state==after,'Replay cannot buy or merge twice')
assert(buy(core,s,'first','50').code=='BadRequest','Removed Buy50 endpoint must not remain available')
assert(core:dispatch(s,'Collect',{token.id},{now=1,alive=true,position=Motion.position(config,token,1)}).code=='OK',
    'A Mini remains collectible after its producer is promoted or retired')
assert(s.state.bag[1].speciesId==token.speciesId,'Old Minis keep their original species and value')
-- Preserve existing high-tier IDs and cadence; absorb only matching/lower tiers.
local keep,ks=fixture(1,10,3)
local oldId=ks.state.producers[1].id;ks.state.producers[1].due=17
local beforeMass=mass(ks.state.producers)
assert(buy(keep,ks,'tier-three').code=='OK')
assert(mass(ks.state.producers)==beforeMass+100*9 and ks.state.purchased==900)
local preserved=false
for _,p in ks.state.producers do
    if p.id==oldId then assert(p.speciesId=='tier_10' and p.due==17);preserved=true end
end
assert(preserved,'Unmerged existing producer ID and due time must survive')
-- Top-tier pairs stay top-tier; the final count must fit, even with enough cash.
local capped,cs=fixture(50,config.MaxTier,20)
local before=cs.state
assert(Economy.purchaseQuote(config,cs.state,'100').code=='PlotFull')
assert(buy(capped,cs,'full').code=='PlotFull' and cs.state==before)
local poor,ps=fixture(1);ps.state.coinUnits=0;before=ps.state
assert(buy(poor,ps,'poor').code=='InsufficientFunds' and ps.state==before)
local locked,ls=fixture(1,1,0);before=ls.state
assert(buy(locked,ls,'locked').code=='Locked' and ls.state==before)
-- Hundreds of deterministic mixed farms compare merge mass and plan/server parity.
for seed=1,160 do
    local c,st=fixture(seed%50+1,1,seed%20+1)
    for slot,p in st.state.producers do p.speciesId=string.format('tier_%02d',(seed*slot)%config.MaxTier+1) end
    local starting=mass(st.state.producers)
    local q=Economy.purchaseQuote(config,st.state,'100')
    local outcome=buy(c,st,'case')
    assert(outcome.code==q.code)
    if outcome.code=='OK' then
        assert(#st.state.producers==#q.mergePlan and #st.state.producers<=config.Slots)
        assert(mass(st.state.producers)==starting+100*3^(q.tier-1))
        assert(c:validate(st.state,st.owner))
        local seen={}
        for _,p in st.state.producers do
            if Catalog[p.speciesId].tier<config.MaxTier then seen[p.speciesId]=(seen[p.speciesId] or 0)+1;assert(seen[p.speciesId]<3) end
        end
    end
end
print('PASS Buy100 compact atomic plan, exact cost/mass, full-plot merging, stable IDs/due, old pickup, replay/rejections and 160 mixed farms')
