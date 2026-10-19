--!strict
-- Local collection celebration. Text has no panel; all 3D accents are native parts.
local TweenService=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local CashEffects={}
local green=Color3.fromRGB(154,255,35)
local function neon(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3): Part
    local part=Instance.new('Part'); part.Name=name; part.Size=size; part.CFrame=cf; part.Color=color
    part.Material=Enum.Material.Neon; part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.CastShadow=false; part.Parent=parent
    return part
end
local function celebrateCharacter(character: Model?)
    local root=character and character:FindFirstChild('HumanoidRootPart')
    if not root or not root:IsA('BasePart') then return end
    local burst=Instance.new('Folder'); burst.Name='CashCollectionBurst'; burst.Parent=workspace; Debris:AddItem(burst,1.9)
    local origin=root.Position-Vector3.new(0,1.75,0)
    for ray=1,8 do
        local angle=ray*math.pi/4
        local direction=Vector3.new(math.cos(angle),0,math.sin(angle))
        local function point(t: number): Vector3
            return origin+direction*(.35+t*3.5)+Vector3.new(0,math.sin(t*math.pi)*1.55-t*.4,0)
        end
        for segment=1,7 do
            local a=point((segment-1)/7); local b=point(segment/7)
            local streak=neon(burst,'Arc',Vector3.new(.065,.065,(b-a).Magnitude+.025),CFrame.lookAt((a+b)/2,b),if ray%2==0 then green else Color3.fromRGB(226,255,167))
            streak.Transparency=1
            task.delay((segment-1)*.035,function()
                if not streak.Parent then return end
                TweenService:Create(streak,TweenInfo.new(.09),{Transparency=.1}):Play()
                task.delay(.22,function()
                    if streak.Parent then TweenService:Create(streak,TweenInfo.new(.65),{Transparency=1,Size=Vector3.new(.015,.015,streak.Size.Z)}):Play() end
                end)
            end)
        end
    end
    for index=1,10 do
        local angle=index*math.pi*.2; local radius=1.3+(index%3)*.45
        local offset=Vector3.new(math.cos(angle)*radius,.4+(index%4)*.35,math.sin(angle)*radius)
        local center=origin+offset
        local drift=Vector3.new(offset.X*.5,1.1+(index%3)*.3,offset.Z*.5)
        for axis=1,3 do
            local size=if axis==1 then Vector3.new(.4,.075,.075) elseif axis==2 then Vector3.new(.075,.4,.075) else Vector3.new(.075,.075,.4)
            local sparkle=neon(burst,'Sparkle',size,CFrame.new(center),if index%2==0 then Color3.fromRGB(236,255,197) else green)
            TweenService:Create(sparkle,TweenInfo.new(.85+(index%3)*.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.new(center+drift)*CFrame.Angles(.3,.5,.2),Size=size*.15,Transparency=1}):Play()
        end
    end
end
function CashEffects.play(gui: ScreenGui,character: Model?,amountText: string)
    if not gui.Parent then return end
    local root=gui:FindFirstChild('SafeArea')
    local parent: Instance=if root and root:IsA('GuiObject') then root else gui
    local previous=parent:FindFirstChild('CashCollectionFeedback')
    if previous then previous:Destroy() end
    local label=Instance.new('TextLabel'); label.Name='CashCollectionFeedback'; label.AnchorPoint=Vector2.new(.5,1)
    label.BackgroundTransparency=1; label.BorderSizePixel=0; label.Text='Collected $'..amountText..' Cash!'
    label.Font=Enum.Font.FredokaOne; label.TextColor3=Color3.new(1,1,1); label.TextScaled=true; label.ZIndex=35; label.Parent=parent
    local constraint=Instance.new('UITextSizeConstraint'); constraint.MaxTextSize=42; constraint.MinTextSize=16; constraint.Parent=label
    local outline=Instance.new('UIStroke'); outline.Color=Color3.fromRGB(22,57,4); outline.Thickness=3; outline.Parent=label
    local gradient=Instance.new('UIGradient'); gradient.Rotation=90; gradient.Color=ColorSequence.new(Color3.fromRGB(194,255,47),Color3.fromRGB(86,223,0)); gradient.Parent=label
    local scale=Instance.new('UIScale'); scale.Scale=.72; scale.Parent=label
    local rise=Instance.new('NumberValue'); rise.Name='Rise'; rise.Parent=label
    local function position()
        if not label.Parent then return end
        local camera=workspace.CurrentCamera
        local area=if root and root:IsA('GuiObject') then root.AbsoluteSize else (if camera then camera.ViewportSize else Vector2.new(800,600))
        local areaOrigin=if root and root:IsA('GuiObject') then root.AbsolutePosition else Vector2.zero
        local bag=root and root:FindFirstChild('MiniBag')
        local width=math.max(100,math.min(560,area.X-28)); local height=if area.X<600 then 42 else 54
        local x=area.X*.5; local y=area.Y-190
        if bag and bag:IsA('GuiObject') then
            x=bag.AbsolutePosition.X-areaOrigin.X+bag.AbsoluteSize.X*.5
            -- Basket portraits extend slightly above their frame.
            y=bag.AbsolutePosition.Y-areaOrigin.Y-14
        end
        x=math.clamp(x,width/2+12,math.max(width/2+12,area.X-width/2-12))
        label.Size=UDim2.fromOffset(width,height); label.Position=UDim2.fromOffset(x,math.max(height+8,y-rise.Value))
        constraint.MaxTextSize=if area.X<600 then 29 else 42
    end
    local positionChanged=rise:GetPropertyChangedSignal('Value'):Connect(position)
    local resized=if root and root:IsA('GuiObject') then root:GetPropertyChangedSignal('AbsoluteSize'):Connect(position) else nil
    label.Destroying:Connect(function() positionChanged:Disconnect(); if resized then resized:Disconnect() end end)
    position(); celebrateCharacter(character)
    TweenService:Create(scale,TweenInfo.new(.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    TweenService:Create(rise,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Value=23}):Play()
    task.delay(1.15,function()
        if not label.Parent then return end
        TweenService:Create(label,TweenInfo.new(.65),{TextTransparency=1}):Play()
        TweenService:Create(outline,TweenInfo.new(.65),{Transparency=1}):Play()
    end)
    Debris:AddItem(label,1.85)
end
return CashEffects
