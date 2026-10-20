local Wait=require('../src/server/Domain/PadEntryWait')
local Geometry=require('../src/shared/PadGeometry')
local Config=require('../src/shared/Config')
local Core=require('../src/server/Domain/FarmCore')
local Catalog=require('../src/shared/CreatureCatalog')
local function context(z,vz,x,y)
    return {now=0,alive=true,position={x=x or Config.BuyPads['1'],y=y or 0,z=z},
        padVelocity={x=-.1654,y=.00062,z=vz}}
end
local function run(initial,read,action,args)
    local now,pauses=0,0
    local result=Wait.resolve(Config,action or 'Buy',args or {'request','1'},initial,
        function() local value=read(now);value.now=now;return value end,
        function(seconds) assert(seconds>0 and seconds<=.025);now+=seconds;pauses+=1 end,
        function() return now end)
    return result,now,pauses
end
-- Captured native failure: acceleration velocity replicates before full entry.
local initial=context(59.13649,4.28374,44.00477,-.000143)
assert(not Geometry.contains(Config,'Buy',Geometry.entryPosition(Config,'Buy',initial.position,initial.padVelocity,'1'),'1'))
local resolved,elapsed,pauses=run(initial,function(now)
    return if now<.15 then initial else context(64.747,24.67)
end)
assert(elapsed>=.15 and elapsed<=.25 and pauses<=11)
assert(Geometry.contains(Config,'Buy',resolved.position,'1'),'Fresh server entry must be used')
local core=Core.new(Config,Catalog)
local session=core:newSession(1,0,'entry')
session.state.coinUnits=20
local result=core:dispatch(session,'Buy',{'first','1'},resolved)
assert(result.code=='OK' and #session.state.producers==1 and session.state.coinUnits==0,
    'Only the final authoritative observation reaches the first domain dispatch')
assert(session.cache.first.result.code=='OK','No early TooFar may poison the request cache')
local stalled,time,count=run(initial,function() return initial end)
assert(time>=.25 and time<.251 and count<=11)
local other=core:newSession(2,0,'timeout')
assert(core:dispatch(other,'Buy',{'far','1'},stalled).code=='TooFar','Timeout must not grant entry')
-- Even full walking speed cannot turn a still-outside foot into authorization.
-- The old velocity projection could accept this point immediately.
local fastOutside=context(Config.BuyZ-3.85-1,16/Config.PlotScale)
local actualFoot,fastTime=run(fastOutside,function() return fastOutside end)
assert(fastTime>=.25 and actualFoot.position==fastOutside.position)
assert(not Geometry.contains(Config,'Buy',actualFoot.position,'1'))
assert(core:dispatch(core:newSession(3,0,'unentered'),'Buy',{'still-outside','1'},actualFoot).code=='TooFar',
    'Velocity is only a wait gate; dispatch requires an actual observed foot inside')
for _,sample in {
    context(59,0),context(59,-16),context(50,100),context(59,16,44,8),context(59,16,44,-1),
} do
    local unchanged,t,n=run(sample,function() error('Ineligible request must not poll') end)
    assert(unchanged==sample and t==0 and n==0)
end
local dead=context(59,4);dead.alive=false
local unchanged,t=run(dead,function() error('Dead avatar cannot await') end)
assert(unchanged==dead and t==0)
for _,action in {'Rebirth','Collect','State'} do
    local _,duration=run(initial,function() error('Unrelated action must not poll') end,action)
    assert(duration==0)
end
local _,invalidTime=run(initial,function() error('Invalid quantity must not poll') end,'Buy',{'request','invalid'})
assert(invalidTime==0)
local reversed,reverseTime=run(initial,function() return context(59,-16) end)
assert(reverseTime==.025 and not Geometry.contains(Config,'Buy',reversed.position,'1'))
print('PASS measured acceleration packet wait, first-request OK, bounded timeout, no stationary/outgoing/far/vertical/dead/unrelated grants')
