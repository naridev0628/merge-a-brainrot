--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Factory=require(Shared:WaitForChild('ModelFactory'))
local Style=require(Shared:WaitForChild('TextStyle'))
local RunService=game:GetService('RunService')
local Runtime=require(script.Parent:WaitForChild('VisualRuntime'))
local Queue=require(script.Parent:WaitForChild('VisualQueue'))
local Discovery={}
function Discovery.new(gui: ScreenGui)
    local queue=Queue.new(6)
    local current: any=nil
    local lifetime=Runtime.new(gui,function() queue:clear() end)
    lifetime:own(function() if current then current:finish('cancelled') end end)
    local pump: ()->()
    pump=function()
        if current or not lifetime:alive() then return end
        local id=queue:take()
        if not id then return end
        local species=Catalog[id]
        local sequence=Runtime.new(gui,function()
            current=nil;queue:complete(id)
            if lifetime:alive() then lifetime:after(0,pump) end
        end)
        current=sequence
        sequence:run(function()
                local card=Instance.new('Frame'); card.Name='NewDiscovery'; card.Size=UDim2.new(.8,0,0,218); card.AnchorPoint=Vector2.new(.5,.5); card.Position=UDim2.fromScale(.5,.48); card.BackgroundTransparency=1; card.ZIndex=35; card.Visible=false; card.Parent=gui
                sequence:own(function() card:Destroy() end)
                Runtime.watch(sequence,card)
                local cardSize=Instance.new('UISizeConstraint');cardSize.MaxSize=Vector2.new(300,218);cardSize.Parent=card
                local scale=Instance.new('UIScale'); scale.Scale=.6; scale.Parent=card
                local burst=Instance.new('Frame'); burst.Name='SpiralShadows'; burst.AnchorPoint=Vector2.new(.5,.5); burst.Position=UDim2.new(.5,0,0,78); burst.Size=UDim2.fromOffset(260,260); burst.BackgroundTransparency=1; burst.ZIndex=34; burst.Parent=card
                -- Tapered, translucent rays rotate independently of the portrait.
                for ray=1,8 do
                    local arm=Instance.new('Frame'); arm.Size=UDim2.fromScale(1,1); arm.BackgroundTransparency=1; arm.Rotation=ray*45; arm.Parent=burst
                    for segment=1,6 do
                        local piece=Instance.new('Frame'); piece.BorderSizePixel=0; piece.BackgroundColor3=Color3.fromRGB(20,30,20); piece.BackgroundTransparency=.72+segment*.018; piece.AnchorPoint=Vector2.new(.5,1)
                        piece.Size=UDim2.fromOffset(3+segment*3.4,14); piece.Position=UDim2.new(.5,segment*.75,.5,-segment*13); piece.Rotation=segment*.7; piece.Parent=arm
                    end
                end
                local viewport=Instance.new('ViewportFrame'); viewport.Name='BrainrotPortrait'; viewport.Size=UDim2.new(1,0,0,165); viewport.BackgroundTransparency=1; viewport.ZIndex=35; viewport.Parent=card
                local world=Instance.new('WorldModel'); world.Parent=viewport
                local model=Factory.producer(world,'DiscoveredBrainrot',species,Vector3.zero,false)
                for _,v in model:GetDescendants() do if v:IsA('BillboardGui') then v:Destroy() end end
                local cf,extent=model:GetBoundingBox()
                local camera=Instance.new('Camera'); camera.FieldOfView=35; camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(extent.X*.2,extent.Y*.08,-math.max(extent.X,extent.Y,extent.Z)*1.9),cf.Position); camera.Parent=viewport; viewport.CurrentCamera=camera
                viewport.Ambient=Color3.fromRGB(220,220,220)
                local name=Instance.new('TextLabel'); name.Name='CreatureName'; name.BackgroundTransparency=1; name.Text=species.name; name.TextColor3=Color3.fromRGB(table.unpack(species.color)); name.TextStrokeTransparency=1
                name.Font=Enum.Font.FredokaOne; name.TextSize=34; name.TextScaled=true; name.TextWrapped=true; name.Position=UDim2.fromOffset(0,166); name.Size=UDim2.new(1,0,0,52); name.ZIndex=36; name.Parent=card
                local nameSize=Instance.new('UITextSizeConstraint'); nameSize.MinTextSize=22; nameSize.MaxTextSize=34; nameSize.Parent=name
                Style.apply(name,32,Color3.fromRGB(table.unpack(species.color)),3)
                Runtime.load(sequence,model:GetDescendants(),function(loaded)
                    if not card.Parent or not gui.Parent then sequence:finish('cancelled');return end
                    -- Keep the name/burst readable even when the mesh is unavailable.
                    viewport.Visible=loaded;card.Visible=true
                    local rotation=RunService.RenderStepped:Connect(function(dt) if burst.Parent then burst.Rotation+=dt*18 end end)
                    sequence:own(function() rotation:Disconnect() end)
                    Runtime.tween(sequence,scale,TweenInfo.new(.25,Enum.EasingStyle.Back),{Scale=1})
                    sequence:after(2.75,function()
                        Runtime.tween(sequence,scale,TweenInfo.new(.25),{Scale=0})
                        sequence:after(.25,function() sequence:finish('complete') end)
                    end)
                end)
        end)
    end
    return function(speciesId: string,_isNew: boolean?)
        if not lifetime:alive() or not Catalog[speciesId] or not queue:push(speciesId) then return end
        pump()
    end
end
return Discovery
