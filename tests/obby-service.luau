local Service=require('../src/server/Services/ObbyService')
local Core=require('../src/server/Domain/FarmCore')
local Config=require('../src/shared/Config')
local Catalog=require('../src/shared/CreatureCatalog')
local made=0
local FakeRun={}
function FakeRun.new()
    made+=1
    local state={phase='idle',checkpoint=0,totalCheckpoints=10,bonusHundredths=0,boostExpiresAt=0,cooldownEndsAt=0}
    return {
        snapshot=function() return table.clone(state) end,
        update=function(_,context)
            if context.reset then state.checkpoint=0;state.phase=if state.cooldownEndsAt>context.now then 'cooldown' else 'idle'
            elseif context.result then state=table.clone(context.result) end
            return table.clone(state)
        end,
    }
end
local core=Core.new(Config,Catalog)
local service=Service.new(core,FakeRun,{})
local first=core:newSession(1,0,'first')
local second=core:newSession(2,0,'second')
service:attach('a',first);service:attach('b',second)
assert(made==2)
local finished={phase='cooldown',checkpoint=0,totalCheckpoints=10,bonusHundredths=25,boostExpiresAt=310,cooldownEndsAt=610}
local changed,bonusChanged=service:update('a',{now=10,result=finished})
assert(changed and bonusChanged and first.state.obbyBonusHundredths==25)
assert((second.state.obbyBonusHundredths or 0)==0,'Rewards stay isolated by player')
local revision=first.state.revision
changed,bonusChanged=service:update('a',{now=11,result=finished})
assert(not changed and not bonusChanged and first.state.revision==revision,'Repeated polls must not commit or resend unchanged state')
service:reset('a','Respawn',12)
service:reset('a','Home',13)
assert(made==2 and first.state.obbyBonusHundredths==25,'Respawn/Home preserve the run object, earned bonus and cooldown')
assert(service:snapshot('a').cooldownEndsAt==610)
local copy=service:snapshot('a');copy.checkpoint=99
assert(service:snapshot('a').checkpoint==0,'Caller cannot mutate the run through snapshots')
local expired=table.clone(finished);expired.bonusHundredths=0;expired.boostExpiresAt=0
changed,bonusChanged=service:update('a',{now=310,result=expired})
assert(changed and bonusChanged and first.state.obbyBonusHundredths==0,'Expiry removes the production bonus')
local running={phase='running',checkpoint=2,totalCheckpoints=10,bonusHundredths=0,boostExpiresAt=0,cooldownEndsAt=0}
changed,bonusChanged=service:update('b',{now=20,result=running})
assert(changed and not bonusChanged,'Checkpoint progress updates UI without economy commits')
service:detach('a')
assert(service:snapshot('a')==nil)
assert(not service:update('a',{now=400,alive=false}),'Removed players cannot update a retained run')
assert(not service:step('a',{now=400,alive=false}),'Removed players cannot produce through a retained run')

-- Use the real run and economy for a scheduler boundary: the last 10 Hz poll
-- still had a bonus, but production may run at or after the award deadline.
local Run=require('../src/server/Domain/ObbyRun')
local ObbyConfig=require('../src/shared/ObbyConfig')
for index,case in {
    {offset=-.005,alive=true,drops=2,credit=0},
    {offset=0,alive=false,drops=1,credit=75},
    {offset=.04,alive=true,drops=1,credit=75},
} do
    local economy=Core.new(Config,Catalog,function() return 1 end)
    local bridge=Service.new(economy,Run,ObbyConfig)
    local farm=economy:newSession(index,0,'deadline-'..index)
    assert(economy:dispatch(farm,'Buy',{'starter','1'},
        {now=0,alive=true,position={x=Config.BuyPads['1'],y=0,z=Config.BuyZ}}).code=='OK')
    bridge:attach(index,farm)
    local now=0
    local function sample(at,position)
        bridge:update(index,{now=at,position=position,alive=true})
    end
    for checkpoint=1,#ObbyConfig.Checkpoints+1 do
        local target=if checkpoint<=#ObbyConfig.Checkpoints then ObbyConfig.Checkpoints[checkpoint] else ObbyConfig.Finish
        if checkpoint>1 then
            local previous=ObbyConfig.Checkpoints[checkpoint-1]
            sample(now+.3,{x=(previous.x+target.x)/2,y=previous.y+4.5,z=(previous.z+target.z)/2})
            now+=.7
        end
        sample(now,target)
        now+=ObbyConfig.LandingHoldSeconds+.01
        sample(now,target)
    end
    assert(farm.state.obbyBonusHundredths==25,'The real ordered run must award the production bonus')
    local deadline=bridge:snapshot(index).boostExpiresAt
    local tick=deadline+case.offset
    sample(deadline-.01,ObbyConfig.Finish)
    assert(farm.state.obbyBonusHundredths==25,'The preceding independent poll still sees an active bonus')
    farm.state.producers[1].productionCredit=75
    farm.state.producers[1].due=tick
    local stateChanged,farmChanged=bridge:step(index,{now=tick,alive=case.alive,position=ObbyConfig.Finish})
    assert(stateChanged and farmChanged)
    assert(#farm.state.tokens==case.drops and farm.state.producers[1].productionCredit==case.credit,
        'Production at or after expiry must not earn the extra quarter credit or extra Mini')
    assert(farm.state.tokens[1].spawnedAt==tick,'Run expiry and production must use the same server timestamp')
    assert(farm.state.obbyBonusHundredths==(if case.offset<0 then 25 else 0))
    local revisionAtTick=farm.state.revision
    stateChanged,farmChanged=bridge:step(index,{now=tick,alive=case.alive,position=ObbyConfig.Finish})
    assert(not stateChanged and not farmChanged and farm.state.revision==revisionAtTick,
        'A repeated production timestamp must not duplicate expiry commits or Minis')
    assert(economy:validate(farm.state,farm.owner))
end
print('PASS per-player reward bridge, no repeated commits, exact production expiry boundary, checkpoint updates, reset lifetime and detach')
