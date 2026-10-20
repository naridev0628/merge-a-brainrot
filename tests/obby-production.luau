local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local core=Core.new(Config,Catalog,function() return 1 end)
local serial=0
local function session(event,bonus,pass)
    serial+=1
    local s=core:newSession(serial,0,'obby-production-'..serial)
    assert(s.state.obbyBonusHundredths==0,'New sessions must start without an earned bonus')
    assert(core:dispatch(s,'Buy',{'starter','1'},
        {now=0,alive=true,position={x=Config.BuyPads['1'],y=0,z=Config.BuyZ}}).code=='OK')
    core:setEvent(s,event)
    if bonus>0 then assert(core:setObbyBonus(s,bonus)) end
    if pass then core:setPasses(s,{mini2=true}) end
    return s
end
local function produce(s,from,count)
    local drops,credits={},{}
    for index=from,from+count-1 do
        assert(core:step(s,index*Config.Interval))
        drops[#drops+1]=#s.state.tokens
        credits[#credits+1]=s.state.producers[1].productionCredit
        for _,token in s.state.tokens do
            assert(token.baseCoinValue==Catalog[token.speciesId].value,'Production bonus must not change per-Mini cash value')
        end
        assert(core:validate(s.state,s.owner))
        -- Simulate collecting between ticks so the production test is not tray-capped.
        s.state.tokens={}
    end
    return table.concat(drops,','),table.concat(credits,',')
end
local normal=session(100,25,false)
local drops,credit=produce(normal,1,4)
assert(drops=='1,1,1,1' and credit=='0,0,0,0','Obby bonus must not inflate raw production')
local pass=session(100,25,true)
drops,credit=produce(pass,1,4)
assert(drops=='2,2,2,2' and credit=='0,0,0,0','Mini pass independently doubles raw production')
local low=session(50,25,false)
drops,credit=produce(low,1,4)
assert(drops=='1,1,1,1' and credit=='0,0,0,0','A low deposit multiplier must not slow raw production')
local high=session(150,25,true)
drops,credit=produce(high,1,4)
assert(drops=='2,2,2,2' and credit=='0,0,0,0','Event and obby bonuses must not multiply raw production twice')
assert(high.state.eventHundredths==150,'Obby bonus must not overwrite the shared world event')
local maximum=session(150,100,true)
assert(produce(maximum,1,1)=='2','Maximum validated bonus must retain bounded integer production')

local expiry=session(100,25,false)
produce(expiry,1,2)
assert(core:setObbyBonus(expiry,0),'Expiry must commit removal of the earned bonus')
drops,credit=produce(expiry,3,4)
assert(drops=='1,1,1,1' and credit=='0,0,0,0','Bonus expiry must not change raw production')
local unchanged=expiry.state
assert(not core:setObbyBonus(expiry,0) and expiry.state==unchanged,'An unchanged value must not create a revision or replace state')

local invalid=session(100,25,false)
for _,value in {-1,101,.5,math.huge,-math.huge,0/0,'25',false,{}} do
    local before=invalid.state
    local revision=before.revision
    assert(not core:setObbyBonus(invalid,value),'Only integer bonus hundredths 0..100 are accepted')
    assert(invalid.state==before and invalid.state.revision==revision and invalid.state.obbyBonusHundredths==25,
        'Invalid bonus input must not mutate authoritative state')
end
assert(not core:setObbyBonus(invalid,nil))
local malformed=core:snapshot(invalid);malformed.obbyBonusHundredths=false
assert(not core:validate(malformed,invalid.owner),'False must not be treated as a missing optional bonus')
malformed=core:snapshot(invalid);malformed.eventHundredths=151
assert(not core:validate(malformed,invalid.owner),'World event range must remain 50..150')
malformed=core:snapshot(invalid);malformed.producers[1].productionCredit=100
assert(not core:validate(malformed,invalid.owner),'Carried production credit must remain 0..99')
invalid.phase='Closed'
local before=invalid.state
assert(not core:setObbyBonus(invalid,0) and invalid.state==before,'Closed sessions cannot receive server rewards')

local legacy=session(100,0,false)
legacy.state.obbyBonusHundredths=nil
assert(core:validate(legacy.state,legacy.owner),'Legacy states without an obby field remain valid')
assert(produce(legacy,1,2)=='1,1','Missing optional bonus must mean zero')
assert(core:setObbyBonus(legacy,25) and legacy.state.obbyBonusHundredths==25)

local rebirth=session(100,25,true)
rebirth.state.producers[1].speciesId='tier_06'
rebirth.state.coinUnits=Config.RebirthBase
assert(core:dispatch(rebirth,'Rebirth',{'rebirth'},
    {now=0,alive=true,position={x=0,y=0,z=Config.MergeZ}}).code=='OK')
assert(rebirth.state.obbyBonusHundredths==25 and rebirth.state.miniMultiplier==2,
    'Rebirth must keep the earned bonus and pass while the external run owns its timer')
assert(produce(rebirth,1,2)=='2,2')

-- Deposit must preserve base value, cash pass and rebirth math independently.
local sale=session(150,25,true)
sale.state.rebirths=2
core:setPasses(sale,{mini2=true,cash4=true})
sale.state.bag={{speciesId='tier_01',baseCoinValue=2,count=1}}
assert(core:dispatch(sale,'Deposit',{'deposit'},
    {now=0,alive=true,position={x=Config.SellX,y=0,z=Config.SellZ}}).code=='OK')
assert(sale.state.saleQueue[1].units==2*(4+2)*4,'Production boost must never multiply each Mini sale value')
print('PASS obby-independent raw production, Mini pass, expiry, rebirth, legacy states, invalid inputs and unchanged cash value')
