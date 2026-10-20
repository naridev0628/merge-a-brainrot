local Config=require('../src/shared/Config')
local Core=require('../src/server/Domain/FarmCore')
local Catalog=require('../src/shared/CreatureCatalog')
local Economy=require('../src/shared/Economy')

assert(#Config.ProcessorRates==#Config.ProcessorCosts+1)
assert(Config.ProcessorCosts[1]==40 and Config.ProcessorCosts[2]==120,'Keep the established opening upgrades')
local previousSeconds=0
for index,cost in Config.ProcessorCosts do
    local rate,nextRate=Config.ProcessorRates[index],Config.ProcessorRates[index+1]
    local dollars=cost/4 -- Baseline: each individual Mini sells for $1.
    local earnSeconds=dollars/rate
    local paybackSeconds=dollars/(nextRate-rate)
    assert(cost%4==0 and cost>0 and cost<Config.CoinCap)
    assert(nextRate>rate and (index==1 or cost>Config.ProcessorCosts[index-1]))
    assert(earnSeconds>=5 and earnSeconds<=12,`Upgrade {index} stalls for {earnSeconds} seconds of full throughput`)
    assert(earnSeconds>=previousSeconds and earnSeconds-previousSeconds<=5,'Smooth earning-time progression')
    assert(paybackSeconds<=20,`Upgrade {index} incremental payback exceeds 20 seconds`)
    previousSeconds=earnSeconds

    -- Earn the exact price from actual sales; upgrade with a live backlog.
    -- This exercises quarter-dollar pricing, all level indexes, and acceleration
    -- without boosts or extra producer revenue being assumed.
    local core=Core.new(Config,Catalog,function() return 1 end)
    local session=core:newSession(index,0,'processor-'..index)
    session.state.processorLevel=index-1
    session.state.coinUnits=0
    local function command(action,id,now,x,z)
        return core:dispatch(session,action,{id},{now=now,alive=true,position={x=x,y=0,z=z}})
    end
    assert(command('Upgrade','poor',0,Config.UpgradeX,Config.UpgradeZ).code=='InsufficientFunds')
    -- High-level prices exceed one bag. Feed real bounded bags until funded.
    local now,remaining,batch=0,dollars,0
    while remaining>0 do
        batch+=1
        local count=math.min(Config.BagCap,remaining)
        session.state.bag={{speciesId='tier_01',baseCoinValue=1,count=count}}
        assert(command('Deposit','fund-'..batch,now,Config.SellX,Config.SellZ).code=='OK')
        now+=count/rate+1e-6
        core:step(session,now)
        assert(command('Claim','claim-'..batch,now,Config.ClaimX,Config.ClaimZ).code=='OK')
        remaining-=count
    end
    assert(session.state.coinUnits==cost,`Upgrade {index} must be funded by its advertised price`)
    session.state.bag={{speciesId='tier_01',baseCoinValue=1,count=math.min(Config.BagCap,nextRate*2)}}
    assert(command('Deposit','backlog',now,Config.SellX,Config.SellZ).code=='OK')
    assert(command('Upgrade','upgrade',now,Config.UpgradeX,Config.UpgradeZ).code=='OK')
    assert(session.state.processorLevel==index and session.state.coinUnits==0)
    local queued=Economy.count(session.state.saleQueue)
    assert(math.abs(session.state.saleQueue[1].interval-1/nextRate)<1e-12)
    now+=queued/nextRate+1e-6
    core:step(session,now)
    assert(Economy.count(session.state.saleQueue)==0,`Upgrade {index} must finish its backlog at the new rate`)
    assert(session.state.soldUnits==queued*4,'Logical Minis must be valued once')
    assert(command('Upgrade','upgrade',now,Config.UpgradeX,Config.UpgradeZ).replayed)
    assert(session.state.processorLevel==index,'Retry must not upgrade twice')
    assert(core:validate(session.state,index))
end
print('PASS all '..#Config.ProcessorCosts..' processor prices, bounded earning time/payback, earned purchases, queue acceleration and replay')
