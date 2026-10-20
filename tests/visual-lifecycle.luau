local Lifecycle=require('../src/client/Controllers/VisualLifecycle')
local Queue=require('../src/client/Controllers/VisualQueue')
local function clock()
    local timers={}
    local function schedule(seconds,callback)
        local timer={seconds=seconds,callback=callback,cancelled=false}
        table.insert(timers,timer)
        return function() timer.cancelled=true end
    end
    return schedule,timers
end
local schedule,timers=clock()
local finished,cleaned,callbacks=0,0,0
local scope=Lifecycle.new(schedule,function() finished+=1 end)
scope:own(function() cleaned+=1 end)
local loaded,cancelled=nil,0
scope:load(function(done) loaded=done;return function() cancelled+=1 end end,3,function(ok,reason)
    assert(not ok and reason=='timeout');callbacks+=1
    scope:after(2,function() scope:finish('complete') end)
end)
assert(scope:alive() and callbacks==0)
timers[1].callback()
assert(callbacks==1 and cancelled==1,'Timeout must release the suspended loader and advance the visual')
loaded(true)
assert(callbacks==1,'A late load cannot reveal twice')
timers[2].callback()
assert(finished==1 and cleaned==1 and not scope:alive())
scope:finish('cancelled');timers[1].callback();timers[2].callback();loaded(false)
assert(finished==1 and callbacks==1 and cleaned==1,'All completion paths must be idempotent')

schedule,timers=clock()
local completed,stopped,shown=0,0,0
local finishReason=nil
scope=Lifecycle.new(schedule,function(reason) completed+=1;finishReason=reason end)
scope:load(function(done) loaded=done;return function() stopped+=1 end end,3,function() shown+=1 end)
scope:after(1,function() shown+=1 end)
scope:finish('cancelled')
assert(completed==1 and finishReason=='cancelled' and stopped==1 and shown==0,'UI cancellation must release its lock without waiting for load or animation timers')
for _,timer in timers do assert(timer.cancelled);timer.callback() end
loaded(true)
assert(shown==0 and completed==1,'Cancelled callbacks must never touch destroyed UI')
scope:own(function() cleaned+=1 end)
assert(cleaned==2,'Resources registered after completion must release immediately')

schedule,timers=clock()
local success=0
scope=Lifecycle.new(schedule,function() completed+=1 end)
scope:load(function(done) done(true);return function() stopped+=1 end end,3,function(ok,reason)
    assert(ok and reason=='loaded');success+=1
end)
assert(success==1 and timers[1].cancelled,'Synchronous completion must cancel the timeout')
timers[1].callback()
assert(success==1)
scope:finish('complete')

schedule,timers=clock()
scope=Lifecycle.new(schedule,function() end)
scope:load(function() error('provider failure') end,3,function(ok,reason)
    assert(not ok and reason=='failed');success+=1
end)
assert(success==2,'A loader exception must become a terminal failed load')
scope:finish('complete')
local errors=0
scope=Lifecycle.new(schedule,function(reason) assert(reason=='error');errors+=1 end)
scope:run(function() error('visual construction failure') end)
scope:finish('complete')
assert(errors==1,'Construction/animation errors must still complete once')
schedule,timers=clock()
scope=Lifecycle.new(schedule,function() end)
for _=1,100 do
    scope:after(0,function() end)
    timers[#timers].callback()
    assert(next(scope.resources)==nil,'Completed queue-pump timers must not accumulate for the GUI lifetime')
end
scope:finish('complete')
local attempts,reports,released=0,0,0
scope=Lifecycle.new(schedule,function() attempts+=1;error('consumer failure') end,function() reports+=1 end)
scope:own(function() released+=1 end)
scope:finish('complete');scope:finish('complete')
assert(attempts==1 and reports==1 and released==1,'A throwing reveal callback must remain once-only and release owned resources')

local queue=Queue.new(6)
for index=1,6 do assert(queue:push('tier_'..index)) end
assert(not queue:push('extra') and not queue:push('tier_1'),'Queue must bound and coalesce a burst')
local first=queue:take()
assert(first=='tier_1' and not queue:push(first),'Active reveals must not accumulate duplicate pending copies')
queue:complete(first)
assert(queue:push(first),'A finished species may be revealed again later')
queue:clear()
assert(queue:take()==nil and queue:push(first),'Cancellation must release queued species references')
print('PASS visual timeout, cancellation, late/synchronous completion, once-only finish, errors and bounded coalesced reveals')
