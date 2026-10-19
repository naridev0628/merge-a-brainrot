--!strict
local TweenService=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local ContentProvider=game:GetService('ContentProvider')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Factory=require(Shared:WaitForChild('ModelFactory'))
local Effects={}
function Effects.play(gui: ScreenGui,character: Model?,miniSpecies: {string})
    if #miniSpecies==0 then return end
    -- Capture actual bag contents, not the highest discovered character.
    local captured=table.clone(miniSpecies)
    task.spawn(function()
        if not gui.Parent then return end
        local random=Random.new()
        for index=#captured,2,-1 do local other=random:NextInteger(1,index); captured[index],captured[other]=captured[other],captured[index] end
        local layer=Instance.new('Frame'); layer.Name='DepositCelebration'; layer.BackgroundTransparency=1; layer.Size=UDim2.fromScale(1,1); layer.ZIndex=30; layer.ClipsDescendants=true; layer.Visible=false; layer.Parent=gui
        local drops=math.min(#captured,if layer.AbsoluteSize.X<600 then 10 else 18)
        local falling={}
        for index=1,drops do
            local species=Catalog[captured[index]]
            if not species then continue end
            local viewport=Instance.new('ViewportFrame'); viewport.Name='FallingMini'; viewport.BackgroundTransparency=1; viewport.ZIndex=30; viewport.Visible=false
            local size=random:NextNumber(58,86); viewport.Size=UDim2.fromOffset(size,size*1.15)
            local x=random:NextNumber(.06,.94)
            viewport.AnchorPoint=Vector2.new(.5,.5); viewport.Position=UDim2.fromScale(x,random:NextNumber(-.26,-.12)); viewport.Rotation=random:NextNumber(-28,28); viewport.Parent=layer
            local world=Instance.new('WorldModel'); world.Parent=viewport
            local model=Factory.producer(world,'CelebrationBrainrot',species,Vector3.zero,true)
            local cf,extent=model:GetBoundingBox()
            local camera=Instance.new('Camera'); camera.FieldOfView=35; camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,0,-math.max(extent.X,extent.Y,extent.Z)*1.9),cf.Position); camera.Parent=viewport; viewport.CurrentCamera=camera
            viewport.Ambient=Color3.fromRGB(230,230,230); viewport.LightColor=Color3.new(1,1,1)
            table.insert(falling,{viewport=viewport,x=x,delay=random:NextNumber(0,.85),duration=random:NextNumber(1.25,1.6)})
        end
        pcall(function() ContentProvider:PreloadAsync(layer:GetDescendants()) end)
        if not layer.Parent or not gui.Parent then layer:Destroy(); return end
        layer.Visible=true; Debris:AddItem(layer,2.5)
        for _,drop in falling do
            task.delay(drop.delay,function()
                local viewport=drop.viewport
                if not viewport.Parent then return end
                viewport.Visible=true
                TweenService:Create(viewport,TweenInfo.new(drop.duration,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromScale(math.clamp(drop.x+random:NextNumber(-.12,.12),-.1,1.1),1.2),Rotation=viewport.Rotation+random:NextNumber(-100,100)}):Play()
            end)
        end
        local root=character and character:FindFirstChild('HumanoidRootPart')
        if #captured>=10 and root and root:IsA('BasePart') then
            for index=1,24 do
                local angle=random:NextNumber(0,math.pi*2)
                local confetti=Instance.new('Part'); confetti.Name='DepositConfetti'; confetti.Size=Vector3.new(.22,.06,.4); confetti.Anchored=true; confetti.CanCollide=false; confetti.CanTouch=false; confetti.CanQuery=false; confetti.CastShadow=false
                confetti.Color=Color3.fromHSV(index/24,.8,1); confetti.CFrame=root.CFrame; confetti.Parent=workspace
                local radius=random:NextNumber(2.5,5)
                local finish=CFrame.new(root.Position+Vector3.new(math.cos(angle)*radius,random:NextNumber(1,4),math.sin(angle)*radius))*CFrame.Angles(angle,angle,angle)
                TweenService:Create(confetti,TweenInfo.new(random:NextNumber(1.3,2.4),Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=finish,Transparency=1}):Play(); Debris:AddItem(confetti,2.5)
            end
        end
    end)
end
return Effects
