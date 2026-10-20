--!strict
-- Local display state only. Deadlines share the snapshot's server clock; the
-- client clock contributes elapsed time since receipt, never an absolute epoch.
local Presentation={}
Presentation.__index=Presentation
local phases={idle=true,running=true,cooldown=true}
local function finite(value: any): boolean
    return type(value)=='number' and value==value and value>=0 and value<=1e12
end
local function integer(value: any,minimum: number,maximum: number): boolean
    return finite(value) and value%1==0 and value>=minimum and value<=maximum
end
local function valid(snapshot: any,receivedAt: number): boolean
    if type(snapshot)~='table' or snapshot.status~='Ready' or type(snapshot.sessionKey)~='string'
        or not integer(snapshot.revision,0,1e12) or not finite(snapshot.serverNow) or not finite(receivedAt) then return false end
    local obby=snapshot.obby
    return type(obby)=='table' and phases[obby.phase]==true and integer(obby.totalCheckpoints,1,100)
        and integer(obby.checkpoint,0,obby.totalCheckpoints) and integer(obby.bonusHundredths,0,100)
        and finite(obby.boostExpiresAt) and finite(obby.cooldownEndsAt)
end
local function timer(remaining: number): string
    local seconds=math.max(0,math.ceil(remaining))
    return string.format('%d:%02d',math.floor(seconds/60),seconds%60)
end
function Presentation.new()
    return setmetatable({initialized=false,latestDeadline=0},Presentation)
end
-- Returns accepted, new completion, and whether the displayed state changed.
function Presentation.receive(self: any,snapshot: any,receivedAt: number): (boolean,boolean,boolean)
    if not valid(snapshot,receivedAt) then return false,false,false end
    local sameSession=snapshot.sessionKey==self.sessionKey
    if sameSession and (snapshot.serverNow<self.serverNow or snapshot.revision<self.revision
        or (snapshot.serverNow==self.serverNow and snapshot.revision==self.revision)) then return false,false,false end
    if not sameSession then self.initialized=false;self.latestDeadline=0 end
    local obby=snapshot.obby
    local finish=self.initialized==true and obby.phase=='cooldown' and obby.bonusHundredths>0
        and obby.boostExpiresAt>snapshot.serverNow and obby.boostExpiresAt>self.latestDeadline
    local signature=table.concat({obby.phase,obby.checkpoint,obby.totalCheckpoints,
        obby.bonusHundredths,obby.boostExpiresAt,obby.cooldownEndsAt},':')
    local changed=self.data==nil or signature~=self.signature or not sameSession
    self.data={phase=obby.phase,checkpoint=obby.checkpoint,totalCheckpoints=obby.totalCheckpoints,
        bonusHundredths=obby.bonusHundredths,boostExpiresAt=obby.boostExpiresAt,cooldownEndsAt=obby.cooldownEndsAt}
    self.sessionKey=snapshot.sessionKey;self.revision=snapshot.revision
    self.serverNow=snapshot.serverNow;self.receivedAt=receivedAt
    self.latestDeadline=math.max(self.latestDeadline,obby.boostExpiresAt)
    self.initialized=true;self.signature=signature
    return true,finish,changed
end
function Presentation.read(self: any,localNow: number): any
    local obby=self.data
    if not obby or not finite(localNow) then return nil end
    local now=self.serverNow+math.max(0,localNow-self.receivedAt)
    if obby.bonusHundredths>0 and obby.boostExpiresAt>now then
        return {kind='bonus',text=string.format('+%.2fx Minis • %s',obby.bonusHundredths/100,timer(obby.boostExpiresAt-now))}
    elseif obby.phase=='running' and obby.checkpoint>0 then
        return {kind='running',text=string.format('Obby: step %d / %d',obby.checkpoint,obby.totalCheckpoints)}
    elseif obby.cooldownEndsAt>now then
        return {kind='cooldown',text='Obby ready in '..timer(obby.cooldownEndsAt-now)}
    end
    return {kind='idle',text='Obby available now!'}
end
function Presentation.clear(self: any)
    -- Preserve award history through temporary unavailable snapshots.
    self.data=nil
end
return table.freeze(Presentation)
