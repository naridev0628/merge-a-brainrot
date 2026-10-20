--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Catalog=require(Shared:WaitForChild('CreatureCatalog'))
local Factory=require(Shared:WaitForChild('ModelFactory'))
local TweenService=game:GetService('TweenService')
local RunService=game:GetService('RunService')
local ContentProvider=game:GetService('ContentProvider')
local Discovery={}
function Discovery.new(gui: ScreenGui)
    local queue={}; local running=false
    return function(speciesId: string,_isNew: boolean?)
        if not Catalog[speciesId] then return end
        table.insert(queue,{id=speciesId})
        if running then return end
        running=true
        task.spawn(function()
            while #queue>0 do
                local item=table.remove(queue,1); local species=Catalog[item.id]
                if not gui.Parent then table.clear(queue); break end
                local card=Instance.new('Frame'); card.Name='NewDiscovery'; card.Size=UDim2.fromOffset(340,232); card.AnchorPoint=Vector2.new(.5,.5); card.Position=UDim2.fromScale(.5,.50); card.BackgroundTransparency=1; card.ZIndex=35; card.Visible=false; card.Parent=gui
                local scale=Instance.new('UIScale'); scale.Scale=.6; scale.Parent=card
                local burst=Instance.new('Frame'); burst.Name='SpiralShadows'; burst.AnchorPoint=Vector2.new(.5,.5); burst.Position=UDim2.new(.5,0,0,88); burst.Size=UDim2.fromOffset(320,320); burst.BackgroundTransparency=1; burst.ZIndex=34; burst.Parent=card
                -- Tapered, translucent rays rotate independently of the portrait.
                for ray=1,10 do
                    local arm=Instance.new('Frame'); arm.Size=UDim2.fromScale(1,1); arm.BackgroundTransparency=1; arm.Rotation=ray*36; arm.Parent=burst
                    for segment=1,10 do
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
                name.Font=Enum.Font.FredokaOne; name.TextSize=34; name.TextScaled=true; name.TextWrapped=true; name.Position=UDim2.fromOffset(0,166); name.Size=UDim2.new(1,0,0,60); name.ZIndex=36; name.Parent=card
                local nameSize=Instance.new('UITextSizeConstraint'); nameSize.MinTextSize=22; nameSize.MaxTextSize=34; nameSize.Parent=name
                local nameOutline=Instance.new('UIStroke'); nameOutline.Name='NameOutline'; nameOutline.Color=Color3.fromRGB(10,8,6); nameOutline.Thickness=3; nameOutline.Parent=name
                pcall(function() ContentProvider:PreloadAsync(model:GetDescendants()) end)
                if not card.Parent or not gui.Parent then card:Destroy(); table.clear(queue); break end
                card.Visible=true
                local rotation=RunService.RenderStepped:Connect(function(dt) if burst.Parent then burst.Rotation+=dt*18 end end)
                TweenService:Create(scale,TweenInfo.new(.25,Enum.EasingStyle.Back),{Scale=1}):Play()
                task.wait(2.75)
                TweenService:Create(scale,TweenInfo.new(.25),{Scale=0}):Play(); task.wait(.25); rotation:Disconnect(); card:Destroy()
            end
            running=false
        end)
    end
end
return Discovery
