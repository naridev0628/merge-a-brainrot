--!strict
local Art=require(script.Parent:WaitForChild('BrickArt'))
local TweenService=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local Catalog=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('CreatureCatalog'))
local Style=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('TextStyle'))
local Effects={}
function Effects.play(gui: ScreenGui,count: number,speciesId: string)
    if not gui.Parent or not Catalog[speciesId] then return end
    local previous=gui:FindFirstChild('PurchaseCelebration');if previous then previous:Destroy() end
    local layer=Instance.new('Frame');layer.Name='PurchaseCelebration';layer.Size=UDim2.fromScale(1,1);layer.BackgroundTransparency=1;layer.ZIndex=30;layer.Parent=gui
    Debris:AddItem(layer,2.2)
    local random=Random.new()
    for index=1,math.min(count,4) do
        local portrait=Art.portrait(layer,speciesId,UDim2.fromScale(.5,.65),UDim2.fromOffset(88,100),true)
        portrait.AnchorPoint=Vector2.new(.5,.5);portrait.ZIndex=30;portrait.Rotation=random:NextNumber(-15,15)
        task.delay((index-1)*.07,function()
            if not portrait.Parent then return end
            TweenService:Create(portrait,TweenInfo.new(.65,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5+random:NextNumber(-.18,.18),.32+random:NextNumber(-.04,.05)),Rotation=random:NextNumber(-25,25)}):Play()
            task.delay(.9,function()if portrait.Parent then TweenService:Create(portrait,TweenInfo.new(.6),{Position=portrait.Position-UDim2.fromScale(0,.12),ImageTransparency=1}):Play() end end)
        end)
    end
    local label=Instance.new('TextLabel');label.Name='PurchaseText';label.BackgroundTransparency=1;label.AnchorPoint=Vector2.new(.5,.5);label.Position=UDim2.fromScale(.5,.54);label.Size=UDim2.new(.8,0,0,48);label.Font=Enum.Font.FredokaOne;label.TextSize=32;label.TextScaled=true;label.Text='+ '..count..' '..Catalog[speciesId].name..'!';label.TextColor3=Color3.fromRGB(166,255,76);label.TextStrokeTransparency=0;label.ZIndex=31;label.Parent=layer
    local max=Instance.new('UITextSizeConstraint');max.MaxTextSize=32;max.MinTextSize=18;max.Parent=label
    Style.apply(label,32,Style.Price,3)
    local gradient=Instance.new('UIGradient');gradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(79,193,18));gradient.Rotation=90;gradient.Parent=label
    task.delay(1.4,function()if label.Parent then TweenService:Create(label,TweenInfo.new(.6),{TextTransparency=1}):Play();TweenService:Create(label.TextOutline,TweenInfo.new(.6),{Transparency=1}):Play() end end)
end
return Effects
