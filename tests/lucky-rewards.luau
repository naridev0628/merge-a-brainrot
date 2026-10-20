local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local Rewards=require('../src/shared/LuckyRewards')
assert(type(Rewards.cost)=='function','Lucky price must scale with its actual reward pool through one shared quote')
assert(Rewards.cost(Config,{producers={{}},lucky={baseTier=2}})==200,'Keep the first Lucky block affordable')
for base=2,Config.MaxTier do
    local pool=Rewards.pool(Config,base)
    assert(#pool==3 and pool[1].chance==75 and pool[2].chance==20 and pool[3].chance==5)
    assert(pool[1].tier<pool[2].tier and pool[2].tier<pool[3].tier,'Every card must offer three distinct rewards')
    assert(pool[3].tier<=Config.MaxTier and pool[1].tier>=2)
    for _,case in {{0,1},{.749999,1},{.75,2},{.949999,2},{.95,3},{.999999,3}} do
        local roll,index=case[1],case[2]
        local core=Core.new(Config,Catalog,function() return roll end)
        local s=core:newSession(1,0,'reward')
        s.state.lucky={id='block',baseTier=base,held=true}
        -- A Lucky block can award the player's first producer.
        s.state.starterClaimed=true
        s.state.producers={{id='existing',speciesId='tier_01',slot=1,due=1}}
        local cost=Rewards.cost(Config,s.state)
        assert(cost/4==10*Catalog[pool[1].speciesId].production,'One-producer price must equal ten seconds of actual lowest-reward output')
        s.state.coinUnits=cost
        local result=core:dispatch(s,'OpenLucky',{'open','block',tostring(cost)},{now=0,alive=true,position={x=0,y=0,z=0}})
        assert(result.code=='OK',result.code)
        assert(Catalog[result.speciesId].tier==pool[index].tier,'Server roll must match exactly the displayed reward pool')
        assert(s.state.coinUnits==0,'Charge precisely the shared quote')
        local revision,producerCount=s.state.revision,#s.state.producers
        local replay=core:dispatch(s,'OpenLucky',{'open','block',tostring(cost)},{now=0,alive=true,position={x=0,y=0,z=0}})
        assert(replay.replayed and replay.speciesId==result.speciesId and s.state.revision==revision and #s.state.producers==producerCount,
            'A shared-price retry must not charge or roll again')
    end
end
assert(Rewards.cost(Config,{producers={{}},lucky={baseTier=25}})==28319042800000,'Top pool price must follow actual tier23 output')
local staleCore=Core.new(Config,Catalog,function() return .99 end)
local stale=staleCore:newSession(2,0,'stale-price')
stale.state.starterClaimed=true;stale.state.producers={{id='starter',speciesId='tier_01',slot=1,due=1}}
stale.state.lucky={id='expensive',baseTier=25,held=true};stale.state.coinUnits=Config.CoinCap
local snapshot=stale.state
assert(staleCore:dispatch(stale,'OpenLucky',{'stale','expensive','419430400'},{now=0,alive=true,position={x=0,y=0,z=0}}).code=='PriceChanged')
assert(stale.state==snapshot and stale.state.lucky~=nil,'An obsolete cheap quote must preserve cash and the held block')
local pool=Rewards.pool(Config,6)
assert(pool[1].tier==6 and pool[2].tier==7 and pool[3].tier==8,'Crocodilo must not occupy every upgraded reward slot')
print('PASS all Lucky pools distinct, 75/20/5 boundaries, ceiling handling and server/UI shared outcomes')
