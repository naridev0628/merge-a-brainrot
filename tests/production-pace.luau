local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local core=Core.new(Config,Catalog,function()return 1 end)
for tier=1,6 do
    local s=core:newSession(tier,0,'pace'..tier)
    assert(core:dispatch(s,'Buy',{'starter'},{now=0,alive=true,position={x=Config.BuyPads['1'],y=0,z=Config.BuyZ}}).code=='OK')
    s.state.producers[1].speciesId=string.format('tier_%02d',tier)
    core:step(s,.99);assert(#s.state.tokens==0)
    core:step(s,1);assert(#s.state.tokens==1,'Every producer must drop after one second, tier '..tier)
    core:step(s,2);assert(#s.state.tokens==2,'Every producer must repeat once per second')
    assert(s.state.tokens[1].baseCoinValue==Catalog[s.state.producers[1].speciesId].value)
end
local roll=1
local lucky=Core.new(Config,Catalog,function()return roll end)
local s=lucky:newSession(1,0,'capped-lucky')
assert(lucky:dispatch(s,'Buy',{'starter'},{now=0,alive=true,position={x=Config.BuyPads['1'],y=0,z=Config.BuyZ}}).code=='OK')
for second=1,8 do lucky:step(s,second) end
assert(#s.state.tokens==8 and not s.state.lucky)
roll=.005
lucky:step(s,9)
assert(s.state.lucky,'A capped tray must still roll the one-percent Lucky chance on production ticks')
assert(#s.state.tokens==8,'Lucky rolls must not exceed the Mini cap')
local block=s.state.lucky.id
lucky:step(s,10);assert(s.state.lucky.id==block,'Only one Lucky block can exist')
print('PASS one-second production for all tiers, retained values and Lucky rolls with capped tray')
