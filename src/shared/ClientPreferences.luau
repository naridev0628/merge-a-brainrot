--!strict
-- Cosmetic settings are local to one client session; no economy state or remotes.
local Preferences={}
Preferences.__index=Preferences
type Listeners = {[number]: (number) -> ()}
local defaults: {[string]: number}={sfxVolume=1,musicVolume=.35}
table.freeze(defaults)

function Preferences.new()
    return setmetatable({values=table.clone(defaults),listeners={},nextListener=0},Preferences)
end

function Preferences.get(self: any,key: string): number?
    return self.values[key]
end

function Preferences.set(self: any,key: string,value: any): (boolean,string?)
    if defaults[key]==nil then return false,'UnknownPreference' end
    if type(value)~='number' or value~=value or math.abs(value)==math.huge then return false,'InvalidValue' end
    local bounded=math.clamp(value,0,1)
    if self.values[key]==bounded then return true,nil end
    self.values[key]=bounded
    local listeners: Listeners?=self.listeners[key]
    if listeners then
        for id,callback in table.clone(listeners) do
            if listeners[id]==callback then callback(bounded) end
        end
    end
    return true,nil
end

function Preferences.subscribe(self: any,key: string,callback: (number) -> ()): () -> ()
    assert(defaults[key]~=nil,'Unknown preference: '..key)
    local existing: Listeners?=self.listeners[key]
    local listeners: Listeners=existing or {}
    if not existing then self.listeners[key]=listeners end
    self.nextListener+=1
    local id=self.nextListener
    listeners[id]=callback
    callback(self.values[key])
    return function() listeners[id]=nil end
end

function Preferences.snapshot(self: any): {[string]: number}
    return table.clone(self.values)
end

function Preferences.reset(self: any)
    for key,value in defaults do self:set(key,value) end
end

return table.freeze(Preferences)
