--!strict
local TweenService=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local ContentProvider=game:GetService('ContentProvider')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Factory=require(Shared:WaitForChild('ModelFactory'))
local Style=require(Shared:WaitForChild('TextStyle'))
local Effects={}
function Effects.play(gui: ScreenGui,character: Model?,miniSpecies: {string})
    if #miniSpecies==0 or not gui.Parent then return end
    local previous=gui:FindFirstChild('DepositCelebration')
    if previous then previous:Destroy() end
    -- One short flight per deposit, bounded even while assets preload.
    local layer=Instance.new('Frame');layer.Name='DepositCelebration';layer.BackgroundTransparency=1;layer.Size=UDim2.fromScale(1,1);layer.ZIndex=30;layer.ClipsDescendants=true;layer.Parent=gui
    Debris:AddItem(layer,1.9)
    local area=layer.AbsoluteSize
    local source=Vector2.new(area.X*.5,area.Y-60)
    local bag=gui:FindFirstChild('MiniBag',true)
    if bag and bag:IsA('GuiObject') then source=bag.AbsolutePosition+bag.AbsoluteSize*.5-layer.AbsolutePosition end
    local target=Vector2.new(area.X*.5,area.Y*.55)
    local root=character and character:FindFirstChild('HumanoidRootPart')
    local camera=workspace.CurrentCamera
    if root and root:IsA('BasePart') and camera then
        local point,visible=camera:WorldToScreenPoint(root.Position+Vector3.new(0,1,0))
        if visible then target=Vector2.new(point.X,point.Y)-layer.AbsolutePosition end
    end
    target=Vector2.new(math.clamp(target.X,40,math.max(40,area.X-40)),math.clamp(target.Y,60,math.max(60,area.Y-100)))
    local flights={}
    -- Actual deposited species, sampled across the bag; never substitute a high tier.
    local count=math.min(#miniSpecies,if area.X<600 then 4 else 6)
    for index=1,count do
        local species=Catalog[miniSpecies[math.ceil(index*#miniSpecies/count)]]
        if not species then continue end
        local viewport=Instance.new('ViewportFrame');viewport.Name='FlyingMini';viewport.BackgroundTransparency=1;viewport.ZIndex=31;viewport.Visible=false
        viewport.Size=UDim2.fromOffset(66,76);viewport.AnchorPoint=Vector2.new(.5,.5);viewport.Position=UDim2.fromOffset(source.X,source.Y);viewport.Parent=layer
        local world=Instance.new('WorldModel');world.Parent=viewport
        local model=Factory.producer(world,'DepositedMini',species,Vector3.zero,true)
        local cf,extent=model:GetBoundingBox()
        local portraitCamera=Instance.new('Camera');portraitCamera.FieldOfView=35;portraitCamera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,0,-math.max(extent.X,extent.Y,extent.Z)*1.9),cf.Position);portraitCamera.Parent=viewport;viewport.CurrentCamera=portraitCamera
        viewport.Ambient=Color3.fromRGB(240,232,210);viewport.LightColor=Color3.new(1,1,1)
        table.insert(flights,viewport)
    end
    task.spawn(function()
        pcall(function() ContentProvider:PreloadAsync(layer:GetDescendants()) end)
        if not layer.Parent then return end
        for index,viewport in flights do
            task.delay((index-1)*.06,function()
                if not viewport.Parent then return end
                viewport.Visible=true
                local spread=(index-(#flights+1)/2)*24
                local middle=(source+target)*.5+Vector2.new(spread,-65)
                TweenService:Create(viewport,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(middle.X,middle.Y),Rotation=spread*.35}):Play()
                task.delay(.32,function()
                    if not viewport.Parent then return end
                    TweenService:Create(viewport,TweenInfo.new(.38,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromOffset(target.X,target.Y),Size=UDim2.fromOffset(22,26),ImageTransparency=1,Rotation=0}):Play()
                end)
            end)
        end
        -- Gold deposit pulse remains distinct from green collection cash.
        task.delay(.5,function()
            if not layer.Parent then return end
            local glow=Instance.new('Frame');glow.Name='DepositPulse';glow.AnchorPoint=Vector2.new(.5,.5);glow.Position=UDim2.fromOffset(target.X,target.Y);glow.Size=UDim2.fromOffset(34,34);glow.BackgroundColor3=Style.Gold;glow.BackgroundTransparency=.7;glow.BorderSizePixel=0;glow.ZIndex=30;glow.Parent=layer
            local round=Instance.new('UICorner');round.CornerRadius=UDim.new(1,0);round.Parent=glow
            local ring=Instance.new('UIStroke');ring.Color=Style.Gold;ring.Thickness=3;ring.Parent=glow
            TweenService:Create(glow,TweenInfo.new(.65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(120,120),BackgroundTransparency=1}):Play()
            TweenService:Create(ring,TweenInfo.new(.65),{Transparency=1}):Play()
        end)
    end)
end
return Effects
