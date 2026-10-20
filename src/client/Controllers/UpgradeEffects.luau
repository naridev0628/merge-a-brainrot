--!strict
local TweenService=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local Map=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('MapSpec'))
local Effects={}
function Effects.play(plotFrame: CFrame)
    local old=workspace:FindFirstChild('ProcessorUpgradeEffect');if old then old:Destroy() end
    local burst=Instance.new('Model');burst.Name='ProcessorUpgradeEffect';burst.Parent=workspace;Debris:AddItem(burst,1.5)
    local center=plotFrame:PointToWorldSpace(Map.Upgrade*Map.PlotScale)+Vector3.new(0,.25,0)
    for i=1,12 do
        local angle=i*math.pi/6
        local chip=Instance.new('Part');chip.Name='UpgradeSpark';chip.Size=Vector3.new(.24,.24,.24)
        chip.Anchored=true;chip.CanCollide=false;chip.CanTouch=false;chip.CanQuery=false
        chip.Material=Enum.Material.Neon;chip.Color=if i%2==0 then Color3.fromRGB(122,255,72) else Color3.fromRGB(255,233,106)
        chip.CFrame=CFrame.new(center+Vector3.new(math.cos(angle)*.5,0,math.sin(angle)*.5));chip.Parent=burst
        TweenService:Create(chip,TweenInfo.new(.85,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
            CFrame=CFrame.new(center+Vector3.new(math.cos(angle)*3,1.4+i%3*.4,math.sin(angle)*3))*CFrame.Angles(i*.3,i,0),
            Transparency=1,Size=Vector3.new(.06,.06,.06),
        }):Play()
    end
    local anchor=Instance.new('Part');anchor.Name='FeedbackAnchor';anchor.Size=Vector3.one;anchor.Transparency=1
    anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Position=center+Vector3.new(0,2.2,0);anchor.Parent=burst
    local labelGui=Instance.new('BillboardGui');labelGui.Name='UpgradeFeedback';labelGui.Size=UDim2.fromOffset(260,70);labelGui.AlwaysOnTop=true;labelGui.Parent=anchor
    local text=Instance.new('TextLabel');text.BackgroundTransparency=1;text.Size=UDim2.fromScale(1,1)
    text.Font=Enum.Font.FredokaOne;text.Text='↑ Processor upgraded!';text.TextSize=25;text.TextColor3=Color3.fromRGB(185,255,85)
    text.TextStrokeColor3=Color3.fromRGB(27,52,9);text.TextStrokeTransparency=0;text.Parent=labelGui
    local size=Instance.new('UIScale');size.Scale=.6;size.Parent=text
    TweenService:Create(size,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    TweenService:Create(anchor,TweenInfo.new(1.3),{Position=anchor.Position+Vector3.new(0,2.5,0)}):Play()
    task.delay(.75,function()
        if text.Parent then TweenService:Create(text,TweenInfo.new(.55),{TextTransparency=1,TextStrokeTransparency=1}):Play() end
    end)
end
return Effects
