local Economy=require('../src/shared/Economy')
local Config=require('../src/shared/Config')
local Core=require('../src/server/Domain/FarmCore')
local Catalog=require('../src/shared/CreatureCatalog')
for purchased=0,30 do
    for amount=0,50 do
        for tier=1,6 do
            local expected=0
            for offset=0,amount*3^(tier-1)-1 do expected+=20+4*math.max(0,purchased+offset-1) end
            assert(Economy.buyCost(purchased,amount,tier)==expected,'Constant-time pricing must exactly match the original price curve')
        end
    end
end
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
    {state(0,0,0,100000,false),'100',100,1,Economy.buyCost(0,100,1),'ClaimStarter'},
    {state(1,0,1,100000,true),'100',100,1,Economy.buyCost(1,100,1),'Locked'},
    {state(48,2,3,1000000,true),'100',100,2,Economy.buyCost(3,100,2),'OK'},
    {state(49,20,0,10000000000,true),'100',100,6,Economy.buyCost(0,100,6),'OK'},
    {state(46,0,0,100000,true),'5',5,1,124,'PlotFull'},
    {state(50,1,0,100000,true),'100',100,1,Economy.buyCost(0,100,1),'OK'},
    {state(1,1,0,100000,true),'50',0,1,0,'BadRequest'},
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
    assert(#session.state.producers==(if code=='OK' and quote.mergePlan then #quote.mergePlan else #st.producers+(if code=='OK' then amount else 0)),'Wrong batch size case '..index)
    if code=='OK' then assert(result.speciesId==string.format('tier_%02d',tier)) end
end
print('PASS shared purchase quote prices, exact affordability, tier bounds, eligibility and server parity')
