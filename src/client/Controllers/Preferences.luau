--!strict
-- One local-session store and mixer shared by the HUD and every farm audio cue.
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Store=require(Shared:WaitForChild('ClientPreferences'))
local SoundService=game:GetService('SoundService')
local store=Store.new()
local groups: {[string]: SoundGroup}={}
for channel,name in {sfx='FarmSFX',music='FarmMusic'} do
    local existing=SoundService:FindFirstChild(name)
    assert(not existing or existing:IsA('SoundGroup'),name..' must be a SoundGroup')
    local group=if existing then existing :: SoundGroup else Instance.new('SoundGroup')
    group.Name=name
    group.Parent=SoundService
    groups[channel]=group
    store:subscribe(channel..'Volume',function(value) group.Volume=value end)
end

local Preferences={}
function Preferences.get(key: string): number?
    return store:get(key)
end
function Preferences.set(key: string,value: any): (boolean,string?)
    return store:set(key,value)
end
function Preferences.subscribe(key: string,callback: (number) -> ()): () -> ()
    return store:subscribe(key,callback)
end
function Preferences.snapshot(): {[string]: number}
    return store:snapshot()
end
function Preferences.reset()
    store:reset()
end
function Preferences.getSoundGroup(channel: string): SoundGroup
    return assert(groups[channel],'Unknown audio channel: '..channel)
end
return table.freeze(Preferences)
