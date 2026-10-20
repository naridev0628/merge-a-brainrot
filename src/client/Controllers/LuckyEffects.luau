--!strict
local Art=require(script.Parent:WaitForChild('BrickArt'))
local Runtime=require(script.Parent:WaitForChild('VisualRuntime'))
local Style=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('TextStyle'))
local Appearance=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('LuckyAppearance'))
local Lucky={}
function Lucky.play(gui: ScreenGui,onReveal: ()->(),baseTier: number?)
    -- Completion owns the caller's animation lock, including cancellation and
    -- visual errors. No yielding asset request sits on this completion path.
    local sequence=Runtime.new(gui,function() onReveal() end)
    local appearance=Appearance.forTier(baseTier)
    sequence:run(function()
        local holder=Instance.new('Frame')
        holder.Name='LuckyOpening';holder.AnchorPoint=Vector2.new(.5,.5);holder.Size=UDim2.fromOffset(240,240)
        holder.Position=UDim2.fromScale(.5,-.3);holder.BackgroundTransparency=1;holder.ZIndex=40;holder.Visible=false;holder.Parent=gui
        sequence:own(function() holder:Destroy() end)
        Runtime.watch(sequence,holder)
        local viewport=Art.luckyPortrait(holder,UDim2.fromScale(0,0),UDim2.fromScale(1,1),true,baseTier)
        viewport.ZIndex=41
        Runtime.load(sequence,viewport:GetDescendants(),function(loaded)
            if not holder.Parent or not gui.Parent then sequence:finish('cancelled');return end
            viewport.Visible=loaded
            if not loaded then
                local fallback=Instance.new('TextLabel');fallback.Name='LuckyFallback'
                fallback.AnchorPoint=Vector2.new(.5,.5);fallback.Position=UDim2.fromScale(.5,.5);fallback.Size=UDim2.fromScale(.62,.62)
                fallback.BackgroundColor3=Color3.fromRGB(table.unpack(appearance.body));fallback.BorderSizePixel=0;fallback.Text='?';fallback.TextScaled=true;fallback.ZIndex=41
                Style.apply(fallback,112,Color3.fromRGB(table.unpack(appearance.mark)),3);fallback.Parent=holder
                local outline=Instance.new('UIStroke');outline.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
                outline.Thickness=3;outline.Color=Style.Ink;outline.Parent=fallback
            end
            holder.Visible=true
            Runtime.tween(sequence,holder,TweenInfo.new(.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,.5)})
            local shake: (number)->()
            shake=function(index)
                if index>12 then
                    Runtime.tween(sequence,holder,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.fromOffset(0,0),Rotation=0})
                    sequence:after(.2,function() sequence:finish('complete') end)
                    return
                end
                local angle=(if index%2==0 then 1 else -1)*(6+index*.7)
                Runtime.tween(sequence,holder,TweenInfo.new(.12,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Rotation=angle})
                sequence:after(.12,function() shake(index+1) end)
            end
            sequence:after(.35,function() shake(1) end)
        end)
    end)
end
return Lucky
