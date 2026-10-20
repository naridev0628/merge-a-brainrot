local Economy=require('../src/shared/Economy')
local Core=require('../src/server/Domain/FarmCore')
local Config=table.clone(require('../src/shared/Config'))
Config.TransitSeconds=0 -- Conveyor arrival is tested independently in conveyor.luau.
local Catalog=require('../src/shared/CreatureCatalog')
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local c=Core.new(Config,Catalog)
local s=c:newSession(1,0,'sale')
eq(#s.state.producers,0)
local function cmd(action,args,now,x,z)
    return c:dispatch(s,action,args,{now=now,alive=true,position={x=x or Config.SellX,y=3,z=z or Config.SellZ}})
end
eq(cmd('Buy',{'free','1'},0,Config.BuyPads['1'],Config.BuyZ).code,'OK'); eq(s.state.coinUnits,0); eq(#s.state.producers,1)
eq(cmd('Buy',{'free','1'},0,Config.BuyPads['1'],Config.BuyZ).replayed,true); eq(#s.state.producers,1)
eq(cmd('Buy',{'notfree','1'},0,Config.BuyPads['1'],Config.BuyZ).code,'InsufficientFunds')
local first=Config.Interval
c:step(s,first)
local t=s.state.tokens[1]
eq(cmd('Collect',{t.id},first,t.x,t.z).code,'OK')
eq(cmd('Deposit',{'deposit'},first).code,'OK'); eq(Economy.count(s.state.bag),0); eq(s.state.coinUnits,0); eq(#s.state.saleQueue,1)
eq(cmd('Deposit',{'deposit'},first).replayed,true); eq(#s.state.saleQueue,1)
eq(cmd('Claim',{'early'},first,Config.ClaimX,Config.ClaimZ).code,'NothingReady')
c:step(s,first+.49); eq(s.state.soldUnits,0)
c:step(s,first+.5); eq(s.state.soldUnits,4); eq(s.state.coinUnits,0)
eq(cmd('Claim',{'cash'},first+.5,Config.ClaimX,Config.ClaimZ).code,'OK'); eq(s.state.coinUnits,4); eq(s.state.soldUnits,0)
eq(cmd('Claim',{'cash'},first+.5,Config.ClaimX,Config.ClaimZ).replayed,true); eq(s.state.coinUnits,4)
c:setPasses(s,{cash2=true,cash4=true,cash8=true,autoCollect=true})
eq(s.state.cashMultiplier,8)
local nextDrop=first+Config.Interval
c:step(s,nextDrop); eq(#s.state.tokens,0); eq(Economy.count(s.state.bag),0); eq(#s.state.saleQueue,1)
c:step(s,nextDrop+.5); eq(s.state.soldUnits,32); eq(s.state.coinUnits,4)
c:setPasses(s,{cash8=true,autoCollect=true,autoSell=true})
c:step(s,nextDrop+.75); eq(s.state.coinUnits,36); eq(s.state.soldUnits,0)
print('PASS starter purchase, physical collection, timed deposit, explicit payout and separate automation passes')
