--!strict
-- Server-only domain state. Sample authoritative character FOOT positions at
-- about 10 Hz; call reset='Home'/'Teleport'/'Respawn' around server teleports.
-- This verifies the observed route, not all client-owned character physics.
-- No client checkpoint/finish claims, Instances, clocks, remotes or economy writes.
export type Position={x: number,y: number,z: number}
export type Context={now: number,position: Position?,alive: boolean,reset: string?}
export type Result={
    event: string,reason: string?,phase: string,checkpoint: number,totalCheckpoints: number,
    bonusHundredths: number,boostExpiresAt: number,boostRemaining: number,boostExpired: boolean,
    cooldownEndsAt: number,cooldownRemaining: number,
}
local Run={}
Run.__index=Run
local epsilon=1e-7
local resets={Home=true,Teleport=true,Respawn=true}
local function finite(value: any,low: number,high: number): boolean
    return type(value)=='number' and value==value and value>=low and value<=high
end
local function validPosition(position: any,limit: number): boolean
    return type(position)=='table' and finite(position.x,-limit,limit)
        and finite(position.y,-limit,limit) and finite(position.z,-limit,limit)
end
local function copyPosition(position: Position): Position
    return {x=position.x,y=position.y,z=position.z}
end
local function prepare(source: any): any
    assert(type(source)=='table','Obby config is required')
    local config: any={}
    local ranges: {[string]: {number}}={
        BonusHundredths={1,100},BoostSeconds={1,86400},CooldownSeconds={1,86400},
        LandingHoldSeconds={.01,1},MinimumCheckpointSeconds={.05,2},MinimumJumpRise={.1,5},
        FootBelowTolerance={0,1},FootAboveTolerance={0,1},FootEdgeTolerance={0,.5},
        FallBelowCheckpoint={.5,10},MaximumHorizontalSpeed={1,100},MaximumVerticalSpeed={1,200},
        MovementSlack={0,3},MaximumObservationGap={.1,5},MaximumRunSeconds={1,600},
        MaximumCoordinate={100,1000000},MaximumTimestamp={1000,1e13},
    }
    for key,range in ranges do
        assert(finite(source[key],range[1],range[2]),'Invalid obby config: '..key)
        config[key]=source[key]
    end
    assert(config.BonusHundredths%1==0,'Bonus must use integer hundredths')
    assert(config.CooldownSeconds>=config.BoostSeconds,'Reward periods must not stack')
    assert(config.MaximumTimestamp>config.CooldownSeconds+config.MaximumRunSeconds)
    local function footprint(value: any): any
        assert(validPosition(value,config.MaximumCoordinate),'Invalid obby footprint position')
        assert(finite(value.halfX,.25,20) and finite(value.halfZ,.25,20),'Invalid obby footprint size')
        return table.freeze({x=value.x,y=value.y,z=value.z,halfX=value.halfX,halfZ=value.halfZ})
    end
    assert(type(source.Checkpoints)=='table' and #source.Checkpoints==10,'Obby requires ten ordered checkpoints')
    config.Checkpoints={}
    for index=1,10 do config.Checkpoints[index]=footprint(source.Checkpoints[index]) end
    table.freeze(config.Checkpoints)
    config.Finish=footprint(source.Finish)
    assert(type(source.Bounds)=='table','Obby course bounds are required')
    local bounds={}
    for _,key in {'minX','maxX','minY','maxY','minZ','maxZ'} do
        assert(finite(source.Bounds[key],-config.MaximumCoordinate,config.MaximumCoordinate),'Invalid course bound: '..key)
        bounds[key]=source.Bounds[key]
    end
    assert(bounds.minX<bounds.maxX and bounds.minY<bounds.maxY and bounds.minZ<bounds.maxZ,'Course bounds are inverted')
    config.Bounds=table.freeze(bounds)
    return table.freeze(config)
end
local function clearProgress(self: any)
    self.checkpoint=0;self.startedAt=nil;self.lastCheckpointAt=nil
    self.candidate=nil;self.candidateSince=nil;self.departed=false
end
local function result(self: any,event: string?,reason: string?): Result
    local now=self.lastNow or 0
    local remaining=math.max(0,self.cooldownEndsAt-now)
    return {
        event=event or 'none',reason=reason,
        phase=if remaining>0 then 'cooldown' elseif self.checkpoint>0 then 'running' else 'idle',
        checkpoint=self.checkpoint,totalCheckpoints=#self.config.Checkpoints,
        bonusHundredths=if self.boostExpiresAt>now then self.config.BonusHundredths else 0,
        boostExpiresAt=self.boostExpiresAt,boostRemaining=math.max(0,self.boostExpiresAt-now),
        boostExpired=self.boostExpired,cooldownEndsAt=self.cooldownEndsAt,cooldownRemaining=remaining,
    }
end
local function retry(self: any,reason: string,force: boolean?): Result
    local active=self.checkpoint>0 or self.candidate~=nil
    clearProgress(self)
    return result(self,if active or force then 'retry' else 'none',reason)
end
local function onTop(config: any,foot: Position,pad: any): boolean
    return math.abs(foot.x-pad.x)<=pad.halfX+config.FootEdgeTolerance+epsilon
        and math.abs(foot.z-pad.z)<=pad.halfZ+config.FootEdgeTolerance+epsilon
        and foot.y>=pad.y-config.FootBelowTolerance-epsilon
        and foot.y<=pad.y+config.FootAboveTolerance+epsilon
end
local function checkpointAt(config: any,position: Position): number?
    for index,pad in config.Checkpoints do if onTop(config,position,pad) then return index end end
    if onTop(config,position,config.Finish) then return #config.Checkpoints+1 end
    return nil
end
function Run.new(config: any)
    return setmetatable({
        config=prepare(config),checkpoint=0,departed=false,
        boostExpiresAt=0,cooldownEndsAt=0,boostExpired=false,
    },Run)
end
function Run.update(self: any,context: Context): Result
    local config=self.config
    local now=if type(context)=='table' then context.now else nil
    self.boostExpired=false
    if not finite(now,0,config.MaximumTimestamp)
        or (self.lastNow and now<self.lastNow) then
        self.lastPosition=nil;self.lastPad=nil
        return retry(self,'InvalidTime')
    end
    local previousNow=self.lastNow
    self.lastNow=now
    if self.boostExpiresAt>0 and now>=self.boostExpiresAt then
        self.boostExpiresAt=0;self.boostExpired=true
    end
    if now>=self.cooldownEndsAt then self.cooldownEndsAt=0 end
    local position=context.position
    if context.reset~=nil then
        self.lastPosition=if validPosition(position,config.MaximumCoordinate) then copyPosition(position :: Position) else nil
        self.lastPad=nil
        return retry(self,if resets[context.reset] then context.reset else 'InvalidReset')
    end
    if context.alive~=true then
        self.lastPosition=nil;self.lastPad=nil
        return retry(self,'Dead')
    end
    if not validPosition(position,config.MaximumCoordinate) then
        self.lastPosition=nil;self.lastPad=nil
        return retry(self,'InvalidPosition')
    end
    local foot=position :: Position
    local previous=self.lastPosition
    local previousPad=self.lastPad
    self.lastPosition=copyPosition(foot)
    local hit=checkpointAt(config,foot)
    self.lastPad=hit
    local active=self.checkpoint>0 or self.candidate~=nil
    local delta=if previousNow then now-previousNow else 0
    if active and delta>config.MaximumObservationGap then return retry(self,'ObservationGap') end
    if previous then
        local dx,dy,dz=foot.x-previous.x,foot.y-previous.y,foot.z-previous.z
        local horizontal=config.MaximumHorizontalSpeed*delta+config.MovementSlack
        if dx*dx+dz*dz>horizontal*horizontal or math.abs(dy)>config.MaximumVerticalSpeed*delta+config.MovementSlack then
            return retry(self,'ImpossibleMovement')
        end
    end
    local bounds=config.Bounds
    if foot.x<bounds.minX or foot.x>bounds.maxX or foot.y<bounds.minY or foot.y>bounds.maxY
        or foot.z<bounds.minZ or foot.z>bounds.maxZ then
        return retry(self,'LeftCourse')
    end
    if self.cooldownEndsAt>now then
        return result(self,if hit==1 and previousPad~=1 then 'cooldown' else 'none')
    end
    if self.startedAt and now-self.startedAt>=config.MaximumRunSeconds-epsilon then return retry(self,'RunTimeout') end
    if self.checkpoint>0 and foot.y<config.Checkpoints[self.checkpoint].y-config.FallBelowCheckpoint then
        return retry(self,'Fell')
    end
    local expected=self.checkpoint+1
    if hit and hit>expected then return retry(self,'SkippedCheckpoint',hit~=previousPad) end
    if hit~=expected then
        self.candidate=nil;self.candidateSince=nil
        if hit==self.checkpoint then
            self.departed=false
        elseif self.checkpoint>0 and foot.y>=config.Checkpoints[self.checkpoint].y+config.MinimumJumpRise then
            self.departed=true
        end
        return result(self)
    end
    if self.checkpoint>0 then
        if not self.departed then return retry(self,'UnobservedJump') end
        if now-self.lastCheckpointAt<config.MinimumCheckpointSeconds-epsilon then return retry(self,'TooFast') end
    end
    if self.candidate~=hit then
        self.candidate=hit;self.candidateSince=now
        return result(self)
    end
    if now-self.candidateSince<config.LandingHoldSeconds-epsilon then return result(self) end
    if hit==#config.Checkpoints+1 then
        if now>config.MaximumTimestamp-config.CooldownSeconds then return retry(self,'ClockLimit') end
        self.boostExpiresAt=now+config.BoostSeconds
        self.cooldownEndsAt=now+config.CooldownSeconds
        clearProgress(self)
        return result(self,'finish')
    end
    self.checkpoint=hit
    self.startedAt=self.startedAt or now
    self.lastCheckpointAt=now
    self.departed=false;self.candidate=nil;self.candidateSince=nil
    return result(self,'checkpoint')
end
-- Snapshot uses the latest accepted server time; keep calling update while idle
-- or cooling down so expiry is observed even when the player leaves the course.
function Run.snapshot(self: any): Result
    local current=result(self)
    current.boostExpired=false
    return current
end
return table.freeze(Run)
