local Economy=require('../src/shared/Economy')
local Core=require('../src/server/Domain/FarmCore')
local Config=table.clone(require('../src/shared/Config'))
Config.TransitSeconds=0 -- Arrival timing has its own regression suite.
local Catalog=require('../src/shared/CreatureCatalog')
local Tutorial=require('../src/shared/Tutorial')
local function eq(a,b) assert(a==b or (type(a)=='number' and type(b)=='number' and math.abs(a-b)<1e-8),tostring(a)..' ~= '..tostring(b)) end
local core=Core.new(Config,Catalog); local s=core:newSession(7,0,'progress')
local function command(action,args,now,x,z)
    return core:dispatch(s,action,args,{now=now,alive=true,position={x=x or Config.SellX,y=3,z=z or Config.SellZ}})
end
eq(Tutorial.goal(s.state).kind,'Buy')
eq(command('Buy',{'starter'},0,Config.BuyPads['1'],Config.BuyZ).code,'OK')
eq(Tutorial.goal(s.state).kind,'Collect')
eq(s.state.coinUnits,0)
for i=1,5 do
    core:step(s,i*Config.Interval); local t=s.state.tokens[1]
    eq(command('Collect',{t.id},i*Config.Interval,t.x,t.z).code,'OK')
end
eq(Tutorial.goal(s.state).kind,'Deposit')
eq(command('Deposit',{'deposit'},18).code,'OK')
eq(Tutorial.goal(s.state).kind,'Wait')
core:step(s,21); eq(Tutorial.goal(s.state).kind,'Claim')
eq(command('Claim',{'claim'},21,Config.ClaimX,Config.ClaimZ).code,'OK'); eq(s.state.coinUnits,20)
eq(Tutorial.goal(s.state).kind,'Buy')
eq(command('Buy',{'buy'},21,Config.BuyPads['1'],Config.BuyZ).code,'OK'); eq(Tutorial.goal(s.state).kind,'Collect')
for now=21,23 do
    core:step(s,now)
    while #s.state.tokens>0 do
        local token=s.state.tokens[1]
        eq(command('Collect',{token.id},now,token.x,token.z).code,'OK')
    end
end
eq(Economy.count(s.state.bag),6)
eq(command('Deposit',{'third-deposit'},23).code,'OK')
core:step(s,26)
eq(command('Claim',{'third-claim'},26,Config.ClaimX,Config.ClaimZ).code,'OK')
eq(command('Buy',{'third-buy'},26,Config.BuyPads['1'],Config.BuyZ).code,'OK')
eq(Tutorial.goal(s.state).kind,'Merge')
eq(command('Merge',{'merge',s.state.producers[1].id,s.state.producers[2].id,s.state.producers[3].id},26).code,'OK')
eq(Tutorial.goal(s.state).kind,'Done')
s.state.coinUnits=1000
s.state.bag={{speciesId='tier_02',baseCoinValue=5},{speciesId='tier_02',baseCoinValue=5}}
eq(command('Deposit',{'upgrade-deposit'},100).code,'OK')
eq(s.state.saleQueue[1].due,100.5); eq(s.state.saleQueue[1].count,2); eq(s.state.saleQueue[1].interval,.5)
eq(command('Upgrade',{'upgrade'},100,Config.UpgradeX,Config.UpgradeZ).code,'OK'); eq(s.state.processorLevel,1); eq(s.state.coinUnits,960)
eq(s.state.saleQueue[1].due,100.2); eq(s.state.saleQueue[1].interval,.2)
eq(command('Upgrade',{'upgrade'},100,Config.UpgradeX,Config.UpgradeZ).replayed,true); eq(s.state.coinUnits,960)
s.state.coinUnits=119
eq(command('Upgrade',{'poor'},100,Config.UpgradeX,Config.UpgradeZ).code,'InsufficientFunds')
core:setPasses(s,{mini2=true}); s.state.tokens={}; s.state.producers[1].due=106
core:step(s,106); eq(#s.state.tokens,2)
local fifth=core:slotPosition(50); eq(fifth.y,Config.DisplayPlatformHeight+4*Config.RowHeight)
print('PASS complete tutorial, processor queue acceleration, upgrade replay, double Minis and five-row cap')
