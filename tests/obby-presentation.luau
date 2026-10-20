local Presentation=require('../src/shared/ObbyPresentation')
local function packet(now,phase,checkpoint,expires,cooldown,bonus,revision,key)
    return {status='Ready',sessionKey=key or 'farm-a',revision=revision or 1,serverNow=now,
        obby={phase=phase,checkpoint=checkpoint or 0,totalCheckpoints=10,
            boostExpiresAt=expires or 0,cooldownEndsAt=cooldown or 0,bonusHundredths=bonus or 0}}
end
local presentation=Presentation.new()
assert(presentation:read(9000)==nil,'No state must not advertise an available reward')
local accepted,finish=presentation:receive(packet(100,'idle'),9000)
assert(accepted and not finish and presentation:read(9000).text=='Obby available now!')
-- Obby progress can change while the farm economy revision remains unchanged.
for checkpoint=1,10 do
    accepted,finish=presentation:receive(packet(100+checkpoint,'running',checkpoint),9000+checkpoint)
    assert(accepted and not finish)
    assert(presentation:read(9000+checkpoint).text=='Obby: step '..checkpoint..' / 10')
end
local completion=packet(111,'cooldown',0,411,711,25)
accepted,finish=presentation:receive(completion,9011)
assert(accepted and finish,'A newly observed finish must notify once')
assert(presentation:read(9011).text=='+0.25x Minis • 5:00')
assert(presentation:read(9012).text=='+0.25x Minis • 4:59','Use elapsed receipt time with the SERVER deadline')
assert(presentation:read(9011.1).kind=='bonus')
accepted,finish=presentation:receive(completion,9012)
assert(not accepted and not finish,'Exact replay must not reset the clock or replay completion')
assert(presentation:read(9012).text=='+0.25x Minis • 4:59')
completion.obby.bonusHundredths=99
assert(presentation:read(9012).text=='+0.25x Minis • 4:59','Store a copy of presentation state')
accepted,finish=presentation:receive(packet(110,'running',9,0,0,0,2),9013)
assert(not accepted and not finish,'An older server timestamp cannot overwrite newer progress')
accepted,finish=presentation:receive(packet(112,'cooldown',0,411,711,25),9012)
assert(accepted and not finish,'Later snapshots of the same award must not replay completion')
assert(presentation:read(9311).text=='Obby ready in 5:00','Expired bonus must reveal cooldown without waiting for another snapshot')
assert(presentation:read(9611).text=='Obby available now!','Expired cooldown must become ready locally')
accepted,finish=presentation:receive(packet(713,'cooldown',0,1013,1313,25),9613)
assert(accepted and finish,'A later earned deadline can notify once again')
accepted,finish=presentation:receive(packet(714,'cooldown',0,1013,1313,25),9614)
assert(accepted and not finish)

local joined=Presentation.new()
accepted,finish=joined:receive(packet(200,'cooldown',0,411,711,25),50)
assert(accepted and not finish,'Joining with an existing bonus must be quiet')
assert(joined:read(51).text=='+0.25x Minis • 3:30','Local and server clocks can have arbitrary offsets')
accepted,finish=joined:receive(packet(201,'cooldown',0,411,711,25,1,'farm-b'),51)
assert(accepted and not finish,'A changed session establishes a quiet baseline')
joined:clear()
assert(joined:read(52)==nil)
accepted,finish=joined:receive(packet(202,'cooldown',0,411,711,25,1,'farm-b'),52)
assert(accepted and not finish,'Temporary unavailable state must preserve award deduplication')
accepted,finish=joined:receive(packet(203,'cooldown',0,411,711,25,0,'farm-b'),53)
assert(not accepted and not finish,'Old revisions must not replace the current timer')

local late=Presentation.new()
late:receive(packet(100,'idle'),0)
accepted,finish=late:receive(packet(500,'cooldown',0,411,711,25),400)
assert(accepted and not finish and late:read(400).text=='Obby ready in 3:31','An already expired award must not play a finish cue')
for _,bad in {0/0,math.huge,-1} do
    local invalid=packet(bad,'idle')
    assert(not late:receive(invalid,401),'Invalid clock samples must be rejected')
end
local invalid=packet(501,'running',11)
assert(not late:receive(invalid,401),'Invalid progress must be rejected')
assert(late:read(400).text=='Obby ready in 3:31','Rejected state must leave the last valid display intact')
print('PASS obby full-run status, server-clock countdowns, expiry/ready transitions, quiet join, deduplicated finishes and stale snapshot rejection')
