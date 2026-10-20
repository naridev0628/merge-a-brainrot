--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Config=require(Shared:WaitForChild('Config'))
local Economy=require(Shared:WaitForChild('Economy'))
local Tutorial=require(Shared:WaitForChild('Tutorial'))
local PassConfig=require(Shared:WaitForChild('PassConfig'))
local Art=require(script.Parent:WaitForChild('BrickArt'))
local Locale=require(script.Parent:WaitForChild('Locale'))
local RebirthPanel=require(script.Parent:WaitForChild('RebirthPanel'))
local IndexPanel=require(script.Parent:WaitForChild('IndexPanel'))
local LuckyPanel=require(script.Parent:WaitForChild('LuckyPanel'))
local TweenService=game:GetService('TweenService')
local UI={}; UI.__index=UI
local C={navy=Color3.fromRGB(26,37,49),cream=Color3.fromRGB(255,248,216),green=Color3.fromRGB(115,245,42),blue=Color3.fromRGB(32,191,243),amber=Color3.fromRGB(255,204,36),violet=Color3.fromRGB(172,94,235),pink=Color3.fromRGB(248,120,174)}
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
    l.TextSize=size; l.Font=Enum.Font.FredokaOne; l.TextWrapped=true; l.Parent=parent; return l
end
local function button(parent: Instance,name: string,label: string,color: Color3): TextButton
    local b=Instance.new('TextButton'); b.Name=name; b.Text=label; b.BackgroundColor3=color; b.TextColor3=C.navy
    b.Font=Enum.Font.FredokaOne; b.TextSize=18; b.TextWrapped=true; b.BorderSizePixel=0; b.Parent=parent
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
    return b
end
function UI.new(parent: Instance)
    local self: any=setmetatable({selected={},pending=false,state=nil,context=nil,quantity='1',mode='Merge',shopInfo={},onBuy=function() end,onDeposit=function() end,onClaim=function() end,onMerge=function() end,onRebirth=function() end,onHome=function() end,onPass=function() end},UI)
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
    self.stats.TextColor3=C.green; self.stats.TextStrokeTransparency=0; self.stats.TextStrokeColor3=Color3.fromRGB(23,47,12); self.stats.TextXAlignment=Enum.TextXAlignment.Left
    self.detail.TextColor3=C.cream; self.detail.TextStrokeTransparency=0; self.detail.TextXAlignment=Enum.TextXAlignment.Left
    self.rebirthCount=text(self.hud,'RebirthCount',24,Color3.new(1,1,1)); self.rebirthCount.TextStrokeTransparency=0; self.rebirthCount.TextXAlignment=Enum.TextXAlignment.Left
    local rebirthGradient=Instance.new('UIGradient'); rebirthGradient.Rotation=90; rebirthGradient.Color=ColorSequence.new(Color3.fromRGB(255,172,179),Color3.fromRGB(255,61,67)); rebirthGradient.Parent=self.rebirthCount
    self.multiplier=text(root,'CashMultiplier',22,Color3.fromRGB(179,183,178)); self.multiplier.TextStrokeTransparency=0; self.multiplier.TextXAlignment=Enum.TextXAlignment.Left
    self.cashPlus=button(self.hud,'CashPlus','+',C.green); self.cashPlus.TextSize=30; self.cashPlus.TextColor3=C.cream; self.cashPlus.TextStrokeTransparency=0
    self.multiplier.Parent=self.hud; self.detail.Visible=false
    self.cashFog=Instance.new('Frame'); self.cashFog.Name='MultiplierFog'; self.cashFog.BackgroundTransparency=1; self.cashFog.Parent=self.hud
    for layer=1,6 do
        local haze=Instance.new('Frame'); haze.Name='Fog'..layer; haze.AnchorPoint=Vector2.new(.5,.5); haze.Position=UDim2.fromScale(.5,.5); haze.Size=UDim2.fromScale(1.22-layer*.065,1.45-layer*.12); haze.BackgroundColor3=Color3.fromRGB(20,22,22); haze.BackgroundTransparency=.94; haze.BorderSizePixel=0; haze.Parent=self.cashFog
        local round=Instance.new('UICorner'); round.CornerRadius=UDim.new(1,0); round.Parent=haze
    end
    self.multiplier.ZIndex=2; self.cashPlus.ZIndex=2
    self.stats.TextStrokeTransparency=1
    local cashOutline=Instance.new('UIStroke'); cashOutline.Thickness=3; cashOutline.Color=Color3.fromRGB(20,49,5); cashOutline.Parent=self.stats
    self.stats.TextColor3=Color3.new(1,1,1)
    local cashGradient=Instance.new('UIGradient'); cashGradient.Rotation=90; cashGradient.Color=ColorSequence.new(Color3.fromRGB(184,255,25),Color3.fromRGB(76,211,0)); cashGradient.Parent=self.stats
    self.stats.Parent=self.cashBar; self.cashPlus.Parent=self.cashBar; self.multiplier.Parent=self.cashBar; self.cashFog.Parent=self.cashBar
    self.total=text(root,'TotalBrainrots',24,Color3.new(1,1,1)); self.total.TextStrokeTransparency=1; self.total.TextXAlignment=Enum.TextXAlignment.Right
    local totalOutline=Instance.new('UIStroke'); totalOutline.Thickness=2.5; totalOutline.Color=Color3.fromRGB(49,35,10); totalOutline.Parent=self.total
    local totalGradient=Instance.new('UIGradient'); totalGradient.Rotation=90; totalGradient.Color=ColorSequence.new(Color3.fromRGB(255,249,188),Color3.fromRGB(255,203,68)); totalGradient.Parent=self.total
    self.bag=Instance.new('Frame'); self.bag.Name='MiniBag'; self.bag.BackgroundTransparency=1; self.bag.Parent=root; Art.basket(self.bag)
    self.bagText=text(self.bag,'Count',32,C.cream); self.bagText.Size=UDim2.fromScale(.60,.32); self.bagText.Position=UDim2.fromScale(.20,.60); self.bagText.TextStrokeTransparency=0; self.bagText.ZIndex=4
    self.bagText.TextScaled=true
    local countSize=Instance.new('UITextSizeConstraint'); countSize.MinTextSize=12; countSize.MaxTextSize=32; countSize.Parent=self.bagText
    local bagCaption=text(self.bag,'Caption',23,C.cream); bagCaption.Text='Minis'; bagCaption.Position=UDim2.fromScale(.12,.30); bagCaption.Size=UDim2.fromScale(.76,.25); bagCaption.TextStrokeTransparency=0; bagCaption.ZIndex=4
    self.bagValue=text(self.bag,'Value',16,C.green); self.bagValue.Size=UDim2.new(1,40,0,24); self.bagValue.Position=UDim2.new(0,-20,1,0); self.bagValue.TextStrokeTransparency=0; self.bagValue.ZIndex=4; self.bagValue.Visible=false
    self.title=text(root,'TutorialTitle',28,C.blue); self.title.TextStrokeTransparency=0; self.title.TextStrokeColor3=C.navy
    self.objective=text(root,'Objective',24,Color3.new(1,1,1)); self.objective.TextStrokeTransparency=0; self.objective.TextStrokeColor3=C.navy
    self.hint=text(root,'Hint',16,Color3.new(1,1,1)); self.hint.TextStrokeTransparency=0; self.hint.TextStrokeColor3=C.navy
    self.actions=Instance.new('Frame'); self.actions.Name='Actions'; self.actions.BackgroundTransparency=1; self.actions.Parent=root
    self.mergeButton=button(self.actions,'Merge','Merge [M]',C.amber)
    self.indexButton=button(self.actions,'Index','Index',C.blue)
    self.rebirthButton=button(self.actions,'Rebirth','Rebirth',C.pink)
    for i,b in {self.mergeButton,self.indexButton,self.rebirthButton} do
        b.TextYAlignment=Enum.TextYAlignment.Bottom; b.TextColor3=C.cream; b.TextStrokeTransparency=0; b.BackgroundTransparency=1
        b:FindFirstChildOfClass('UIStroke').Transparency=1
        Art.icon(b,({'merge','book','rebirth'})[i],UDim2.fromScale(.1,.01),UDim2.fromScale(.8,.73))
    end
    self.rebirthBadge=frame(self.rebirthButton,'ReadyBadge',Color3.fromRGB(255,62,69)); self.rebirthBadge.Size=UDim2.fromOffset(28,28); self.rebirthBadge.Position=UDim2.fromOffset(-9,-9); self.rebirthBadge.ZIndex=6; self.rebirthBadge.Visible=false
    self.rebirthBadge:FindFirstChildOfClass('UICorner').CornerRadius=UDim.new(1,0)
    local alert=text(self.rebirthBadge,'Alert',25,C.cream); alert.Text='!'; alert.TextStrokeTransparency=0; alert.Size=UDim2.fromScale(1,1); alert.ZIndex=7
    self.homeButton=button(root,'Home','My plot',C.cream)
    self.boostButton=button(root,'MoneyBoost','2x MONEY',C.green)
    self.autoButton=button(root,'Automation','Auto Collect\nAuto Sell',C.amber)
    Art.brick(self.boostButton,C.green); self.boostButton.TextColor3=Color3.fromRGB(88,255,0); self.boostButton.TextStrokeTransparency=0; self.boostButton.TextStrokeColor3=Color3.fromRGB(0,35,0)
    self.boostButton.TextSize=40; self.boostButton.TextYAlignment=Enum.TextYAlignment.Center
    local rainbow=self.boostButton:FindFirstChildOfClass('UIStroke'); rainbow.Color=Color3.new(1,1,1); rainbow.Thickness=5
    local spectrum=Instance.new('UIGradient'); spectrum.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,45,45)),ColorSequenceKeypoint.new(.2,Color3.fromRGB(255,234,0)),ColorSequenceKeypoint.new(.4,Color3.fromRGB(40,255,30)),ColorSequenceKeypoint.new(.6,Color3.fromRGB(0,195,255)),ColorSequenceKeypoint.new(.8,Color3.fromRGB(110,55,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,45,130))}); spectrum.Parent=rainbow
    TweenService:Create(spectrum,TweenInfo.new(3,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360}):Play()
    local boostOutline=Instance.new('UIStroke'); boostOutline.Thickness=3; boostOutline.Color=Color3.fromRGB(0,20,0); boostOutline.Parent=self.boostButton.BrickCaption
    self.permanent=text(self.boostButton,'Permanent',18,Color3.fromRGB(255,102,106)); self.permanent.Text='PERMANENT!'; self.permanent.Rotation=-5; self.permanent.Position=UDim2.fromScale(-.03,-.16); self.permanent.Size=UDim2.fromScale(1.06,.28); self.permanent.TextStrokeTransparency=0; self.permanent.ZIndex=4
    self.boostPrice=text(root,'BoostPrice',17,C.cream); self.boostPrice.Text='Coming soon'; self.boostPrice.TextStrokeTransparency=0
    Art.brick(self.homeButton,C.blue); self.homeButton.BackgroundColor3=C.blue; self.homeButton.Text='Home'; self.homeButton.TextColor3=C.cream; self.homeButton.TextStrokeTransparency=0
    Art.icon(self.autoButton,'gear',UDim2.fromScale(0,.05),UDim2.fromScale(.3,.8)); self.autoButton.Text='Auto'; self.autoButton.TextXAlignment=Enum.TextXAlignment.Right
    self.autoButton.BackgroundTransparency=1; self.autoButton:FindFirstChildOfClass('UIStroke').Transparency=1; self.autoButton.TextColor3=C.cream; self.autoButton.TextStrokeTransparency=0
    self.memory=text(root,'MemoryNotice',12,Color3.new(1,1,1)); self.memory.Text='STUDIO PREVIEW - progress resets on Stop'; self.memory.TextStrokeTransparency=0; self.memory.Size=UDim2.new(1,0,0,18); self.memory.Position=UDim2.new(0,0,1,-18)
    self.toast=frame(root,'Feedback',C.navy); self.toast.Visible=false; self.toast.ZIndex=20; self.toast.AnchorPoint=Vector2.new(.5,0)
    self.toast.BackgroundTransparency=1; self.toast:FindFirstChildOfClass('UIStroke').Transparency=1
    self.toastText=text(self.toast,'Message',16,C.cream); self.toastText.Size=UDim2.new(1,-16,1,-8); self.toastText.Position=UDim2.fromOffset(8,4); self.toastText.ZIndex=21
    self.toastOutline=Instance.new('UIStroke'); self.toastOutline.Color=Color3.fromRGB(28,29,24); self.toastOutline.Thickness=2; self.toastOutline.Parent=self.toastText
    self.contextPanel=frame(root,'PadAction',C.navy); self.contextPanel.Visible=false; self.contextPanel.AnchorPoint=Vector2.new(.5,1)
    self.contextPanel.BackgroundTransparency=1; self.contextPanel:FindFirstChildOfClass('UIStroke').Transparency=1
    self.contextText=text(self.contextPanel,'Summary',13,C.cream); self.contextText.Size=UDim2.new(1,-12,0,22); self.contextText.Position=UDim2.fromOffset(6,0); self.contextText.TextStrokeTransparency=0
    self.contextButton=button(self.contextPanel,'Act','',C.amber); self.contextButton.Position=UDim2.fromOffset(6,22); self.contextButton.Size=UDim2.new(1,-12,0,40)
    self.contextButton.BackgroundTransparency=1; self.contextButton:FindFirstChildOfClass('UIStroke').Transparency=1; self.contextButton.TextColor3=C.cream; self.contextButton.TextSize=20; self.contextButton.TextStrokeTransparency=0
    self.overlay=Instance.new('TextButton'); self.overlay.Name='MergeOverlay'; self.overlay.Text=''; self.overlay.AutoButtonColor=false; self.overlay.Size=UDim2.fromScale(1,1); self.overlay.BackgroundColor3=Color3.new(0,0,0); self.overlay.BackgroundTransparency=.35; self.overlay.ZIndex=10; self.overlay.Visible=false; self.overlay.Parent=root
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
    self.mergeButton.Activated:Connect(function() self:toggleMerge() end)
    self.indexButton.Activated:Connect(function() self:open('Index') end)
    self.rebirthButton.Activated:Connect(function() self:open('Rebirth') end)
    self.boostButton.Activated:Connect(function() self:open('Shop') end)
    self.autoButton.Activated:Connect(function() self:open('Shop') end)
    self.homeButton.Activated:Connect(function() if not self:isOpen() then self.onHome() end end)
    self.cashPlus.Activated:Connect(function() self:open('Shop') end)
    self.closeButton.Activated:Connect(function() self:close() end)
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
    local size=self.root.AbsoluteSize; local short=size.Y<440; local phone=size.X<600
    local compactCash=phone or (short and size.X<900)
    self.stats.TextSize=if compactCash then 30 elseif short then 40 else 52
    local amountWidth=math.min(if compactCash then 116 else 270,math.max(if compactCash then 66 else 96,game:GetService('TextService'):GetTextSize(self.stats.Text,self.stats.TextSize,self.stats.Font,Vector2.new(1000,80)).X+14))
    local plusSize=if compactCash then 26 else 38; local multiplierWidth=if compactCash then 64 else 118
    local cashWidth=amountWidth+plusSize+multiplierWidth+32; local cashHeight=if phone then 50 elseif short then 58 else 76
    self.hud.Size=UDim2.fromOffset(cashWidth,cashHeight+29); self.hud.Position=UDim2.new(0,12,1,-cashHeight-(if phone then 164 else 53))
    self.cashBar.Position=UDim2.fromOffset(0,29); self.cashBar.Size=UDim2.fromOffset(cashWidth,cashHeight)
    self.stats.Position=UDim2.fromOffset(8,0); self.stats.Size=UDim2.new(0,amountWidth,1,0); self.stats.TextScaled=true
    local constraint=self.stats:FindFirstChildOfClass('UITextSizeConstraint') or Instance.new('UITextSizeConstraint',self.stats); constraint.MaxTextSize=self.stats.TextSize; constraint.MinTextSize=20
    self.rebirthCount.Position=UDim2.fromOffset(0,0); self.rebirthCount.Size=UDim2.fromOffset(cashWidth,28); self.rebirthCount.TextSize=if phone then 20 else 24
    self.cashPlus.Position=UDim2.new(0,amountWidth+14,.5,-plusSize/2); self.cashPlus.Size=UDim2.fromOffset(plusSize,plusSize)
    self.multiplier.Position=UDim2.new(0,amountWidth+plusSize+22,0,0); self.multiplier.Size=UDim2.new(0,multiplierWidth,1,0); self.multiplier.TextSize=if compactCash then 16 else 24; self.multiplier.Visible=true
    self.cashFog.Position=self.multiplier.Position; self.cashFog.Size=self.multiplier.Size
    self.bag.Size=UDim2.fromOffset(if phone or short then 126 else 178,if phone or short then 102 else 145); self.bag.AnchorPoint=Vector2.new(.5,1); self.bag.Position=UDim2.new(if phone then .78 else .5,0,1,if phone then -250 else -44)
    self.total.AnchorPoint=Vector2.new(1,1); self.total.Position=UDim2.new(1,-12,1,if phone then -103 else -25); self.total.Size=UDim2.fromOffset(if phone then 210 elseif short then 230 else 330,30); self.total.TextSize=if phone then 18 elseif short then 20 else 25
    local w=math.min(size.X-(if phone then 24 else 300),520)
    for _,l in {self.title,self.objective,self.hint} do l.AnchorPoint=Vector2.new(.5,0); l.Size=UDim2.fromOffset(w,if l==self.hint then 34 else 36) end
    self.title.Position=UDim2.new(.5,0,0,0); self.objective.Position=UDim2.new(.5,0,0,34); self.hint.Position=UDim2.new(.5,0,0,70)
    self.title.TextSize=if short then 23 else 28; self.objective.TextSize=if phone or short then 19 else 24; self.hint.TextSize=if phone or short then 13 else 16
    local actionWidth=if phone or short then 72 else 92
    local actionHeight=if phone or short then 62 else 86
    self.actions.Size=UDim2.fromOffset(actionWidth,3*(actionHeight+8)); self.actions.Position=UDim2.new(1,-actionWidth-12,0,if short then 65 else 140)
    for i,b in {self.mergeButton,self.indexButton,self.rebirthButton} do b.Size=UDim2.new(1,0,0,actionHeight); b.Position=UDim2.fromOffset(0,(i-1)*(actionHeight+8)); b.TextSize=if short or phone then 16 else 23 end
    self.mergeButton.Text='Merge pad'
    self.boostButton.Position=UDim2.fromOffset(12,if short then 74 else 150); self.boostButton.Size=UDim2.fromOffset(if phone or short then 112 else 175,if short then 85 else 120); self.boostButton.TextSize=if short or phone then 26 else 36
    self.boostPrice.Position=self.boostButton.Position+UDim2.fromOffset(0,self.boostButton.Size.Y.Offset+5); self.boostPrice.Size=UDim2.fromOffset(self.boostButton.Size.X.Offset,22); self.boostPrice.TextSize=if phone or short then 14 else 18
    self.autoButton.Position=UDim2.fromOffset(12,if short then 194 else 310); self.autoButton.Size=UDim2.fromOffset(if phone or short then 90 else 130,44)
    self.homeButton.AnchorPoint=Vector2.new(.5,0); self.homeButton.Position=UDim2.new(.5,0,0,4); self.homeButton.Size=UDim2.fromOffset(160,42); self.homeButton.Visible=self.state~=nil and self.state.tutorialStep>=7
    self.contextPanel.Position=UDim2.new(.5,0,1,if phone then -300 elseif short then -178 else -226); self.contextPanel.Size=UDim2.fromOffset(math.min(320,size.X-36),62); self.contextButton.TextSize=if phone or short then 18 else 20
    self.toast.Position=UDim2.new(.5,0,0,if short then 104 else 108); self.toast.Size=UDim2.fromOffset(math.min(size.X-32,410),44); self.toastText.TextSize=if phone or short then 14 else 16
    self.panel.Size=UDim2.fromOffset(math.min(size.X-24,640),math.min(size.Y-24,620))
    self.panel.AnchorPoint=Vector2.new(.5,.5); self.panel.Position=UDim2.fromScale(.5,.5); self.panel.BackgroundColor3=C.navy
    self.closeButton.Size=UDim2.fromOffset(48,48); self.closeButton.Position=UDim2.new(1,-60,0,6)
    if self.mode=='Index' then self.panel.Size=UDim2.fromOffset(math.min(size.X-24,820),math.min(size.Y-24,650)) end
    if self.mode=='Lucky' then
        local scale=math.min(1,(size.X-24)/340,(size.Y-24)/560)
        self.panel.Size=UDim2.fromOffset(340*scale,560*scale)
        self.closeButton.Size=UDim2.fromOffset(38*scale,38*scale); self.closeButton.Position=UDim2.new(1,-46*scale,0,8*scale)
        if not phone then self.panel.AnchorPoint=Vector2.new(1,.5); self.panel.Position=UDim2.new(1,-12,.5,0) end
    end
    self.preview.Size=UDim2.new(1,-24,0,if short then 44 else 76); self.preview.TextSize=if short then 14 else 16
    self.list.Position=UDim2.fromOffset(12,if short then 112 else 144); self.list.Size=UDim2.new(1,-24,1,if short then -180 else -212)
    self.layout.CellSize=UDim2.new(if phone then 1 else .5,-8,0,if short then 48 else 70)
    self.indexView.resize(phone); self.luckyView.resize()
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
    self.pickupSerial=(self.pickupSerial or 0)+1
    local lane=({-42,34,-12,54,-52,12})[(self.pickupSerial-1)%6+1]
    local popup=text(self.bag,'PickupGain',25,if speciesId and Catalog[speciesId] then Color3.fromRGB(table.unpack(Catalog[speciesId].color)) else C.cream)
    popup.AnchorPoint=Vector2.new(.5,1); popup.Position=UDim2.new(.5,lane,0,12); popup.Size=UDim2.fromOffset(120,45); popup.Text='+'..count; popup.TextSize=34; popup.Rotation=lane/9; popup.ZIndex=9
    local outline=Instance.new('UIStroke'); outline.Color=Color3.fromRGB(20,15,12); outline.Thickness=3; outline.Parent=popup
    local scale=Instance.new('UIScale'); scale.Scale=.65; scale.Parent=popup
    TweenService:Create(scale,TweenInfo.new(.18,Enum.EasingStyle.Back),{Scale=1}):Play()
    TweenService:Create(popup,TweenInfo.new(.75,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(.5,lane*1.2,0,-72)}):Play()
    task.delay(.65,function()
        if not popup.Parent then return end
        TweenService:Create(popup,TweenInfo.new(.35),{TextTransparency=1}):Play()
        TweenService:Create(outline,TweenInfo.new(.35),{Transparency=1}):Play()
    end)
    game:GetService('Debris'):AddItem(popup,1.05)
end
function UI.unavailable(self: any,reason: string) self.state=nil; self.stats.Text='Unavailable'; self.objective.Text=reason; self:close(); self.contextPanel.Visible=false end
function UI.setPending(self: any,value: boolean) self.pending=value; self.signature=nil; self:drawMerge(); self:setContext(self.context,self.quantity) end
function UI.clearSelection(self: any) self.selected={}; self.signature=nil; self:drawMerge() end
function UI.isOpen(self: any): boolean return self.overlay.Visible end
function UI.close(self: any) self.overlay.Visible=false; self:setContext(self.context,self.quantity) end
function UI.open(self: any,mode: string) self.mode=mode; self.overlay.Visible=true; self.toast.Visible=false; self.signature=nil; self:resize(); self:drawMerge(); self:setContext(self.context,self.quantity) end
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
    self.contextPanel.Visible=kind~=nil and self.state~=nil and not self:isOpen()
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
        local free=self.quantity=='1' and not s.starterClaimed
        self.contextText.Text=if s.rebirths<unlock then 'Unlocks at rebirth '..unlock else tostring(Config.Slots-#s.producers)..' spaces left'
        local amount=if self.quantity=='100' then math.min(100,Config.Slots-#s.producers) else tonumber(self.quantity)
        self.contextButton.Text=if s.rebirths<unlock then 'LOCKED - Rebirth '..unlock elseif free then 'Walk onto the pad - $5' elseif amount==0 then 'Maximum reached - merge!' else 'Step on pad - $'..UI.coins(Economy.buyCost(s.purchased or 0,amount,if self.quantity=='100' then math.clamp(s.rebirths,1,Config.MaxTier) else 1))
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
    local s=self.state
    if not s then return end
    local signature=self.mode..tostring(self.pending)..table.concat(self.selected,',')
    if s then signature..=tostring(s.coinUnits)..':'..s.rebirths..':'..s.cashMultiplier..':'..tostring(s.lucky and s.lucky.id)..':'..tostring(s.autoCollect)..':'..tostring(s.autoSell)..':'..s.miniMultiplier; for _,p in s.producers do signature..=p.id..p.speciesId end end
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
            b.TextColor3=Color3.new(1,1,1); b.TextStrokeTransparency=0; b.TextStrokeColor3=C.navy; b.TextSize=20
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
