--!strict
-- Local input acknowledgement only. Purchase/reward effects await server OK.
local Feedback={}
Feedback.__index=Feedback
local duration=.18
local pads={
    Buy1='Buy1',Buy5='Buy5',Buy10='Buy10',Buy100='Buy100',
    Deposit='DepositPad',Claim='CoinPad',Upgrade='UpgradePad',AutoMerge='MergePad',
}
local function clear(self: any)
    self.highlight.Enabled=false
    self.highlight.Adornee=nil
    self.pad=nil;self.plot=nil;self.world=nil
end
function Feedback.new(root: Instance?): any
    local scope=root or workspace
    local highlight=Instance.new('Highlight')
    highlight.Name='PadEntryFeedback'
    highlight.Enabled=false
    highlight.DepthMode=Enum.HighlightDepthMode.Occluded
    highlight.FillColor=Color3.new(1,1,1)
    highlight.OutlineColor=Color3.new(1,1,1)
    highlight.FillTransparency=1;highlight.OutlineTransparency=1
    highlight.Parent=scope
    return setmetatable({root=scope,highlight=highlight,destroyed=false,started=0},Feedback)
end
function Feedback.setPlot(self: any,id: number?)
    if self.destroyed or self.plotId==id then return end
    clear(self);self.plotId=nil
    if id and id%1==0 and id>=1 and id<=6 then self.plotId=id end
end
function Feedback.trigger(self: any,plotId: number?,targetKey: string?,now: number): boolean
    if self.destroyed then return false end
    clear(self)
    if not self.plotId or plotId~=self.plotId or not targetKey then return false end
    local name=pads[targetKey]
    if not name then return false end
    local world=self.root:FindFirstChild('MergeABrainrotGenerated')
    local plot=world and world:FindFirstChild('Plot'..self.plotId)
    local pad=plot and plot:FindFirstChild(name)
    if not pad or not pad:IsA('BasePart') then return false end
    self.world=world;self.plot=plot;self.pad=pad;self.started=now
    self.highlight.Adornee=pad
    self.highlight.FillTransparency=.35
    self.highlight.OutlineTransparency=.15
    self.highlight.Enabled=true
    return true
end
function Feedback.update(self: any,now: number)
    if self.destroyed or not self.pad then return end
    local elapsed=now-self.started
    if elapsed>=duration or self.pad.Parent~=self.plot or self.plot.Parent~=self.world or self.world.Parent~=self.root then
        clear(self);return
    end
    local alpha=math.clamp(elapsed/duration,0,1)
    self.highlight.FillTransparency=.35+.65*alpha
    self.highlight.OutlineTransparency=.15+.85*alpha
end
function Feedback.destroy(self: any)
    if self.destroyed then return end
    clear(self);self.plotId=nil;self.destroyed=true
    self.highlight:Destroy()
end
return table.freeze(Feedback)
