--!strict
local TweenService=game:GetService('TweenService')
local ContentProvider=game:GetService('ContentProvider')
local Art=require(script.Parent:WaitForChild('BrickArt'))
local Lucky={}
function Lucky.play(gui: ScreenGui,onReveal: ()->())
    task.spawn(function()
        local box: Frame?=nil
        -- A single completion path releases the caller's animation lock even if
        -- the UI disappears or a visual asset cannot be rendered.
        local ok,err=xpcall(function()
            if not gui.Parent then return end
            local holder=Instance.new('Frame'); box=holder
            holder.Name='LuckyOpening'; holder.AnchorPoint=Vector2.new(.5,.5); holder.Size=UDim2.fromOffset(240,240); holder.Position=UDim2.fromScale(.5,-.3); holder.BackgroundTransparency=1; holder.ZIndex=40; holder.Visible=false; holder.Parent=gui
            local viewport=Art.luckyPortrait(holder,UDim2.fromScale(0,0),UDim2.fromScale(1,1)); viewport.ZIndex=41
            pcall(function() ContentProvider:PreloadAsync(viewport:GetDescendants()) end)
            if not holder.Parent or not gui.Parent then return end
            viewport.Visible=true; holder.Visible=true
            TweenService:Create(holder,TweenInfo.new(.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,.5)}):Play()
            task.wait(.35)
            for index=1,12 do
                if not holder.Parent then return end
                local angle=(if index%2==0 then 1 else -1)*(6+index*.7)
                TweenService:Create(holder,TweenInfo.new(.12,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Rotation=angle}):Play()
                task.wait(.12)
            end
            if not holder.Parent then return end
            TweenService:Create(holder,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.fromOffset(0,0),Rotation=0}):Play()
            task.wait(.2)
        end,debug.traceback)
        if box then box:Destroy() end
        if not ok then warn('Lucky opening visual: '..tostring(err)) end
        onReveal()
    end)
end
return Lucky
