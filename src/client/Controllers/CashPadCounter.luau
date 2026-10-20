--!strict
-- Local receipt animation after Claim succeeds. Never changes economic state.
local Counter={}
Counter.__index=Counter
local duration=1.5
local function remaining(self: any,now: number): number
    local t=math.clamp((now-self.started)/duration,0,1)
    -- Smoothstep begins and finishes gently so large amounts remain readable.
    return self.credit*(1-t*t*(3-2*t))
end
local function label(self: any): TextLabel?
    if not self.plotId then return nil end
    local world=self.root:FindFirstChild('MergeABrainrotGenerated')
    local plot=world and world:FindFirstChild('Plot'..self.plotId)
    local pad=plot and plot:FindFirstChild('CoinPad')
    local gui=pad and pad:FindFirstChild('Label')
    local price=gui and gui:FindFirstChild('Price')
    return if price and price:IsA('TextLabel') then price else nil
end
local function countingText(units: number): string
    -- Round the visual value down only; economic quarter-dollar units stay exact.
    local whole=string.format('%.0f',math.floor(math.max(0,units)/4))
    while true do
        local grouped,changed=whole:gsub('^(%d+)(%d%d%d)','%1,%2')
        whole=grouped
        if changed==0 then break end
    end
    return '$'..whole
end
local function restore(self: any)
    if self.active then
        local price=label(self)
        if price then price.Text=countingText(self.actual) end
    end
    self.active=false
end
function Counter.new(root: Instance?): any
    return setmetatable({root=root or workspace,actual=0,revision=-1,minimumRevision=-1,
        active=false,destroyed=false,started=0,credit=0,lastClaimRevision=-1},Counter)
end
function Counter.setState(self: any,snapshot: any)
    if self.destroyed then return end
    local plotId=snapshot and snapshot.plotId
    if plotId~=self.plotId then
        restore(self);self.plotId=plotId;self.actual=0;self.revision=-1;self.minimumRevision=-1;self.lastClaimRevision=-1
    end
    if not snapshot then return end
    local revision=snapshot.revision or self.revision
    if revision<self.revision or revision<self.minimumRevision then return end
    self.revision=revision;self.actual=math.max(0,snapshot.soldUnits or 0)
end
function Counter.claim(self: any,plotId: number,creditUnits: number,currentSoldUnits: number,now: number,claimRevision: number?): boolean
    if self.destroyed or not self.plotId or plotId~=self.plotId or creditUnits<=0 then return false end
    if claimRevision and claimRevision<=self.lastClaimRevision then return false end
    if claimRevision then self.lastClaimRevision=claimRevision end
    local unfinished=if self.active then remaining(self,now) else 0
    self.actual=math.max(0,currentSoldUnits)
    self.credit=creditUnits+unfinished;self.started=now;self.active=true
    self.minimumRevision=claimRevision or self.revision
    self:update(now)
    return label(self)~=nil
end
function Counter.update(self: any,now: number)
    if self.destroyed or not self.active then return end
    if now-self.started>=duration then restore(self);return end
    local price=label(self)
    if not price then return end
    -- Write every active frame: server replication may have replaced the text
    -- since the last frame even when this rounded amount has not changed.
    price.Text=countingText(self.actual+remaining(self,now))
end
function Counter.destroy(self: any)
    if self.destroyed then return end
    restore(self);self.destroyed=true;self.plotId=nil
end
return table.freeze(Counter)
