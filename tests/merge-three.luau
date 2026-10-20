local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
assert(Config.MergeCount==3)
local core=Core.new(Config,Catalog,function() return 1 end)
local function fixture(tiers)
    local session=core:newSession(1,0,'triples')
    session.state.starterClaimed=true
    for slot,tier in tiers do
        session.state.producers[slot]={id='p'..slot,speciesId=string.format('tier_%02d',tier),slot=slot,due=10+slot}
    end
    return session
end
local function merge(session,args)
    return core:dispatch(session,'Merge',args,{now=3,alive=true,position={x=Config.MergeX,y=0,z=Config.MergeZ}})
end
for _,case in {
    {tiers={1,1,1},args={'two','p1','p2'},code='BadRequest'},
    {tiers={1,1,1},args={'same','p1','p2','p1'},code='SameProducer'},
    {tiers={1,1,1},args={'foreign','p1','p2','foreign'},code='MissingProducer'},
    {tiers={1,1,2},args={'mismatch','p1','p2','p3'},code='Mismatch'},
    {tiers={Config.MaxTier,Config.MaxTier,Config.MaxTier},args={'top','p1','p2','p3'},code='MaxTier'},
} do
    local s=fixture(case.tiers);local before=s.state
    assert(merge(s,case.args).code==case.code and s.state==before,'Rejected triples must not change the wallet or producers')
end
local valid=fixture({1,1,1,7})
local survivor=table.clone(valid.state.producers[4])
local result=merge(valid,{'valid','p3','p1','p2'})
assert(result.code=='OK' and result.count==1 and #valid.state.producers==2)
assert(valid.state.coinUnits==Config.StartingUnits and valid.state.discoveries.tier_02)
local found=false
for _,p in valid.state.producers do
    if p.id==survivor.id then
        found=true;assert(p.speciesId==survivor.speciesId and p.due==survivor.due)
    else assert(p.speciesId=='tier_02' and p.due==3+Config.Interval) end
end
assert(found)
local before=valid.state
assert(merge(valid,{'valid','p3','p1','p2'}).replayed and valid.state==before)
-- A triple cascade leaves 0..2 of each non-max tier and reports groups, not inputs.
local cascade=fixture({1,1,1,1,1,1,1,1,1,1,1})
local automatic=core:dispatch(cascade,'AutoMerge',{'all'},
    {now=3,alive=true,position={x=Config.MergeX,y=0,z=Config.MergeZ}})
assert(automatic.code=='OK' and automatic.count==4 and #cascade.state.producers==3)
local counts={}
for _,p in cascade.state.producers do counts[p.speciesId]=(counts[p.speciesId] or 0)+1 end
assert(counts.tier_01==2 and counts.tier_03==1)
before=cascade.state
assert(core:dispatch(cascade,'AutoMerge',{'leftovers'},
    {now=3,alive=true,position={x=Config.MergeX,y=0,z=Config.MergeZ}}).code=='NoPairs' and cascade.state==before)
print('PASS exactly-three manual merges, duplicate/foreign/mismatch/max rejection, survivor schedule, replay, triple cascade and two-item leftovers')
