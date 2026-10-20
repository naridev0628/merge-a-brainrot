--!strict
-- Session bridge: the run outlives character respawns, and only bonus changes
-- enter the farm economy. Injecting the domain keeps this lifecycle testable.
local Service={}
Service.__index=Service
local function signature(state: any): string
    return table.concat({state.phase,state.checkpoint,state.bonusHundredths,state.boostExpiresAt,state.cooldownEndsAt},':')
end
function Service.new(core: any,Run: any,config: any)
    return setmetatable({core=core,Run=Run,config=config,entries={}},Service)
end
function Service.attach(self: any,key: any,session: any)
    assert(not self.entries[key],'Player already has an obby run')
    local run=self.Run.new(self.config)
    self.entries[key]={session=session,run=run,signature=signature(run:snapshot())}
end
function Service.detach(self: any,key: any)
    self.entries[key]=nil
end
function Service.snapshot(self: any,key: any): any
    local entry=self.entries[key]
    return if entry then entry.run:snapshot() else nil
end
function Service.update(self: any,key: any,context: any): (boolean,boolean)
    local entry=self.entries[key]
    if not entry then return false,false end
    local state=entry.run:update(context)
    local bonusChanged=(entry.session.state.obbyBonusHundredths or 0)~=state.bonusHundredths
    if bonusChanged then
        self.core:setObbyBonus(entry.session,state.bonusHundredths)
        assert((entry.session.state.obbyBonusHundredths or 0)==state.bonusHundredths,'Obby reward could not be applied')
    end
    local nextSignature=signature(state)
    local changed=nextSignature~=entry.signature
    entry.signature=nextSignature
    return changed or bonusChanged,bonusChanged
end
-- Keep expiry and production adjacent, without rendering/yielding between them.
-- Returns snapshot changed, farm changed; the 10 Hz progress sampler may still
-- update independently, but it never determines the lifetime of production.
function Service.step(self: any,key: any,context: any): (boolean,boolean)
    local entry=self.entries[key]
    if not entry then return false,false end
    local changed,bonusChanged=self:update(key,context)
    local produced=self.core:step(entry.session,context.now)
    return changed or produced,bonusChanged or produced
end
function Service.reset(self: any,key: any,reason: string,now: number): (boolean,boolean)
    return self:update(key,{now=now,alive=false,reset=reason})
end
return table.freeze(Service)
