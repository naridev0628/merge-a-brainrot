local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local c=Core.new(Config,Catalog,function()return 1 end)
local s=c:newSession(1,0,'queue')
local function put(id,value,count,now)
    s.state.bag={{speciesId=if value==2 then 'tier_01' else 'tier_02',baseCoinValue=value,count=count}}
    return c:dispatch(s,'Deposit',{id},{now=now,alive=true,position={x=Config.SellX,y=0,z=Config.SellZ}})
end
assert(put('first',2,1,0).code=='OK')
assert(put('second',5,1,.25).code=='OK')
assert(s.state.saleQueue[1].due==.5,'Redeposit must not restart current sale')
assert(put('third',2,1,.3).code=='OK')
assert(#s.state.saleQueue==3 and s.state.saleQueue[2].units==20,'New low-value goods must not jump the queue')
c:step(s,1)
assert(s.state.soldUnits==28 and #s.state.saleQueue==1)
-- At 10/s, commands can arrive after multiple completions between .25s ticks.
s.state.processorLevel=2;s.state.coinUnits=10000;s.state.soldUnits=0
s.state.saleQueue={{units=8,due=1,count=2,interval=.1},{units=20,due=1.2,count=1,interval=.1}}
local upgrade=c:dispatch(s,'Upgrade',{'upgrade'},{now=1.21,alive=true,position={x=Config.UpgradeX,y=0,z=Config.UpgradeZ}})
assert(upgrade.code=='OK',upgrade.code)
assert(s.state.soldUnits==36 and #s.state.saleQueue==0)
print('PASS redeposit timing, FIFO batch order and upgrade between processor ticks')
