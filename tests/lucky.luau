local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local roll=0
local core=Core.new(Config,Catalog,function() return roll end)
local s=core:newSession(1,0,'lucky')
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function cmd(action,args,x,z) return core:dispatch(s,action,args,{now=6,alive=true,position={x=x or 0,y=3,z=z or 24}}) end
eq(cmd('Buy',{'free'},Config.BuyPads['1'],34).code,'OK')
core:step(s,12); assert(s.state.lucky); eq(s.state.lucky.baseTier,2)
local block=s.state.lucky.id
eq(cmd('OpenLucky',{'open',block,'200'}).code,'InsufficientFunds')
s.state.coinUnits=1000
eq(cmd('OpenLucky',{'stale',block,'1'}).code,'PriceChanged'); eq(s.state.coinUnits,1000)
eq(cmd('OpenLucky',{'far',block,'200'},99,99).code,'TooFar')
roll=.97
local result=cmd('OpenLucky',{'open',block,'200'}); eq(result.code,'OK'); eq(result.speciesId,'tier_04')
eq(s.state.coinUnits,800); eq(#s.state.producers,2); eq(s.state.lucky,nil); eq(s.state.discoveries.tier_04,true)
eq(cmd('OpenLucky',{'open',block,'200'}).replayed,true); eq(s.state.coinUnits,800)
eq(cmd('OpenLucky',{'again',block,'200'}).code,'MissingLucky')
roll=.001; core:step(s,18); eq(s.state.lucky,nil)
roll=.00099; core:step(s,24); assert(s.state.lucky); local original=s.state.lucky.id
core:step(s,30); eq(s.state.lucky.id,original)
print('PASS Lucky drop boundary, price quote, distance, exact reward, replay and single-block limit')
