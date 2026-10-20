local Cache=require('../src/client/Controllers/AudioLoadCache')
local loads,completions,timers={},{},{}
local cache=Cache.new(function(id,done)
    loads[id]=(loads[id] or 0)+1
    completions[id]=done
end,function(_,callback) table.insert(timers,callback) end)
local outcomes={}
cache.request('available',function(ok) table.insert(outcomes,ok) end)
cache.request('available',function(ok) table.insert(outcomes,ok) end)
assert(loads.available==1,'Concurrent consumers must share one asset fetch')
assert(cache.status('available')=='loading')
completions.available(true)
assert(#outcomes==2 and outcomes[1] and outcomes[2],'All pending consumers must see success')
cache.request('available',function(ok) assert(ok);table.insert(outcomes,ok) end)
assert(loads.available==1 and #outcomes==3,'Ready assets must reuse the cached result')
timers[1]()
assert(cache.status('available')=='ready','A stale timeout must not revoke a loaded asset')

cache.request('denied')
completions.denied(false)
for _=1,100 do
    cache.request('denied',function(ok) assert(not ok) end)
end
assert(loads.denied==1 and cache.status('denied')=='failed','An unavailable asset must not be retried per action')

local notified=0
cache.request('stuck',function(ok) assert(not ok);notified+=1 end)
timers[#timers]()
assert(notified==1 and cache.status('stuck')=='failed','A stalled preload must settle without indefinite callbacks')
completions.stuck(true)
cache.request('stuck')
assert(notified==1 and loads.stuck==1 and cache.status('stuck')=='failed','Late success cannot replay music after timeout')

local throwing=Cache.new(function() error('simulated provider failure') end,function() end)
local failed=false
throwing.request('error',function(ok) failed=not ok end)
assert(failed and throwing.status('error')=='failed','Provider exceptions must become silent terminal failures')
print('PASS shared audio fetch, cached success/failure, bounded timeout, late completion and provider exceptions')
