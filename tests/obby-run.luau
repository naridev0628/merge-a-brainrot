local Config=require('../src/shared/ObbyConfig')
local Run=require('../src/server/Domain/ObbyRun')
local function position(p)
    return {x=p.x,y=p.y,z=p.z}
end
local function sample(run,now,p,alive,reset)
    return run:update({now=now,position=p,alive=alive~=false,reset=reset})
end
local function target(index)
    return if index<=#Config.Checkpoints then Config.Checkpoints[index] else Config.Finish
end
local function land(run,index,now)
    local dest=target(index)
    if index>1 then
        local previous=target(index-1)
        local air={x=(previous.x+dest.x)/2,y=previous.y+4.5,z=(previous.z+dest.z)/2}
        assert(sample(run,now+.3,air).event=='none','A jump alone must not award a checkpoint')
        now+=.7
    end
    local result=sample(run,now,position(dest))
    assert(result.event=='none','A first contact must wait for a confirmed landing')
    now+=Config.LandingHoldSeconds+.01
    result=sample(run,now,position(dest))
    assert(result.event==(if index<=#Config.Checkpoints then 'checkpoint' else 'finish'),
        'An ordered, observed jump and landing should advance')
    return now,result
end
local function complete(run,now)
    local result
    for index=1,#Config.Checkpoints+1 do now,result=land(run,index,now) end
    return now,result
end

local run=Run.new(Config)
local now,result=complete(run,10)
assert(result.bonusHundredths==25 and result.boostExpiresAt==now+300)
assert(result.cooldownEndsAt==now+600 and result.checkpoint==0,'Finish must award once and clear run progress')
local awardedAt=now
for index=1,100 do
    result=sample(run,now+index*.01,position(Config.Finish))
    assert(result.event~='finish' and result.boostExpiresAt==awardedAt+300,'Repeated finish samples must not extend rewards')
end
result=sample(run,now+10,position(Config.Checkpoints[1]))
assert(result.event=='cooldown' and result.checkpoint==0 and result.bonusHundredths==25)
result=sample(run,now+10.1,position(Config.Checkpoints[1]))
assert(result.event=='none','Standing in a blocked start must not spam cooldown events')
result=sample(run,awardedAt+300,position(Config.Checkpoints[1]))
assert(result.boostExpired and result.bonusHundredths==0 and math.abs(result.cooldownRemaining-300)<1e-6)
result=sample(run,awardedAt+300.1,position(Config.Checkpoints[1]))
assert(not result.boostExpired,'Expiry notification must occur once')
now=awardedAt+600
now,result=complete(run,now)
assert(result.event=='finish' and result.bonusHundredths==25,'A full run can earn a fresh bonus after cooldown')

-- No claimed checkpoint IDs: only authoritative position samples advance.
for _,index in {2,5,10,11} do
    local attempt=Run.new(Config)
    result=sample(attempt,0,position(target(index)))
    result=sample(attempt,1,position(target(index)))
    assert(result.checkpoint==0 and result.bonusHundredths==0,'Starting midway or at finish must not reward')
end
local skip=Run.new(Config)
now=land(skip,1,0)
result=sample(skip,now+1,position(Config.Checkpoints[3]))
assert(result.event=='retry' and result.reason=='SkippedCheckpoint' and result.checkpoint==0)

local fall=Run.new(Config)
now=land(fall,1,0)
now=land(fall,2,now)
local below=position(Config.Checkpoints[2]);below.y-=Config.FallBelowCheckpoint+.1
result=sample(fall,now+.2,below)
assert(result.event=='retry' and result.reason=='Fell' and result.cooldownRemaining==0)
now=land(fall,1,now+1)
assert(fall:snapshot().checkpoint==1,'A fall must allow an immediate new attempt without reward cooldown')

for _,reset in {'Home','Teleport','Respawn'} do
    local attempt=Run.new(Config)
    now=land(attempt,1,0)
    now=land(attempt,2,now)
    result=sample(attempt,now+.1,position(Config.Finish),true,reset)
    assert(result.event=='retry' and result.reason==reset and result.checkpoint==0)
    result=sample(attempt,now+.3,position(Config.Finish))
    assert(result.bonusHundredths==0,'A reset/teleport must never award the finish')
end
local death=Run.new(Config)
now=land(death,1,0)
result=sample(death,now+.1,position(Config.Finish),false)
assert(result.event=='retry' and result.reason=='Dead' and result.checkpoint==0)
result=sample(death,now+.2,position(Config.Finish))
assert(result.bonusHundredths==0,'Respawning at the finish cannot restore a dead run')

-- Even in order, instant teleports and unobserved jumps are not a valid run.
local teleport=Run.new(Config)
now=land(teleport,1,0)
result=sample(teleport,now+.01,position(Config.Checkpoints[2]))
assert(result.event=='retry' and result.reason=='ImpossibleMovement')
local noJump=Run.new(Config)
now=land(noJump,1,0)
result=sample(noJump,now+1,position(Config.Checkpoints[2]))
assert(result.event=='retry' and result.reason=='UnobservedJump')
local returned=Run.new(Config)
now=land(returned,1,0)
local previous,nextPad=Config.Checkpoints[1],Config.Checkpoints[2]
sample(returned,now+.3,{x=(previous.x+nextPad.x)/2,y=previous.y+4.5,z=(previous.z+nextPad.z)/2})
sample(returned,now+.7,position(previous))
result=sample(returned,now+1.5,position(nextPad))
assert(result.event=='retry' and result.reason=='UnobservedJump','Landing back must discard airborne evidence from an abandoned jump')
local gap=Run.new(Config)
now=land(gap,1,0)
result=sample(gap,now+Config.MaximumObservationGap+.1,position(Config.Checkpoints[2]))
assert(result.event=='retry' and result.reason=='ObservationGap')

-- Footprints include corners, require actual top height, and need two samples.
local corner=Run.new(Config)
local p=position(Config.Checkpoints[1]);p.x+=2.5;p.z-=2.5
assert(sample(corner,0,p).checkpoint==0)
assert(sample(corner,.11,p).checkpoint==1,'Full platform corners must be valid landings')
local over=Run.new(Config)
p=position(Config.Checkpoints[1]);p.y+=Config.FootAboveTolerance+.01
assert(sample(over,0,p).checkpoint==0 and sample(over,1,p).checkpoint==0,'Flying above a checkpoint is not a landing')
local fleeting=Run.new(Config)
local first=position(Config.Checkpoints[1])
sample(fleeting,0,first)
p=position(first);p.x+=5
sample(fleeting,.05,p)
assert(sample(fleeting,.1,first).checkpoint==0,'Interrupted contact cannot accumulate landing time')

-- Time/coordinates are validated and bounded before arithmetic; errors fail closed.
for _,bad in {0/0,math.huge,-math.huge,-1,Config.MaximumTimestamp+1} do
    local attempt=Run.new(Config)
    land(attempt,1,10)
    result=sample(attempt,bad,position(Config.Finish))
    assert(result.event=='retry' and result.reason=='InvalidTime' and result.checkpoint==0)
end
local backwards=Run.new(Config)
now=land(backwards,1,10)
result=sample(backwards,now-.01,position(Config.Checkpoints[2]))
assert(result.reason=='InvalidTime' and result.checkpoint==0,'Backward clocks must not advance a run')
for _,bad in {{x=0/0,y=0,z=0},{x=math.huge,y=0,z=0},{x=Config.MaximumCoordinate+1,y=0,z=0},{}} do
    local attempt=Run.new(Config)
    now=land(attempt,1,0)
    result=sample(attempt,now+.1,bad)
    assert(result.reason=='InvalidPosition' and result.checkpoint==0)
end
local timeout=Run.new(Config)
now=land(timeout,1,0)
for _=1,math.ceil(Config.MaximumRunSeconds) do
    now+=1;result=sample(timeout,now,position(Config.Checkpoints[1]))
end
assert(result.event=='retry' and result.reason=='RunTimeout')
local outside=Run.new(Config)
now=land(outside,1,0)
result=sample(outside,now+1,{x=25,y=8,z=0})
assert(result.event=='retry' and result.reason=='LeftCourse')

-- Death/Home cancel attempts, not an already earned bonus; snapshots are copies.
local earned=Run.new(Config)
now,result=complete(earned,0)
local expires=result.boostExpiresAt
result=sample(earned,now+.1,nil,false,'Home')
assert(result.bonusHundredths==25 and result.boostExpiresAt==expires)
local copy=earned:snapshot();copy.bonusHundredths=900;copy.checkpoint=10
assert(earned:snapshot().bonusHundredths==25 and earned:snapshot().checkpoint==0)
local badConfig=table.clone(Config);badConfig.BoostSeconds=math.huge
assert(not pcall(Run.new,badConfig),'Invalid configuration must fail before creating a run')
local limitedConfig=table.clone(Config);limitedConfig.MaximumTimestamp=1000
local limited=Run.new(limitedConfig)
now,result=complete(limited,390)
result=sample(limited,1000,nil,false)
assert(result.boostExpired and result.bonusHundredths==0 and result.cooldownRemaining==0,
    'Valid late samples must expire rewards even near the configured clock ceiling')
local noRoom=Run.new(limitedConfig)
now=399
for index=1,#Config.Checkpoints do now=land(noRoom,index,now) end
local from,to=Config.Checkpoints[10],Config.Finish
sample(noRoom,now+.3,{x=(from.x+to.x)/2,y=from.y+4.5,z=(from.z+to.z)/2})
sample(noRoom,now+.7,position(to))
result=sample(noRoom,now+.81,position(to))
assert(result.event=='retry' and result.reason=='ClockLimit' and result.boostExpiresAt==0,
    'A finish must not create truncated or overflowing reward timers')
assert(Config.BonusHundredths==25 and Config.BoostSeconds==300 and Config.CooldownSeconds==600)
print('PASS ordered obby, observed jumps/landings, one award, additive bonus, cooldown, expiry, retry, death/Home, bounds and invalid input')
