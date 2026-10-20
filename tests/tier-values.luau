local Economy=require('../src/shared/Economy')
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local core=Core.new(Config,Catalog,function() return 1 end)
local payouts={}
for tier=1,6 do
    local id=string.format('tier_%02d',tier)
    local s=core:newSession(tier,0,'value'..tier)
    s.state.starterClaimed=true;s.state.discoveries[id]=true
    s.state.producers={{id='producer',speciesId=id,slot=1,due=6}}
    assert(core:step(s,6)); assert(#s.state.tokens==1,'Every level drops the same count')
    local t=s.state.tokens[1];assert(t.baseCoinValue==Catalog[id].value)
    assert(core:dispatch(s,'Collect',{t.id},{now=t.readyAt,alive=true,position=t}).code=='OK')
    assert(core:dispatch(s,'Deposit',{'deposit'},{now=11,alive=true,position={x=Config.SellX,y=3,z=Config.SellZ}}).code=='OK')
    core:step(s,11.6)
    assert(core:dispatch(s,'Claim',{'claim'},{now=11.6,alive=true,position={x=Config.ClaimX,y=3,z=Config.ClaimZ}}).code=='OK')
    payouts[tier]=(s.state.coinUnits-Config.StartingUnits)/4
    assert(payouts[tier]==Catalog[id].value)
    if tier>1 then assert(payouts[tier]>payouts[tier-1]) end
end
assert(payouts[1]==2 and payouts[3]==12,'Ballerina must pay six times TungTung per Mini')
print('PASS identical drop counts, increasing tier values, Ballerina payout $12 versus TungTung $2')
