--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Config=require(Shared:WaitForChild('Config'))
local Economy=require(Shared:WaitForChild('Economy'))
local FarmCapacity=require(Shared:WaitForChild('FarmCapacity'))
local Tutorial=require(Shared:WaitForChild('Tutorial'))
local PassConfig=require(Shared:WaitForChild('PassConfig'))
local Style=require(Shared:WaitForChild('TextStyle'))
local Art=require(script.Parent:WaitForChild('BrickArt'))
local Locale=require(script.Parent:WaitForChild('Locale'))
local RebirthPanel=require(script.Parent:WaitForChild('RebirthPanel'))
local IndexPanel=require(script.Parent:WaitForChild('IndexPanel'))
local LuckyPanel=require(script.Parent:WaitForChild('LuckyPanel'))
local SettingsPanel=require(script.Parent:WaitForChild('SettingsPanel'))
local TweenService=game:GetService('TweenService')
local UI={}; UI.__index=UI
local C={navy=Color3.fromRGB(26,37,49),cream=Style.Cream,green=Style.Price,blue=Color3.fromRGB(32,191,243),amber=Color3.fromRGB(255,204,36),violet=Color3.fromRGB(172,94,235),pink=Color3.fromRGB(248,120,174)}
function UI.coins(units: number): string
    local result=string.format('%.2f',units/4); return (result:gsub('%.?0+$',''))
end
local function frame(parent: Instance,name: string,color: Color3): Frame
    local f=Instance.new('Frame'); f.Name=name; f.BackgroundColor3=color; f.BorderSizePixel=0; f.Parent=parent
    local corner=Instance.new('UICorner'); corner.CornerRadius=UDim.new(0,5); corner.Parent=f
    local stroke=Instance.new('UIStroke'); stroke.Color=C.navy; stroke.Thickness=3; stroke.Parent=f
    return f
end
local function text(parent: Instance,name: string,size: number,color: Color3): TextLabel
    local l=Instance.new('TextLabel'); l.Name=name; l.BackgroundTransparency=1; l.Text=''; l.TextColor3=color
    l.TextSize=size; l.Font=Enum.Font.FredokaOne; l.TextWrapped=true; l.TextStrokeColor3=Color3.fromRGB(12,10,8); l.TextStrokeTransparency=1; l.Parent=parent; Style.apply(l,size,color); return l
end
local function button(parent: Instance,name: string,label: string,color: Color3): TextButton
    local b=Instance.new('TextButton'); b.Name=name; b.Text=label; b.BackgroundColor3=color; b.TextColor3=C.cream
    b.Font=Enum.Font.FredokaOne; b.TextSize=22; b.TextWrapped=true; b.TextStrokeColor3=Color3.fromRGB(12,10,8); b.TextStrokeTransparency=1; b.BorderSizePixel=0; b.Parent=parent
    local corner=Instance.new('UICorner'); corner.CornerRadius=UDim.new(0,5); corner.Parent=b
    local stroke=Instance.new('UIStroke'); stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Color=C.navy; stroke.Thickness=3; stroke.Parent=b
    local gradient=Instance.new('UIGradient'); gradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(204,204,204)); gradient.Rotation=90; gradient.Parent=b
    local scale=Instance.new('UIScale'); scale.Name='HoverScale'; scale.Parent=b
    local hovering=false; local pressed=false; local motion: Tween?=nil
    local function animate()
        if motion then motion:Cancel() end
        motion=TweenService:Create(scale,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=if pressed then .97 elseif hovering then 1.05 else 1})
        motion:Play()
    end
    b.MouseEnter:Connect(function() if b.AutoButtonColor then hovering=true; animate() end end)
    b.MouseLeave:Connect(function() hovering=false; pressed=false; animate() end)
    b.InputBegan:Connect(function(input) if b.AutoButtonColor and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then pressed=true; animate() end end)
    b.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then pressed=false; animate() end end)
    Style.apply(b,22,C.cream)
    return b
end
function UI.new(parent: Instance)
    local self: any=setmetatable({selected={},pending=false,state=nil,context=nil,quantity='1',mode='Merge',shopInfo={},onBuy=function() end,onDeposit=function() end,onClaim=function() end,onMerge=function() end,onRebirth=function() end,onHome=function() end,onPass=function() end,onLucky=function() end,onDropLucky=function() end,onDiscardLucky=function() end},UI)
    local gui=Instance.new('ScreenGui'); gui.Name='BrainrotHUD'; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets; gui.Parent=parent; self.gui=gui
    local root=Instance.new('Frame'); root.Name='SafeArea'; root.BackgroundTransparency=1; root.Size=UDim2.fromScale(1,1); root.Parent=gui; self.root=root
    self.hud=frame(root,'FarmStats',C.green)
    self.hud.BackgroundTransparency=1; self.hud:FindFirstChildOfClass('UIStroke').Transparency=1
    self.cashBar=frame(self.hud,'CashBar',Color3.fromRGB(30,62,23)); self.cashBar.BackgroundTransparency=.75
    local hudFade=Instance.new('UIGradient'); hudFade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.65,.35),NumberSequenceKeypoint.new(1,1)}); hudFade.Parent=self.cashBar
    local hudBorder=self.cashBar:FindFirstChildOfClass('UIStroke'); hudBorder.Color=Color3.fromRGB(31,70,15); hudBorder.Thickness=2
    local borderFade=hudFade:Clone(); borderFade.Parent=hudBorder
    self.stats=text(self.hud,'Stats',27,C.navy); self.stats.Size=UDim2.new(1,-12,0,40); self.stats.Position=UDim2.fromOffset(6,0)
    self.detail=text(self.hud,'Details',16,C.navy); self.detail.Position=UDim2.fromOffset(6,40); self.detail.Size=UDim2.new(1,-12,0,40)
    self.stats.TextColor3=C.green; self.stats.TextStrokeTransparency=1; self.stats.TextStrokeColor3=Color3.fromRGB(23,47,12); self.stats.TextXAlignment=Enum.TextXAlignment.Left
    self.detail.TextColor3=C.cream; self.detail.TextStrokeTransparency=1; self.detail.TextXAlignment=Enum.TextXAlignment.Left
    self.rebirthCount=text(self.hud,'RebirthCount',24,Color3.new(1,1,1)); self.rebirthCount.TextStrokeTransparency=1; self.rebirthCount.TextXAlignment=Enum.TextXAlignment.Left
    local rebirthGradient=Instance.new('UIGradient'); rebirthGradient.Rotation=90; rebirthGradient.Color=ColorSequence.new(Color3.fromRGB(255,172,179),Color3.fromRGB(255,61,67)); rebirthGradient.Parent=self.rebirthCount
    self.multiplier=text(root,'CashMultiplier',22,Color3.fromRGB(179,183,178)); self.multiplier.TextStrokeTransparency=1; self.multiplier.TextXAlignment=Enum.TextXAlignment.Left
    self.cashPlus=button(self.hud,'CashPlus','+',C.green); self.cashPlus.TextSize=30; self.cashPlus.TextColor3=C.cream; self.cashPlus.TextStrokeTransparency=1
    self.multiplier.Parent=self.hud; self.detail.Visible=false
    self.cashFog=Instance.new('Frame'); self.cashFog.Name='MultiplierFog'; self.cashFog.BackgroundTransparency=1; self.cashFog.Parent=self.hud
    for layer=1,6 do
        local haze=Instance.new('Frame'); haze.Name='Fog'..layer; haze.AnchorPoint=Vector2.new(.5,.5); haze.Position=UDim2.fromScale(.5,.5); haze.Size=UDim2.fromScale(1.22-layer*.065,1.45-layer*.12); haze.BackgroundColor3=Color3.fromRGB(20,22,22); haze.BackgroundTransparency=.94; haze.BorderSizePixel=0; haze.Parent=self.cashFog
        local round=Instance.new('UICorner'); round.CornerRadius=UDim.new(1,0); round.Parent=haze
    end
    self.multiplier.ZIndex=2; self.cashPlus.ZIndex=2
    self.stats.TextStrokeTransparency=1
    Style.apply(self.stats,nil,nil,3)
    self.stats.TextColor3=Color3.new(1,1,1)
    local cashGradient=Instance.new('UIGradient'); cashGradient.Rotation=90; cashGradient.Color=ColorSequence.new(Color3.fromRGB(184,255,25),Color3.fromRGB(76,211,0)); cashGradient.Parent=self.stats
    self.stats.Parent=self.cashBar; self.cashPlus.Parent=self.cashBar; self.multiplier.Parent=self.cashBar; self.cashFog.Parent=self.cashBar
    self.total=text(root,'TotalBrainrots',24,Color3.new(1,1,1)); self.total.TextStrokeTransparency=1; self.total.TextXAlignment=Enum.TextXAlignment.Right
    Style.apply(self.total,nil,nil,2.5)
    local totalGradient=Instance.new('UIGradient'); totalGradient.Rotation=90; totalGradient.Color=ColorSequence.new(Color3.fromRGB(255,249,188),Color3.fromRGB(255,203,68)); totalGradient.Parent=self.total
    self.bag=Instance.new('Frame'); self.bag.Name='MiniBag'; self.bag.BackgroundTransparency=1; self.bag.Parent=root; Art.basket(self.bag)
    self.bagText=text(self.bag,'Count',32,C.cream); self.bagText.Size=UDim2.fromScale(.68,.29); self.bagText.Position=UDim2.fromScale(.16,.65); self.bagText.TextStrokeTransparency=1; self.bagText.ZIndex=4
    self.bagText.TextScaled=true
    local countSize=Instance.new('UITextSizeConstraint'); countSize.MinTextSize=12; countSize.MaxTextSize=32; countSize.Parent=self.bagText
    local bagCaption=text(self.bag,'Caption',23,C.cream); bagCaption.Text='Minis'; bagCaption.Position=UDim2.fromScale(.12,.39); bagCaption.Size=UDim2.fromScale(.76,.23); bagCaption.TextStrokeTransparency=1; bagCaption.ZIndex=4
    self.bagValue=text(self.bag,'Value',16,C.green); self.bagValue.Size=UDim2.new(1,40,0,24); self.bagValue.Position=UDim2.new(0,-20,1,0); self.bagValue.TextStrokeTransparency=1; self.bagValue.ZIndex=4; self.bagValue.Visible=false
    self.title=text(root,'TutorialTitle',28,C.blue); self.title.TextStrokeTransparency=1; self.title.TextStrokeColor3=C.navy
    self.objective=text(root,'Objective',24,Color3.new(1,1,1)); self.objective.TextStrokeTransparency=1; self.objective.TextStrokeColor3=C.navy
    self.hint=text(root,'Hint',16,Color3.new(1,1,1)); self.hint.TextStrokeTransparency=1; self.hint.TextStrokeColor3=C.navy
    self.actions=Instance.new('Frame'); self.actions.Name='Actions'; self.actions.BackgroundTransparency=1; self.actions.Parent=root
    self.mergeButton=button(self.actions,'Merge','Merge [M]',C.amber)
    self.indexButton=button(self.actions,'Index','Index',C.blue)
    self.rebirthButton=button(self.actions,'Rebirth','Rebirth',C.pink)
    self.settingsButton=button(self.actions,'Settings','Settings',C.blue)
    for i,b in {self.mergeButton,self.indexButton,self.rebirthButton,self.settingsButton} do
        b.TextYAlignment=Enum.TextYAlignment.Bottom; b.TextColor3=C.cream; b.TextStrokeTransparency=1; b.BackgroundTransparency=1
        b:FindFirstChildOfClass('UIStroke').Transparency=1
        Art.icon(b,({'merge','book','rebirth','gear'})[i],UDim2.fromScale(.1,.01),UDim2.fromScale(.8,.73))
    end
    self.rebirthBadge=frame(self.rebirthButton,'ReadyBadge',Color3.fromRGB(255,62,69)); self.rebirthBadge.Size=UDim2.fromOffset(28,28); self.rebirthBadge.Position=UDim2.fromOffset(-9,-9); self.rebirthBadge.ZIndex=6; self.rebirthBadge.Visible=false
    self.rebirthBadge:FindFirstChildOfClass('UICorner').CornerRadius=UDim.new(1,0)
    local alert=text(self.rebirthBadge,'Alert',25,C.cream); alert.Text='!'; alert.TextStrokeTransparency=1; alert.Size=UDim2.fromScale(1,1); alert.ZIndex=7
    self.homeButton=button(root,'Home','Home',Color3.fromRGB(29,190,242))
    self.boostButton=button(root,'MoneyBoost','2x Cash',C.green)
    self.autoButton=button(root,'Automation','Auto Collect\nAuto Sell',C.amber)
    Art.brick(self.boostButton,C.green); self.boostButton.TextColor3=Color3.fromRGB(49,255,0); self.boostButton.TextStrokeTransparency=1; self.boostButton.TextStrokeColor3=Color3.fromRGB(0,0,0)
    self.boostButton.TextSize=40; self.boostButton.TextYAlignment=Enum.TextYAlignment.Center
    local rainbow=self.boostButton:FindFirstChildOfClass('UIStroke'); rainbow.Color=Color3.new(1,1,1); rainbow.Thickness=5
    local spectrum=Instance.new('UIGradient'); spectrum.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,45,45)),ColorSequenceKeypoint.new(.2,Color3.fromRGB(255,234,0)),ColorSequenceKeypoint.new(.4,Color3.fromRGB(40,255,30)),ColorSequenceKeypoint.new(.6,Color3.fromRGB(0,195,255)),ColorSequenceKeypoint.new(.8,Color3.fromRGB(110,55,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,45,130))}); spectrum.Parent=rainbow
    TweenService:Create(spectrum,TweenInfo.new(3,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360}):Play()
    for layer=1,3 do
        local glow=Instance.new('Frame'); glow.Name='RainbowGlow'..layer; glow.Size=UDim2.fromScale(1,1); glow.BackgroundTransparency=1; glow.Active=false; glow.ZIndex=2; glow.Parent=self.boostButton
        local corner=Instance.new('UICorner'); corner.CornerRadius=UDim.new(0,5); corner.Parent=glow
        local glowStroke=Instance.new('UIStroke'); glowStroke.Thickness=6+layer*4; glowStroke.Color=Color3.new(1,1,1); glowStroke.Transparency=.60+layer*.10; glowStroke.Parent=glow
        local glowSpectrum=spectrum:Clone(); glowSpectrum.Parent=glowStroke
        TweenService:Create(glowSpectrum,TweenInfo.new(3,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360}):Play()
        TweenService:Create(glowStroke,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.72+layer*.08}):Play()
    end
    Style.apply(self.boostButton.BrickCaption,nil,nil,3.5)
    self.permanent=text(self.boostButton,'Permanent',23,Color3.fromRGB(255,93,104)); self.permanent.Text='PERMANENT!'; self.permanent.Rotation=-4; self.permanent.Position=UDim2.fromScale(-.03,-.19); self.permanent.Size=UDim2.fromScale(1.06,.30); self.permanent.TextStrokeTransparency=1; self.permanent.ZIndex=4
    Style.apply(self.permanent,nil,nil,2.5)
    self.boostPrice=text(root,'BoostPrice',25,Color3.new(1,1,1)); self.boostPrice.Text='Coming soon'; self.boostPrice.TextStrokeTransparency=1
    Style.apply(self.boostPrice,nil,nil,2.5)
    Art.brick(self.homeButton,self.homeButton.BackgroundColor3); self.homeButton.TextColor3=Color3.new(1,1,1); self.homeButton.TextStrokeTransparency=1
    local homeBorder=self.homeButton:FindFirstChildOfClass('UIStroke'); homeBorder.Color=Color3.fromRGB(4,39,48); homeBorder.Thickness=4
    local homeRim=Instance.new('Frame'); homeRim.Name='InsetRim'; homeRim.Position=UDim2.fromOffset(5,5); homeRim.Size=UDim2.new(1,-10,1,-10); homeRim.BackgroundTransparency=1; homeRim.ZIndex=2; homeRim.Parent=self.homeButton
    local rimStroke=Instance.new('UIStroke'); rimStroke.Color=Color3.fromRGB(176,241,255); rimStroke.Transparency=.35; rimStroke.Thickness=2; rimStroke.Parent=homeRim
    Style.apply(self.homeButton.BrickCaption,nil,nil,3.5)
    Art.icon(self.autoButton,'gear',UDim2.fromScale(0,.05),UDim2.fromScale(.3,.8)); self.autoButton.Text='Auto'; self.autoButton.TextXAlignment=Enum.TextXAlignment.Right
    self.autoButton.BackgroundTransparency=1; self.autoButton:FindFirstChildOfClass('UIStroke').Transparency=1; self.autoButton.TextColor3=C.cream; self.autoButton.TextStrokeTransparency=1
    self.memory=text(root,'MemoryNotice',12,Color3.new(1,1,1)); self.memory.Text='STUDIO PREVIEW - progress resets on Stop'; self.memory.TextStrokeTransparency=1; self.memory.Size=UDim2.new(1,0,0,18); self.memory.Position=UDim2.new(0,0,1,-18)
    self.toast=frame(root,'Feedback',C.navy); self.toast.Visible=false; self.toast.ZIndex=20; self.toast.AnchorPoint=Vector2.new(.5,0)
    self.toast.BackgroundTransparency=1; self.toast:FindFirstChildOfClass('UIStroke').Transparency=1
    self.toastText=text(self.toast,'Message',16,C.cream); self.toastText.Size=UDim2.new(1,-16,1,-8); self.toastText.Position=UDim2.fromOffset(8,4); self.toastText.ZIndex=21
    self.toastOutline=self.toastText:FindFirstChild('TextOutline')
    self.contextPanel=frame(root,'PadAction',C.navy); self.contextPanel.Visible=false; self.contextPanel.AnchorPoint=Vector2.new(.5,1)
    self.contextPanel.BackgroundTransparency=1; self.contextPanel:FindFirstChildOfClass('UIStroke').Transparency=1
    self.contextText=text(self.contextPanel,'Summary',13,C.cream); self.contextText.Size=UDim2.new(1,-12,0,22); self.contextText.Position=UDim2.fromOffset(6,0); self.contextText.TextStrokeTransparency=1
    self.contextButton=button(self.contextPanel,'Act','',C.amber); self.contextButton.Position=UDim2.fromOffset(6,22); self.contextButton.Size=UDim2.new(1,-12,0,40)
    self.contextButton.BackgroundTransparency=1; self.contextButton:FindFirstChildOfClass('UIStroke').Transparency=1; self.contextButton.TextColor3=C.cream; self.contextButton.TextSize=20; self.contextButton.TextStrokeTransparency=1
    self.overlay=Instance.new('Frame'); self.overlay.Name='PanelOverlay'; self.overlay.Active=false; self.overlay.BorderSizePixel=0; self.overlay.Size=UDim2.fromScale(1,1); self.overlay.BackgroundColor3=Color3.new(0,0,0); self.overlay.BackgroundTransparency=.35; self.overlay.ZIndex=10; self.overlay.Visible=false; self.overlay.Parent=root
    self.panel=frame(self.overlay,'MergePanel',C.navy); self.panel.AnchorPoint=Vector2.new(.5,.5); self.panel.Position=UDim2.fromScale(.5,.5); self.panel.ZIndex=11
    self.heading=text(self.panel,'Heading',23,C.cream); self.heading.Position=UDim2.fromOffset(12,4); self.heading.Size=UDim2.new(1,-80,0,48)
    self.closeButton=button(self.panel,'Close','X',C.pink); self.closeButton.Position=UDim2.new(1,-60,0,6); self.closeButton.Size=UDim2.fromOffset(48,48)
    self.heading.ZIndex=5; self.closeButton.ZIndex=6
    self.preview=text(self.panel,'Preview',16,C.cream); self.preview.Position=UDim2.fromOffset(12,60)
    self.list=Instance.new('ScrollingFrame'); self.list.Name='Producers'; self.list.BackgroundTransparency=1; self.list.BorderSizePixel=0; self.list.ScrollBarThickness=5; self.list.CanvasSize=UDim2.new(); self.list.Parent=self.panel
    self.layout=Instance.new('UIGridLayout'); self.layout.CellPadding=UDim2.fromOffset(8,8); self.layout.SortOrder=Enum.SortOrder.LayoutOrder; self.layout.Parent=self.list
    self.confirm=button(self.panel,'Confirm','Confirm merge',C.amber); self.confirm.Position=UDim2.new(0,12,1,-62); self.confirm.Size=UDim2.new(1,-24,0,48)
    self.rebirthView=RebirthPanel.new(self,button,text,frame,Art,C)
    self.indexView=IndexPanel.new(self,text,frame,Art,C)
    self.luckyView=LuckyPanel.new(self,button,text,frame,Art,C)
    self.settingsView=SettingsPanel.new(self,button,text,frame,Art,C)
    self.mergeButton.Activated:Connect(function() self:toggleMerge() end)
    self.indexButton.Activated:Connect(function() self:open('Index') end)
    self.rebirthButton.Activated:Connect(function() self:open('Rebirth') end)
    self.settingsButton.Activated:Connect(function() self:open('Settings') end)
    self.boostButton.Activated:Connect(function() self:open('Shop') end)
    self.autoButton.Activated:Connect(function() self:open('Shop') end)
    self.homeButton.Activated:Connect(function() if not self:isOpen() then self.onHome() end end)
    self.cashPlus.Activated:Connect(function() self:open('Shop') end)
    self.closeButton.Activated:Connect(function()
        if self:isLuckyOpen() then
            if not self.pending then self.onDropLucky() end
        else self:close() end
    end)
    self.contextButton.Activated:Connect(function() self:act() end)
    self.confirm.Activated:Connect(function()
        if self.pending then return end
        if self.mode=='Index' or self.mode=='Shop' then self:close()
        elseif self.mode=='Rebirth' and self.eligible then self.onRebirth()
        elseif self.mode=='Upgrade' then self.onPass(self.upgradeKey)
        elseif self.mode=='Lucky' then if self.eligible then self.onLucky() elseif not self.state.lucky then self:close() end
        elseif self.eligible then self.onMerge(table.clone(self.selected)) end
    end)
    root:GetPropertyChangedSignal('AbsoluteSize'):Connect(function() self:resize() end)
    self.layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() self.list.CanvasSize=UDim2.fromOffset(0,self.layout.AbsoluteContentSize.Y+8) end)
    Locale.bind(gui)
    self:resize(); self:drawMerge(); return self
end
function UI.resize(self: any)
    local size=self.root.AbsoluteSize; local short=size.Y<500; local phone=size.X<600
    local compactCash=phone or (short and size.X<900)
    self.stats.TextSize=if compactCash then 30 elseif short then 40 else 52
    local amountWidth=math.min(if phone then 100 elseif compactCash then 116 else 270,math.max(if compactCash then 66 else 96,game:GetService('TextService'):GetTextSize(self.stats.Text,self.stats.TextSize,self.stats.Font,Vector2.new(1000,80)).X+14))
    local plusSize=if compactCash then 26 else 38; local multiplierWidth=if compactCash then 64 else 118
    local cashWidth=amountWidth+plusSize+multiplierWidth+32; local cashHeight=if phone then 50 elseif short then 42 else 76
    self.hud.Size=UDim2.fromOffset(cashWidth,cashHeight+29); self.hud.Position=UDim2.new(0,12,1,-cashHeight-(if phone then 132 else 49))
    self.cashBar.Position=UDim2.fromOffset(0,29); self.cashBar.Size=UDim2.fromOffset(cashWidth,cashHeight)
    self.stats.Position=UDim2.fromOffset(8,0); self.stats.Size=UDim2.new(0,amountWidth,1,0); self.stats.TextScaled=true
    local constraint=self.stats:FindFirstChildOfClass('UITextSizeConstraint') or Instance.new('UITextSizeConstraint',self.stats); constraint.MaxTextSize=self.stats.TextSize; constraint.MinTextSize=20
    self.rebirthCount.Position=UDim2.fromOffset(0,0); self.rebirthCount.Size=UDim2.fromOffset(cashWidth,28); self.rebirthCount.TextSize=if phone then 20 else 24
    self.cashPlus.Position=UDim2.new(0,amountWidth+14,.5,-plusSize/2); self.cashPlus.Size=UDim2.fromOffset(plusSize,plusSize)
    self.multiplier.Position=UDim2.new(0,amountWidth+plusSize+22,0,0); self.multiplier.Size=UDim2.new(0,multiplierWidth,1,0); self.multiplier.TextSize=if compactCash then 16 else 24; self.multiplier.Visible=true
    self.cashFog.Position=self.multiplier.Position; self.cashFog.Size=self.multiplier.Size
    local bagWidth=if phone then math.clamp(size.X-214,106,138) elseif short then 138 else 204
    self.bag.Size=UDim2.fromOffset(bagWidth,if phone then bagWidth*116/138 elseif short then 116 else 170); self.bag.AnchorPoint=Vector2.new(.5,1); self.bag.Position=if phone then UDim2.new(1,-12-bagWidth/2,1,-36) else UDim2.new(if short then .51 else .5,0,1,-24)
    self.total.AnchorPoint=Vector2.new(if phone then 0 else 1,1); self.total.Position=UDim2.new(if phone then 0 else 1,if phone then 12 else -12,1,if phone then -30 else -25); self.total.Size=UDim2.fromOffset(if phone then 210 elseif short then 230 else 330,30); self.total.TextSize=if phone then 18 elseif short then 20 else 25
    self.total.Visible=not (short and (self:isLuckyOpen() or self:isSettingsOpen()))
    local w=math.min(size.X-(if phone then 24 else 300),520)
    for _,l in {self.title,self.objective,self.hint} do l.AnchorPoint=Vector2.new(.5,0); l.Size=UDim2.fromOffset(w,if l==self.hint then 34 else 36) end
    if self.state then
        local tutorialVisible=Tutorial.goal(self.state).kind~='Done' and not self:isLuckyOpen() and not self:isSettingsOpen()
        for _,label in {self.title,self.objective,self.hint} do label.Visible=tutorialVisible end
    end
    self.title.Position=UDim2.new(.5,0,0,0); self.objective.Position=UDim2.new(.5,0,0,34); self.hint.Position=UDim2.new(.5,0,0,70)
    self.title.TextSize=if short then 23 else 28; self.objective.TextSize=if phone or short then 19 else 24; self.hint.TextSize=if phone or short then 13 else 16
    local compactRail=phone or size.Y<650
    local actionWidth=if compactRail then 72 else 92
    local actionHeight=if short then 52 elseif compactRail then 62 else 86
    local actionColumns=if phone or short then 2 else 1
    local actionsWidth=actionColumns*actionWidth+(actionColumns-1)*8
    self.actions.Size=UDim2.fromOffset(actionsWidth,math.ceil(4/actionColumns)*(actionHeight+8)); self.actions.Position=UDim2.new(1,-actionsWidth-12,0,if short then 48 elseif compactRail and not phone then 70 else 140)
    for i,b in {self.mergeButton,self.indexButton,self.rebirthButton,self.settingsButton} do b.Size=UDim2.fromOffset(actionWidth,actionHeight); b.Position=UDim2.fromOffset(((i-1)%actionColumns)*(actionWidth+8),math.floor((i-1)/actionColumns)*(actionHeight+8)); b.TextSize=if compactRail then 16 else 23 end
    self.mergeButton.Text='Merge Pad'
    self.actions.Visible=not self:isLuckyOpen() and not self:isSettingsOpen()
    self.boostButton.Position=UDim2.fromOffset(16,if short then 70 else 150); self.boostButton.Size=UDim2.fromOffset(if short then 106 elseif phone then 126 else 184,if short then 64 elseif phone then 86 else 112); self.boostButton.TextSize=if short then 24 elseif phone then 28 else 38
    self.permanent.TextSize=if phone or short then 17 else 23
    self.boostPrice.Position=self.boostButton.Position+UDim2.fromOffset(-4,self.boostButton.Size.Y.Offset+9); self.boostPrice.Size=UDim2.fromOffset(self.boostButton.Size.X.Offset+8,if short then 24 else 30); self.boostPrice.TextSize=if phone or short then 17 else 25
    self.autoButton.Position=UDim2.fromOffset(if short then 128 else 12,if short then 145 else 310); self.autoButton.Size=UDim2.fromOffset(if phone or short then 90 else 130,if short then 36 else 44)
    self.homeButton.AnchorPoint=Vector2.new(.5,0); self.homeButton.Position=UDim2.new(.5,0,0,6); self.homeButton.Size=UDim2.fromOffset(if short then 154 elseif phone then 190 else 252,if short then 40 elseif phone then 50 else 66); self.homeButton.TextSize=if phone or short then 30 else 39; self.homeButton.Visible=self.state~=nil and (self.state.tutorialStep>=7 or self:isLuckyOpen())
    self.contextPanel.Position=UDim2.new(if short then .42 else .5,0,1,if phone then -200 elseif short then -150 else -226); self.contextPanel.Size=UDim2.fromOffset(if short then 230 else math.min(320,size.X-36),62); self.contextButton.TextSize=if phone or short then 18 else 20
    self.toast.Position=UDim2.new(.5,0,0,if short then 104 else 108); self.toast.Size=UDim2.fromOffset(math.min(size.X-32,410),44); self.toastText.TextSize=if phone or short then 14 else 16
    self.panel.Size=UDim2.fromOffset(math.min(size.X-24,640),math.min(size.Y-24,620))
    self.panel.AnchorPoint=Vector2.new(.5,.5); self.panel.Position=UDim2.fromScale(.5,.5); self.panel.BackgroundColor3=C.navy; self.panel.BackgroundTransparency=if self.mode=='Rebirth' then .25 elseif self.mode=='Index' then .28 else 0
    self.panel:FindFirstChildOfClass('UIStroke').Transparency=if self.mode=='Lucky' then 1 else 0
    self.closeButton.Size=UDim2.fromOffset(48,48); self.closeButton.Position=UDim2.new(1,-60,0,6); self.closeButton.TextSize=22
    if self.mode=='Rebirth' then self.panel.Size=UDim2.fromOffset(math.min(size.X-24,500),math.min(size.Y-24,460)) end
    if self.mode=='Index' then self.panel.Size=UDim2.fromOffset(math.min(size.X-24,820),math.min(size.Y-24,650)) end
    if self.mode=='Lucky' then
        -- Native pixels keep odds and actions legible, including short landscape.
        local width=if phone then math.min(200,size.X-132) elseif short then 208 else math.clamp(size.X/6,220,280)
        local top=self.homeButton.Position.Y.Offset+self.homeButton.Size.Y.Offset+12
        local contextTop=size.Y+self.contextPanel.Position.Y.Offset-self.contextPanel.Size.Y.Offset
        local height=if phone then math.min(432,contextTop-top-12) elseif short then size.Y-28 else math.min(LuckyPanel.Height,size.Y-120)
        self.panel.Size=UDim2.fromOffset(width,height); self.panel.BackgroundTransparency=1
        self.closeButton.Size=UDim2.fromOffset(28,28); self.closeButton.Position=UDim2.new(1,-30,0,3); self.closeButton.TextSize=19
        self.panel.AnchorPoint=Vector2.new(1,if phone then 0 else .5); self.panel.Position=if phone then UDim2.new(1,-12,0,top) else UDim2.new(1,-12,.5,0)
        if phone then
            local left=size.X-12-width
            self.boostButton.Size=UDim2.fromOffset(math.min(self.boostButton.Size.X.Offset,left-28),self.boostButton.Size.Y.Offset)
            self.boostButton.Position=UDim2.fromOffset(16,math.max(self.boostButton.Position.Y.Offset,top+52))
            self.boostPrice.Position=self.boostButton.Position+UDim2.fromOffset(-4,self.boostButton.Size.Y.Offset+9); self.boostPrice.Size=UDim2.fromOffset(self.boostButton.Size.X.Offset+8,if short then 24 else 30)
            self.permanent.TextScaled=true
            self.autoButton.Position=UDim2.fromOffset(12,top); self.autoButton.Size=UDim2.fromOffset(math.min(90,left-24),36)
        end
    end
    if self.mode=='Settings' then
        local aboveHud=phone or (not short and size.X<864)
        local top=self.homeButton.Position.Y.Offset+self.homeButton.Size.Y.Offset+12
        local contextTop=size.Y+self.contextPanel.Position.Y.Offset-self.contextPanel.Size.Y.Offset
        local width=if aboveHud then math.min(292,size.X-24) elseif short then math.min(224,math.floor(size.X*.49-93)) else 300
        local height=if aboveHud then math.min(SettingsPanel.Height,contextTop-top-12) else math.min(SettingsPanel.Height,size.Y-24)
        self.panel.Size=UDim2.fromOffset(width,math.max(100,height))
        self.panel.AnchorPoint=Vector2.new(1,if aboveHud then 0 else .5)
        self.panel.Position=if aboveHud then UDim2.new(1,-12,0,top) else UDim2.new(1,-12,.5,0)
        self.panel.BackgroundTransparency=.08
        self.closeButton.Size=UDim2.fromOffset(40,40);self.closeButton.Position=UDim2.new(1,-46,0,5)
    end
    self.preview.Size=UDim2.new(1,-24,0,if short then 44 else 76); self.preview.TextSize=if short then 14 else 16
    self.list.Position=UDim2.fromOffset(12,if short then 112 else 144); self.list.Size=UDim2.new(1,-24,1,if short then -180 else -212)
    self.layout.CellSize=UDim2.new(if phone then 1 else .5,-8,0,if short then 48 else 70)
    self.indexView.resize(phone); self.luckyView.resize(); self.settingsView.resize()
end
function UI.notice(self: any,message: string)
    if self.noticeFade then self.noticeFade:Cancel() end
    if self.noticeOutlineFade then self.noticeOutlineFade:Cancel() end
    self.toastText.TextTransparency=0; self.toastOutline.Transparency=0
    self.toastText.Text=message; self.toast.Visible=true; self.noticeVersion=(self.noticeVersion or 0)+1
    local version=self.noticeVersion
    task.delay(2.4,function()
        if self.noticeVersion~=version or not self.toast.Parent then return end
        self.noticeFade=TweenService:Create(self.toastText,TweenInfo.new(.3),{TextTransparency=1}); self.noticeFade:Play()
        self.noticeOutlineFade=TweenService:Create(self.toastOutline,TweenInfo.new(.3),{Transparency=1}); self.noticeOutlineFade:Play()
        task.delay(.3,function() if self.noticeVersion==version then self.toast.Visible=false end end)
    end)
end
function UI.pickup(self: any,count: number,speciesId: string?)
    if count<=0 then return end
    self.pickupPool=self.pickupPool or {}
    local now=os.clock(); local entry=nil
    -- A quick sweep becomes one readable gain per species, rather than 50 labels.
    for _,candidate in self.pickupPool do
        if candidate.root.Visible and candidate.speciesId==speciesId and now-candidate.started<.22 then entry=candidate; break end
    end
    if not entry then
        for _,candidate in self.pickupPool do if not candidate.root.Visible then entry=candidate; break end end
        if not entry and #self.pickupPool<6 then
            local root=Instance.new('Frame'); root.Name='PickupGain'; root.BackgroundTransparency=1; root.Size=UDim2.fromOffset(144,58); root.AnchorPoint=Vector2.new(.5,1); root.ZIndex=9; root.Parent=self.bag
            local amount=text(root,'Amount',38,Style.Gold); amount.Size=UDim2.new(1,0,0,40); amount.ZIndex=10
            local species=text(root,'Species',14,Style.Cream); species.Position=UDim2.fromOffset(0,39); species.Size=UDim2.new(1,0,0,18); species.ZIndex=10
            species.TextScaled=true; local limit=Instance.new('UITextSizeConstraint'); limit.MinTextSize=12; limit.MaxTextSize=14; limit.Parent=species
            entry={root=root,amount=amount,species=species,index=#self.pickupPool+1,version=0}; table.insert(self.pickupPool,entry)
        end
        if not entry then
            -- All six lanes are occupied: fold into the newest gain, preserving count.
            entry=self.pickupPool[1]
            for _,candidate in self.pickupPool do if candidate.started>entry.started then entry=candidate end end
            entry.speciesId=nil; entry.species.Text='Minis'; entry.species.TextColor3=Style.Cream
        else
            entry.count=0; entry.speciesId=speciesId
            local species=speciesId and Catalog[speciesId]
            entry.species.Text=if species then species.name else 'Minis'
            entry.species.TextColor3=if species then Color3.fromRGB(table.unpack(species.color)) else Style.Cream
        end
    end
    entry.count+=count; entry.version+=1; local version=entry.version
    entry.started=now; entry.root.Visible=true; entry.root:SetAttribute('Count',entry.count); entry.amount.Text='+'..entry.count
    if entry.motion then entry.motion:Cancel() end
    local lane=({-25,25,0,-38,38,0})[entry.index]
    local lift=math.floor((entry.index-1)/2)*22
    entry.root.Position=UDim2.new(.5,lane,0,8-lift)
    entry.motion=TweenService:Create(entry.root,TweenInfo.new(.85,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(.5,lane,0,-58-lift)}); entry.motion:Play()
    task.delay(1,function()
        if entry.version==version and entry.root.Parent then entry.root.Visible=false end
    end)
end
function UI.unavailable(self: any,reason: string) self.state=nil; self.stats.Text='Unavailable'; self.objective.Text=reason; self:close(); self.contextPanel.Visible=false end
function UI.setPending(self: any,value: boolean) self.pending=value; self.signature=nil; self:drawMerge(); self:setContext(self.context,self.quantity) end
function UI.clearSelection(self: any) self.selected={}; self.signature=nil; self:drawMerge() end
-- Side panels leave input, proximity pickups, and pad actions live.
function UI.isOpen(self: any): boolean return self.overlay.Visible and self.mode~='Lucky' and self.mode~='Settings' end
function UI.isLuckyOpen(self: any): boolean return self.overlay.Visible and self.mode=='Lucky' end
function UI.isSettingsOpen(self: any): boolean return self.overlay.Visible and self.mode=='Settings' end
-- Programmatic closes never drop a block; only the close button requests a drop.
function UI.close(self: any)
    if self.mode~='Lucky' and self.state and self.state.lucky and self.state.lucky.held then
        self:open('Lucky'); return
    end
    self.overlay.Visible=false; self.overlay.Active=false; self:resize(); self:setContext(self.context,self.quantity)
end
function UI.open(self: any,mode: string)
    local sidePanel=mode=='Lucky' or mode=='Settings'
    self.mode=mode; self.overlay.Visible=true; self.overlay.Active=not sidePanel; self.overlay.BackgroundTransparency=if sidePanel then 1 else .35
    self.toast.Visible=false; self.signature=nil; self:resize(); self:drawMerge(); self:setContext(self.context,self.quantity)
end
function UI.toggleMerge(self: any) self.onMerge() end
function UI.offerUpgrade(self: any,multiplier: number)
    self:notice(tostring(multiplier)..'x Cash is active!')
end
function UI.refreshBoostPrice(self: any)
    local multiplier=if self.state then self.state.cashMultiplier else 1
    local key=if multiplier<2 then 'cash2' elseif multiplier<4 then 'cash4' else 'cash8'
    local info=self.shopInfo[key]; local pass=PassConfig[key]
    self.boostPrice.Text=if multiplier>=8 then 'Owned' elseif pass.id>0 and info and info.forSale and type(info.price)=='number' then tostring(info.price)..' Robux' else 'Coming soon'
end
function UI.setShopInfo(self: any,info: any) self.shopInfo=info; self:refreshBoostPrice(); self.signature=nil; self:drawMerge() end
function UI.act(self: any)
    if self.pending or self:isOpen() then return end
    if self.context~='Pass' and self.context~='Lucky' and self.context~='FinishNow' then return end
    if self.context=='Buy' then self.onBuy(self.quantity)
    elseif self.context=='Deposit' then self.onDeposit()
    elseif self.context=='Claim' then self.onClaim()
    elseif self.context=='Upgrade' then self.onUpgrade()
    elseif self.context=='Pass' then self.onPass(self.quantity)
    elseif self.context=='Lucky' then self:open('Lucky')
    elseif self.context=='FinishNow' then self:notice('Finish now is coming soon.')
    elseif self.context=='Merge' then self:toggleMerge() end
end
function UI.setContext(self: any,kind: string?,quantity: string?)
    self.context=kind; self.quantity=quantity or '1'
    self.contextPanel.Visible=kind~=nil and self.state~=nil and not self:isOpen() and not (kind=='Lucky' and self:isLuckyOpen())
    self.contextButton.Active=kind=='Pass' or kind=='Lucky' or kind=='FinishNow'
    if not self.contextPanel.Visible then return end
    local s=self.state
    if kind=='FinishNow' then self.contextText.Text='Finish all queued sales'; self.contextButton.Text='Coming soon'
    elseif kind=='Deposit' then self.contextText.Text=Economy.count(s.bag)..' Minis | '..Economy.count(s.saleQueue)..' in processor'; self.contextButton.Text='Walk onto the deposit pad'
    elseif kind=='Claim' then
        local nextSale=s.saleQueue[1]
        self.contextText.Text=if nextSale then Economy.count(s.saleQueue)..' selling | Next in '..math.max(0,math.ceil(nextSale.due-(self.estimatedServerNow or s.serverNow)))..'s' else 'All sales complete'
        self.contextButton.Text='Walk onto the cash pad'
    elseif kind=='Upgrade' then
        local cost=Config.ProcessorCosts[s.processorLevel+1]
        self.contextText.Text='Processor Lv '..s.processorLevel..' | '..Config.ProcessorRates[s.processorLevel+1]..' / s'
        self.contextButton.Text=if cost then 'Step on pad - $'..UI.coins(cost) else 'Fully upgraded!'
    elseif kind=='Pass' then
        local pass=PassConfig[self.quantity]; local info=self.shopInfo[self.quantity]
        self.contextText.Text=pass.name
        self.contextButton.Text=if info and info.forSale then 'View pass - '..info.price..' Robux' else 'Coming soon'
    elseif kind=='Lucky' then
        self.contextText.Text='A rare Lucky Block dropped!'
        self.contextButton.Text='See rewards and price'
    elseif kind=='Merge' then self.contextText.Text='Two matching Brainrots become one'; self.contextButton.Text='Step on pad to merge automatically'
    else
        local unlock=Config.BuyUnlocks[self.quantity]
        local quote=Economy.purchaseQuote(Config,s,self.quantity)
        self.contextText.Text=if quote.code=='Locked' then 'Unlocks at rebirth '..unlock else FarmCapacity.hint(Config,s)
        self.contextButton.Text=if quote.code=='Locked' then 'LOCKED - Rebirth '..unlock
            elseif quote.code=='ClaimStarter' then 'Buy your first Brainrot on the $5 pad'
            elseif quote.code=='PlotFull' then 'Not enough space - merge!'
            elseif quote.code=='BadRequest' then 'Unavailable'
            else 'Step on pad - $'..UI.coins(quote.cost)
    end
    if self.pending then self.contextButton.Text='Waiting for server...' end
end
function UI.update(self: any,state: any)
    self.state=state
    local coins=state.coinUnits/4
    self.stats.Text='$'..(if coins>=1e9 then string.format('%.2fB',coins/1e9) elseif coins>=1e6 then string.format('%.2fM',coins/1e6) elseif coins>=1e4 then string.format('%.1fK',coins/1e3) else UI.coins(state.coinUnits))
    self.detail.Text=#state.producers..' / '..Config.Slots..' Brainrots'
    self.rebirthCount.Text='Rebirth '..state.rebirths
    local total=0; local top=false
    for _,producer in state.producers do
        local tier=Catalog[producer.speciesId].tier; total+=2^(tier-1); if tier==Config.MaxTier then top=true end
    end
    self.total.Text='Total Brainrots: '..total
    self.rebirthBadge.Visible=top and state.coinUnits>=Config.RebirthBase+state.rebirths*Config.RebirthStep and state.rebirths<Config.MaxRebirths
    self.multiplier.Text='x'..((1+state.rebirths*.25)*state.cashMultiplier)..' Cash'
    self.bagText.Text=tostring(Economy.count(state.bag))
    self.bagValue.Visible=false
    local goal=Tutorial.goal(state); self.title.Text=if goal.kind=='Done' then 'MERGE A BRAINROT' else 'Tutorial'
    self.objective.Text=goal.title; self.hint.Text=goal.detail
    for _,label in {self.title,self.objective,self.hint} do label.Visible=goal.kind~='Done' end
    self.boostButton.Text=if state.cashMultiplier>=8 then '8x Cash' else tostring(state.cashMultiplier*2)..'x Cash'
    self:refreshBoostPrice()
    self.homeButton.Visible=state.tutorialStep>=7
    local owned={}; for _,p in state.producers do owned[p.id]=true end
    local keep={}; for _,id in self.selected do if owned[id] then table.insert(keep,id) end end; self.selected=keep
    self:resize(); self:setContext(self.context,self.quantity); self:drawMerge()
end
function UI.drawMerge(self: any)
    -- open() invalidates the signature and renders the latest state on demand.
    if not self.overlay.Visible then return end
    local settings=self.mode=='Settings'
    self.settingsView.setVisible(settings)
    if settings then
        self.rebirthView.setVisible(false);self.indexView.setVisible(false);self.luckyView.setVisible(false)
        self.heading.Visible=true;self.heading.Text='Settings';self.heading.Position=UDim2.fromOffset(54,4);self.heading.Size=UDim2.new(1,-108,0,48);self.heading.TextXAlignment=Enum.TextXAlignment.Left
        self.preview.Visible=false;self.list.Visible=false;self.confirm.Visible=false
        return
    end
    local s=self.state
    if not s then return end
    local signature=self.mode..tostring(self.pending)
    if self.mode=='Shop' or self.mode=='Upgrade' then
        -- Shop metadata explicitly invalidates this signature in setShopInfo.
        signature..=':'..tostring(self.upgradeKey)..':'..s.cashMultiplier..':'..s.miniMultiplier..':'..tostring(s.autoCollect)..':'..tostring(s.autoSell)
    else
        signature..=table.concat(self.selected,',')
        if s then signature..=tostring(s.coinUnits)..':'..s.rebirths..':'..s.cashMultiplier..':'..tostring(s.lucky and s.lucky.id)..':'..tostring(s.lucky and s.lucky.held)..':'..tostring(s.autoCollect)..':'..tostring(s.autoSell)..':'..s.miniMultiplier..':'..tostring(s.eventHundredths)..':'..tostring(s.obbyBonusHundredths or 0); for _,p in s.producers do signature..=p.id..p.speciesId end end
    end
    if self.signature==signature then return end; self.signature=signature
    local scroll=self.list.CanvasPosition
    for _,child in self.list:GetChildren() do if child:IsA('GuiObject') then child:Destroy() end end
    self.eligible=false; self.confirm.Text='Close'; self.confirm.Visible=true
    self.heading.Visible=true; self.heading.Size=UDim2.new(1,-80,0,48)
    local rebirth=self.mode=='Rebirth'; local index=self.mode=='Index'; local lucky=self.mode=='Lucky'
    self.rebirthView.setVisible(rebirth); self.indexView.setVisible(index); self.luckyView.setVisible(lucky)
    self.preview.Visible=not (rebirth or index or lucky); self.list.Visible=not (rebirth or index or lucky); self.confirm.Visible=not (rebirth or index or lucky)
    local function card(name: string,label: string,color: Color3,order: number,callback: (() -> ())?)
        local b=button(self.list,name,label,color); b.LayoutOrder=order
        if callback then b.Activated:Connect(callback) else b.AutoButtonColor=false end
        return b
    end
    if self.mode=='Index' then
        self.heading.Text='Index'; self.indexView.render(s)
    elseif self.mode=='Lucky' then
        self.luckyView.render(s)
    elseif self.mode=='Rebirth' then
        self.heading.Text='Rebirth'; self.rebirthView.render(s)
    elseif self.mode=='Shop' or self.mode=='Upgrade' then
        self.heading.Text=if self.mode=='Upgrade' then 'Boost unlocked! Want the next level?' else 'Permanent boosts'
        self.preview.Text='Money boosts use your highest level. Auto Collect picks up + deposits. Auto Sell collects completed payouts.'
        for i,key in {'cash2','cash4','cash8','autoCollect','autoSell','mini2'} do
            local pass=PassConfig[key]; local info=self.shopInfo[key]
            local owned=(key=='cash2' and s.cashMultiplier>=2) or (key=='cash4' and s.cashMultiplier>=4) or (key=='cash8' and s.cashMultiplier>=8) or (key=='autoCollect' and s.autoCollect) or (key=='autoSell' and s.autoSell) or (key=='mini2' and s.miniMultiplier==2)
            local available=info and info.forSale and pass.id>0
            local price=if owned then 'OWNED' elseif available then tostring(info.price)..' Robux' else 'Coming soon'
            local colors={cash2=C.green,cash4=C.blue,cash8=C.violet,autoCollect=C.amber,autoSell=C.pink,mini2=C.green}
            local b=card(key,pass.name..'\n'..price,colors[key],i,function() if not owned and available then self.onPass(key) end end)
            b.TextColor3=Color3.new(1,1,1); b.TextStrokeTransparency=1; b.TextStrokeColor3=C.navy; b.TextSize=20
            Art.brick(b,colors[key]); b.AutoButtonColor=available and not owned
            local caption=b:FindFirstChild('BrickCaption'); if caption then caption.TextScaled=true; local limit=Instance.new('UITextSizeConstraint');limit.MaxTextSize=23;limit.MinTextSize=12;limit.Parent=caption end
        end
        if self.mode=='Upgrade' then
            local info=self.shopInfo[self.upgradeKey]; self.eligible=info and info.forSale or false
            self.confirm.Text=if self.eligible then 'Upgrade - '..info.price..' Robux' else 'Continue playing'
            if not self.eligible then self.mode='Shop' end
        end
    else
        self.heading.Text='Merge your Brainrots!'
        local producers=table.clone(s.producers); table.sort(producers,function(a: any,b: any) return a.slot<b.slot end)
        local pair={}
        for order,p in producers do
            local species=Catalog[p.speciesId]; local selected=table.find(self.selected,p.id)
            if selected then pair[selected]=p end
            local entry=card('Producer_'..p.slot,(if selected then '[ '..selected..' ] ' else '')..species.name..'\nLevel '..species.tier..' | Row '..math.ceil(p.slot/Config.Columns),if selected then C.violet else C.cream,order,function()
                if self.pending then return end
                local index=table.find(self.selected,p.id)
                if index then table.remove(self.selected,index) elseif #self.selected<2 then table.insert(self.selected,p.id) else self.selected={p.id} end
                self.signature=nil; self:drawMerge()
            end)
            Art.cardPortrait(entry,p.speciesId)
        end
        self.preview.Text='Select two matching Brainrots.\nMerging is free and makes room in your stack.'
        if #pair==2 then
            local first=Catalog[pair[1].speciesId]
            if pair[1].speciesId~=pair[2].speciesId then self.preview.Text='These Brainrots do not match.'
            elseif not first.nextId then self.preview.Text='Highest tier! Keep this Brainrot or rebirth.'
            else self.eligible=true; self.preview.Text=first.name..' x2 -> '..Catalog[first.nextId].name..'\n'..s.miniMultiplier..' Mini'..(if s.miniMultiplier==2 then 's' else '')..' / '..Config.Interval..'s each · $'..UI.coins(Catalog[first.nextId].value*(4+s.rebirths)*s.cashMultiplier)..' per Mini after merge' end
        end
        self.confirm.Text='Confirm merge'
    end
    if self.pending then self.confirm.Text='Waiting for server...' end
    self.confirm.BackgroundTransparency=if self.pending or (not self.eligible and (self.mode=='Merge' or self.mode=='Rebirth')) then .5 else 0
    self.list.CanvasPosition=scroll
end
return UI
