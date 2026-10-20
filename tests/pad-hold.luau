local Hold=require('../src/shared/PadHold')
local hold=Hold.new()
Hold.update(hold,'Buy1',10)
assert(Hold.ready(hold,10),'Entry triggers immediately')
Hold.sent(hold,10)
assert(not Hold.ready(hold,10.1) and not Hold.ready(hold,10.49),'First repeat respects the half-second cadence')
assert(Hold.ready(hold,10.5),'Standing on Buy1 starts repeating after half a second')
Hold.sent(hold,12)
assert(not Hold.ready(hold,12.49),'Repeats must not use the old 0.1 second pace')
assert(Hold.ready(hold,12.5),'Repeat once every half second')
Hold.stop(hold)
assert(not Hold.ready(hold,20),'Hard capacity rejection stops holding')
Hold.update(hold,'Buy1',20);assert(not Hold.ready(hold,20),'Remaining on stopped pad never retries')
Hold.update(hold,nil,20);assert(not Hold.ready(hold,20))
Hold.update(hold,'Buy1',21);assert(Hold.ready(hold,21),'Leaving and reentering restores entry action')
Hold.sent(hold,21);Hold.update(hold,'Upgrade',21.1)
assert(Hold.ready(hold,21.1),'Changing pads triggers new entry')
Hold.sent(hold,21.1);assert(not Hold.ready(hold,22.9));assert(Hold.ready(hold,23.1))
Hold.update(hold,nil,23.11);Hold.update(hold,'Upgrade',23.12)
assert(Hold.ready(hold,23.12),'Reentry has no waiting period')
-- A transient position-replication rejection must retry without entering the
-- two-second hold delay or flooding the server's slowest pad rate (2/sec).
local Limiter=require('../src/server/Domain/RateLimiter')
local retry=Hold.new()
local bucket={}
Hold.update(retry,'AutoMerge',30)
for i=0,99 do
    local now=30+i*.05
    if Hold.ready(retry,now) then
        assert(Limiter.allow(bucket,'AutoMerge',now,2,3),'Boundary retries exhausted the pad bucket')
        Hold.sent(retry,now)
        Hold.retry(retry,now)
        assert(not Hold.ready(retry,now+.49),'A rejection must not create a tight resend loop')
        assert(Hold.ready(retry,now+.5),'Boundary retry should not wait two seconds')
    end
end
Hold.update(retry,nil,35);Hold.update(retry,'Buy1',35.01)
assert(Hold.ready(retry,35.01),'Leaving a rejected pad must not delay another entry')
Hold.sent(retry,35.01);Hold.retry(retry,35.1);Hold.stop(retry)
assert(not Hold.ready(retry,40),'A hard rejection overrides a pending boundary retry')
print('PASS immediate entry, held repeats, bounded boundary retries and hard-rejection stop')
