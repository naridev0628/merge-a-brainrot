local Economy=require('../src/shared/Economy')
local Config=require('../src/shared/Config')
local Core=require('../src/server/Domain/FarmCore')
local Catalog=require('../src/shared/CreatureCatalog')
assert(type(Economy.purchaseQuote)=='function','Purchase rules must be shared by server and both clients')
local function state(count,rebirths,purchased,coins,starter)
    local producers={}
    for slot=1,count do table.insert(producers,{id='p'..slot,speciesId='tier_01',slot=slot,due=1}) end
    return {producers=producers,rebirths=rebirths,purchased=purchased,coinUnits=coins,starterClaimed=starter}
end
-- Literal prices cover arithmetic progression, rebirth tier equivalents, and full/partial batches.
local cases={
    {state(0,0,0,20,false),'1',1,1,20,'OK'},
    {state(1,0,1,139,true),'5',5,1,140,'InsufficientFunds'},
    {state(1,0,1,140,true),'5',5,1,140,'OK'},
    {state(1,0,1,380,true),'10',10,1,380,'OK'},
    {state(0,0,0,100000,false),'50',50,1,5704,'ClaimStarter'},
    {state(1,0,1,100000,true),'50',49,1,5684,'Locked'},
    {state(48,2,3,136,true),'50',2,2,136,'OK'},
    {state(49,20,0,2500,true),'50',1,6,2500,'OK'},
    {state(46,0,0,100000,true),'5',5,1,124,'PlotFull'},
    {state(50,1,0,100000,true),'50',0,1,0,'PlotFull'},
    {state(1,1,0,100000,true),'100',0,1,0,'BadRequest'},
}
for index,case in cases do
    local st,q,amount,tier,cost,code=table.unpack(case)
    local quote=Economy.purchaseQuote(Config,st,q)
    assert(quote.amount==amount and quote.tier==tier and quote.cost==cost and quote.code==code,'Incorrect purchase quote case '..index)
    local core=Core.new(Config,Catalog,function()return 1 end)
    local session=core:newSession(index,0,'quote'..index)
    for key,value in st do session.state[key]=value end
    local before=session.state.coinUnits
    local result=core:dispatch(session,'Buy',{'buy',q},{now=0,alive=true,position={x=Config.BuyPads[q] or 0,y=0,z=Config.BuyZ}})
    assert(result.code==quote.code,'Server eligibility must match shared quote case '..index)
    assert(session.state.coinUnits==before-(if code=='OK' then cost else 0),'Wrong charge case '..index)
    assert(#session.state.producers==#st.producers+(if code=='OK' then amount else 0),'Wrong batch size case '..index)
    if code=='OK' then assert(result.speciesId==string.format('tier_%02d',tier)) end
end
print('PASS shared purchase quote prices, exact affordability, tier bounds, eligibility and server parity')
