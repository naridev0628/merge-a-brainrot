--!strict
local Limiter={}
function Limiter.allow(buckets: {[string]: any}, key: string, now: number, rate: number, capacity: number): boolean
    local b=buckets[key]
    if not b then b={tokens=capacity,time=now}; buckets[key]=b end
    b.tokens=math.min(capacity,b.tokens+math.max(0,now-b.time)*rate); b.time=now
    if b.tokens<1 then return false end
    b.tokens-=1
    return true
end
return Limiter
