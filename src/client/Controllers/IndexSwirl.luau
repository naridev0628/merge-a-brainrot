--!strict
-- Small native GUI spiral. One fixed set per card, animated only while visible.
local Swirl={}
function Swirl.new(parent: GuiObject,color: Color3): Frame
    local root=Instance.new('Frame');root.Name='CharacterSwirl';root.AnchorPoint=Vector2.new(.5,.5)
    root.Position=UDim2.fromScale(.5,.43);root.Size=UDim2.fromScale(1.16,1.16)
    root.BackgroundTransparency=1;root.ZIndex=1;root.Parent=parent
    local square=Instance.new('UIAspectRatioConstraint');square.AspectRatio=1;square.Parent=root
    for ray=0,7 do
        for segment=1,3 do
            local a=(segment-1)/3;local b=segment/3
            local angleA=ray*math.pi/4+a*.55;local angleB=ray*math.pi/4+b*.55
            local start=Vector2.new(math.cos(angleA),math.sin(angleA))*(.06+.49*a)
            local finish=Vector2.new(math.cos(angleB),math.sin(angleB))*(.06+.49*b)
            local delta=finish-start
            local spoke=Instance.new('Frame');spoke.Name='Ray';spoke.BorderSizePixel=0;spoke.AnchorPoint=Vector2.new(.5,.5)
            spoke.Position=UDim2.fromScale(.5+(start.X+finish.X)/2,.5+(start.Y+finish.Y)/2)
            spoke.Size=UDim2.fromScale(delta.Magnitude+.012,.018+segment*.012)
            spoke.Rotation=math.deg(math.atan2(delta.Y,delta.X))
            spoke.BackgroundColor3=color;spoke.BackgroundTransparency=.79+segment*.045
            spoke.ZIndex=1;spoke.Parent=root
        end
    end
    return root
end
return table.freeze(Swirl)
