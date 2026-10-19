--!strict
local Catalog=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CreatureCatalog"))
local UI={}
UI.__index=UI
local C={
    navy=Color3.fromRGB(24,50,63), cream=Color3.fromRGB(255,244,220),
    mint=Color3.fromRGB(182,223,202), blue=Color3.fromRGB(119,185,245),
    amber=Color3.fromRGB(245,188,72), violet=Color3.fromRGB(110,75,196),
    muted=Color3.fromRGB(86,114,125),
}
function UI.coins(units: number): string
    local result=string.format("%.2f",units/4)
    return (result:gsub("%.?0+$",""))
end
local function frame(parent: Instance, name: string, color: Color3): Frame
    local f=Instance.new("Frame"); f.Name=name; f.BackgroundColor3=color; f.BorderSizePixel=0; f.Parent=parent
    local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,12); corner.Parent=f
    return f
end
local function text(parent: Instance, name: string, size: number, color: Color3): TextLabel
    local l=Instance.new("TextLabel"); l.Name=name; l.BackgroundTransparency=1
    l.TextColor3=color; l.TextSize=size; l.Font=Enum.Font.GothamMedium
    l.TextWrapped=true; l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=""; l.Parent=parent
    return l
end
local function button(parent: Instance, name: string, label: string, color: Color3): TextButton
    local b=Instance.new("TextButton"); b.Name=name; b.Text=label; b.BackgroundColor3=color
    b.TextColor3=if color==C.violet then C.cream else C.navy
    b.Font=Enum.Font.GothamBold; b.TextSize=16; b.TextWrapped=true
    b.BorderSizePixel=0; b.AutoButtonColor=true
    local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,10); corner.Parent=b
    b.Parent=parent; return b
end
function UI.new(parent: Instance)
    local self: any=setmetatable({selected={},pending=false,state=nil,context=nil,onBuy=function() end,onSell=function() end,onMerge=function() end,onHome=function() end},UI)
    local gui=Instance.new("ScreenGui"); gui.Name="BrainrotHUD"; gui.ResetOnSpawn=false
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent=parent; self.gui=gui
    local root=Instance.new("Frame"); root.Name="SafeArea"; root.BackgroundTransparency=1; root.Size=UDim2.fromScale(1,1); root.Parent=gui; self.root=root
    self.hud=frame(root,"FarmStats",C.navy)
    self.title=text(self.hud,"Title",14,C.mint); self.title.Text="MINI MEADOW  /  FIRST PLAYABLE"; self.title.Position=UDim2.fromOffset(14,8); self.title.Size=UDim2.new(1,-28,0,20)
    self.stats=text(self.hud,"Stats",21,C.cream); self.stats.Position=UDim2.fromOffset(14,32); self.stats.Size=UDim2.new(1,-28,0,28); self.stats.Text="Loading your farm…"
    self.detail=text(self.hud,"Details",14,C.mint); self.detail.Position=UDim2.fromOffset(14,64); self.detail.Size=UDim2.new(1,-28,0,20)
    self.objective=text(self.hud,"Objective",16,C.cream); self.objective.Position=UDim2.fromOffset(14,88); self.objective.Size=UDim2.new(1,-28,0,42)
    self.actions=Instance.new("Frame"); self.actions.Name="Actions"; self.actions.BackgroundTransparency=1; self.actions.Parent=root
    self.mergeButton=button(self.actions,"Merge","Merge [M]",C.violet); self.mergeButton.Size=UDim2.new(0.62,-4,1,0)
    self.homeButton=button(self.actions,"Home","Home",C.mint); self.homeButton.Position=UDim2.new(0.62,4,0,0); self.homeButton.Size=UDim2.new(0.38,-4,1,0)
    self.memory=text(root,"MemoryNotice",14,C.navy); self.memory.Text="Studio test — progress is not saved."
    self.memory.AnchorPoint=Vector2.new(0.5,1); self.memory.Position=UDim2.new(0.5,0,1,-8); self.memory.Size=UDim2.new(0.6,0,0,36); self.memory.TextXAlignment=Enum.TextXAlignment.Center
    self.toast=frame(root,"Feedback",C.navy); self.toast.Visible=false; self.toast.AnchorPoint=Vector2.new(0.5,0)
    self.toast.ZIndex=20
    self.toastText=text(self.toast,"Message",16,C.cream); self.toastText.Position=UDim2.fromOffset(12,4); self.toastText.Size=UDim2.new(1,-24,1,-8); self.toastText.ZIndex=21
    self.contextPanel=frame(root,"PadAction",C.navy); self.contextPanel.Visible=false; self.contextPanel.AnchorPoint=Vector2.new(0.5,0.5)
    self.contextText=text(self.contextPanel,"Summary",14,C.cream); self.contextText.Position=UDim2.fromOffset(12,4); self.contextText.Size=UDim2.new(1,-24,0,30)
    self.contextButton=button(self.contextPanel,"Act","",C.blue); self.contextButton.Position=UDim2.fromOffset(8,38); self.contextButton.Size=UDim2.new(1,-16,0,52)
    self.overlay=Instance.new("TextButton"); self.overlay.Name="MergeOverlay"; self.overlay.Text=""; self.overlay.AutoButtonColor=false
    self.overlay.Size=UDim2.fromScale(1,1); self.overlay.BackgroundColor3=Color3.new(0,0,0); self.overlay.BackgroundTransparency=0.35; self.overlay.Visible=false; self.overlay.ZIndex=10; self.overlay.Parent=root
    self.panel=frame(self.overlay,"MergePanel",C.navy); self.panel.AnchorPoint=Vector2.new(0.5,0.5); self.panel.Position=UDim2.fromScale(0.5,0.5); self.panel.ZIndex=11
    self.heading=text(self.panel,"Heading",22,C.cream); self.heading.Text="Make something stranger"; self.heading.Position=UDim2.fromOffset(14,8); self.heading.Size=UDim2.new(1,-80,0,48)
    self.closeButton=button(self.panel,"Close","X",C.mint); self.closeButton.Size=UDim2.fromOffset(48,48); self.closeButton.Position=UDim2.new(1,-60,0,8)
    self.preview=text(self.panel,"Preview",16,C.cream); self.preview.Position=UDim2.fromOffset(14,64); self.preview.Size=UDim2.new(1,-28,0,76)
    self.list=Instance.new("ScrollingFrame"); self.list.Name="Producers"; self.list.BackgroundTransparency=1; self.list.BorderSizePixel=0
    self.list.Position=UDim2.fromOffset(12,148); self.list.Size=UDim2.new(1,-24,1,-220); self.list.ScrollBarThickness=6; self.list.CanvasSize=UDim2.new(); self.list.Parent=self.panel
    self.layout=Instance.new("UIGridLayout"); self.layout.CellPadding=UDim2.fromOffset(8,8); self.layout.SortOrder=Enum.SortOrder.LayoutOrder; self.layout.Parent=self.list
    self.confirm=button(self.panel,"Confirm","Confirm merge",C.violet); self.confirm.Position=UDim2.new(0,12,1,-64); self.confirm.Size=UDim2.new(1,-24,0,52)
    self.mergeButton.Activated:Connect(function() self:toggleMerge() end)
    self.homeButton.Activated:Connect(function() if not self.overlay.Visible then self.onHome() end end)
    self.closeButton.Activated:Connect(function() self:close() end)
    self.confirm.Activated:Connect(function()
        if self.eligible and not self.pending then self.onMerge(table.clone(self.selected)) end
    end)
    self.contextButton.Activated:Connect(function()
        if self.pending or self.overlay.Visible then return end
        if self.context=="Sell" then self.onSell() elseif self.context=="Buy" then self.onBuy() end
    end)
    root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:resize() end)
    self.layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.list.CanvasSize=UDim2.fromOffset(0,self.layout.AbsoluteContentSize.Y+8)
    end)
    self:resize()
    return self
end
function UI.resize(self: any)
    local size=self.root.AbsoluteSize
    local narrow=size.X<720
    self.hud.Position=UDim2.fromOffset(12,8)
    self.hud.Size=UDim2.fromOffset(if narrow then size.X-24 else 410,138)
    self.actions.Position=if narrow then UDim2.fromOffset(12,154) else UDim2.new(1,-282,0,8)
    self.actions.Size=UDim2.fromOffset(if narrow then math.min(size.X-24,350) else 270,48)
    self.toast.Position=UDim2.new(0.5,0,0,if narrow then 210 else 68)
    self.toast.Size=UDim2.fromOffset(math.min(size.X-24,480),52)
    self.contextPanel.Position=UDim2.fromScale(0.5,if narrow then 0.65 else 0.78)
    self.contextPanel.Size=UDim2.fromOffset(math.min(size.X-72,300),98)
    self.panel.Size=UDim2.fromOffset(math.min(size.X-24,640),math.min(size.Y-24,620))
    local compact=size.Y<440
    local cardHeight=if compact then 48 else 64
    self.layout.CellSize=if size.X<520 then UDim2.new(1,-8,0,cardHeight) else UDim2.new(0.5,-8,0,cardHeight)
    self.preview.Size=UDim2.new(1,-28,0,if compact then 44 else 76)
    self.preview.TextSize=if compact then 14 else 16
    self.list.Position=UDim2.fromOffset(12,if compact then 116 else 148)
    self.list.Size=UDim2.new(1,-24,1,if compact then -188 else -220)
    -- Short landscape uses a compact stats bar and keeps action targets at 48px.
    if size.Y<440 and size.X>=520 then
        self.hud.Size=UDim2.fromOffset(math.max(250,size.X-310),100)
        self.title.Visible=false; self.stats.Position=UDim2.fromOffset(12,4)
        self.detail.Position=UDim2.fromOffset(12,34); self.objective.Position=UDim2.fromOffset(12,56)
        self.actions.Position=UDim2.new(1,-282,0,8)
    else
        self.title.Visible=true; self.stats.Position=UDim2.fromOffset(14,32)
        self.detail.Position=UDim2.fromOffset(14,64); self.objective.Position=UDim2.fromOffset(14,88)
    end
end
function UI.notice(self: any, message: string)
    self.toastText.Text=message; self.toast.Visible=true
    self.noticeVersion=(self.noticeVersion or 0)+1
    local version=self.noticeVersion
    task.delay(4,function() if self.noticeVersion==version then self.toast.Visible=false end end)
end
function UI.unavailable(self: any, reason: string)
    self.state=nil; self.stats.Text="Farm unavailable"; self.objective.Text=reason
    self.detail.Text="No progress was loaded."; self:close(); self.contextPanel.Visible=false
end
function UI.setPending(self: any, value: boolean)
    self.pending=value; self.confirm.Text=if value then "Waiting for server…" else "Confirm merge"
    self:drawMerge(); self:setContext(self.context)
end
function UI.clearSelection(self: any) self.selected={}; self:drawMerge() end
function UI.isOpen(self: any): boolean return self.overlay.Visible end
function UI.close(self: any) self.overlay.Visible=false; self:setContext(self.context) end
function UI.toggleMerge(self: any)
    if not self.state then return end
    self.overlay.Visible=not self.overlay.Visible
    self.toast.Visible=false; self:setContext(self.context); self:drawMerge()
end
function UI.setContext(self: any, kind: string?)
    self.context=kind
    self.contextPanel.Visible=kind~=nil and self.state~=nil and not self.overlay.Visible
    if not self.contextPanel.Visible then return end
    local state=self.state
    if kind=="Sell" then
        local base=0; for _,g in state.bag do base+=g.baseCoinValue end
        self.contextText.Text=#state.bag.." Minis · "..UI.coins(base*(4+state.rebirths)).." Coins"
        self.contextButton.Text=if self.pending then "Selling…" elseif #state.bag==0 then "Bag empty — collect Minis" else "Sell Minis [E]"
        self.contextButton.BackgroundColor3=C.amber
    else
        self.contextText.Text=(12-#state.producers).."/12 free slots · Tier 1 producer"
        self.contextButton.Text=if self.pending then "Buying…" elseif #state.producers>=12 then "Plot full — merge a pair" elseif state.coinUnits<80 then "Need "..UI.coins(80-state.coinUnits).." more Coins" else "Buy Tier 1 · 20 Coins [E]"
        self.contextButton.BackgroundColor3=C.blue
    end
end
function UI.update(self: any, state: any)
    self.state=state
    local best=1; for _,p in state.producers do best=math.max(best,Catalog[p.speciesId].tier) end
    self.stats.Text=UI.coins(state.coinUnits).." Coins    ·    Bag "..#state.bag.."/96"
    self.detail.Text="Best T"..best.."   ·   "..#state.producers.."/12 slots   ·   0 rebirths   ·   1×"
    local objectives={
        "Walk near the glowing Minis to collect them.",
        "Sell your Minis at the amber pad. 10 Minis = 20 Coins.",
        "Buy another Spoon Sprout at the blue pad.",
        "Open Merge. Pick two matching producers.",
        "Keep growing! Combine two Waffles to discover Bubble Boots.",
    }
    self.objective.Text=if best==3 then "Bubble Boots discovered! First playable loop complete." else objectives[state.tutorialStep] or objectives[5]
    local owned={}; for _,p in state.producers do owned[p.id]=true end
    local keep={}; for _,id in self.selected do if owned[id] then table.insert(keep,id) end end
    self.selected=keep
    self:setContext(self.context); self:drawMerge()
end
function UI.drawMerge(self: any)
    if not self.state then return end
    local scroll=self.list.CanvasPosition
    for _,child in self.list:GetChildren() do if child:IsA("TextButton") then child:Destroy() end end
    local producers=table.clone(self.state.producers)
    table.sort(producers,function(a: any,b: any)
        local at,bt=Catalog[a.speciesId].tier,Catalog[b.speciesId].tier
        return if at==bt then a.slot<b.slot else at<bt
    end)
    local pair={}
    for order,p in producers do
        local species=Catalog[p.speciesId]; local selected=table.find(self.selected,p.id)
        if selected then pair[selected]=p end
        local card=button(self.list,"Producer_"..p.slot,
            (if selected then "✓ "..selected.."  " else "").."T"..species.tier.." · "..species.name.."\nSlot "..p.slot.." · "..species.value.." Coins / 6s",
            if selected then C.violet else C.cream)
        card.LayoutOrder=order
        card.Activated:Connect(function()
            if self.pending then return end
            local index=table.find(self.selected,p.id)
            if index then table.remove(self.selected,index)
            elseif #self.selected<2 then table.insert(self.selected,p.id)
            else self.selected={p.id} end
            self:drawMerge()
        end)
    end
    self.list.CanvasPosition=scroll
    self.eligible=false
    if #pair==2 then
        local first=Catalog[pair[1].speciesId]
        if pair[1].speciesId~=pair[2].speciesId then self.preview.Text="Those species do not match. Select two identical producers."
        elseif not first.nextId then self.preview.Text="Highest tier in this prototype. These producers keep making Minis."
        else
            local output=Catalog[first.nextId]; self.eligible=true
            self.preview.Text="2 × "..first.name.." → 1 × "..output.name.."\n"..(first.value*2).." → "..output.value.." base Coins / 6s · Frees 1 slot · No fee"
        end
    else
        self.preview.Text=if #producers==1 then "Buy another Tier 1 to make your first pair.\nChoose two matching producers below." else "Choose two matching producers.\nTap a selected card to remove it."
    end
    self.confirm.BackgroundTransparency=if self.eligible and not self.pending then 0 else 0.5
    self.confirm.AutoButtonColor=self.eligible and not self.pending
end
return UI
