local Preferences=require('../src/shared/ClientPreferences')

local prefs=Preferences.new()
assert(prefs:get('sfxVolume')==1 and prefs:get('musicVolume')==.35,'Defaults must preserve SFX and keep music quiet')
local updates={}
local disconnect=prefs:subscribe('sfxVolume',function(value) table.insert(updates,value) end)
assert(#updates==1 and updates[1]==1,'Bindings must immediately receive the current value')
assert(prefs:set('sfxVolume',.4))
assert(#updates==2 and updates[2]==.4,'Accepted values must reach bindings')
assert(prefs:set('sfxVolume',.4) and #updates==2,'Unchanged settings must not replay callbacks')
assert(prefs:set('sfxVolume',-2) and prefs:get('sfxVolume')==0,'Volume must clamp at mute')
assert(prefs:set('sfxVolume',8) and prefs:get('sfxVolume')==1,'Volume must clamp at full volume')
for _,value in {'loud',false,math.huge,-math.huge,0/0} do
    local before=#updates
    assert(not prefs:set('sfxVolume',value),'Invalid values must be rejected')
    assert(prefs:get('sfxVolume')==1 and #updates==before,'Invalid values must not change settings or invoke bindings')
end
assert(not prefs:set('paidCash',100) and prefs:get('paidCash')==nil,'Only known cosmetic preferences may change')
local copy=prefs:snapshot()
copy.sfxVolume=.1
assert(prefs:get('sfxVolume')==1,'Snapshots must not expose mutable preference storage')
disconnect();disconnect()
local before=#updates
prefs:set('sfxVolume',.2)
assert(#updates==before,'Disconnected bindings must not run')
local musicUpdates={}
local stopMusic=prefs:subscribe('musicVolume',function(value) table.insert(musicUpdates,value) end)
prefs:set('musicVolume',0)
prefs:reset()
assert(prefs:get('sfxVolume')==1 and prefs:get('musicVolume')==.35,'Reset must restore both defaults')
assert(#musicUpdates==3 and musicUpdates[3]==.35,'Reset must notify live bindings')
stopMusic()
local other=Preferences.new()
prefs:set('musicVolume',.7)
assert(other:get('musicVolume')==.35,'Independent sessions must not share mutable state')
print('PASS bounded preferences, invalid input rejection, immediate bindings, change suppression, unsubscribe, reset and isolation')
