--!strict
local Factory={}
local cream=Color3.fromRGB(255,244,220)
local navy=Color3.fromRGB(24,50,63)
function Factory.part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, collide: boolean?): Part
    local p=Instance.new("Part")
    p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
    p.Shape=shape or Enum.PartType.Block; p.Material=Enum.Material.SmoothPlastic
    p.Anchored=true; p.CanCollide=collide==true; p.CanTouch=false
    p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end
function Factory.label(part: BasePart, text: string, width: number?, height: number?)
    local gui=Instance.new("BillboardGui")
    gui.Name="Label"; gui.Size=UDim2.fromOffset(width or 180,height or 50)
    gui.StudsOffset=Vector3.new(0,2.6,0); gui.MaxDistance=90
    gui.AlwaysOnTop=false; gui.Parent=part
    local label=Instance.new("TextLabel")
    label.Name="Text"; label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1
    label.Text=text; label.TextColor3=navy; label.TextStrokeColor3=cream; label.TextStrokeTransparency=0.3
    label.Font=Enum.Font.GothamBold; label.TextSize=16; label.TextWrapped=true; label.Parent=gui
    return label
end
function Factory.producer(parent: Instance, id: string, species: any, position: Vector3): Model
    local model=Instance.new("Model"); model.Name=id
    local color=Color3.fromRGB(table.unpack(species.color))
    local function part(name,size,offset,col,shape)
        return Factory.part(model,name,size,CFrame.new(position+offset),col,shape)
    end
    local body: Part
    if species.tier==1 then
        body=part("Planter",Vector3.new(2.7,2,2.7),Vector3.new(0,1.2,0),Color3.fromRGB(216,148,108),Enum.PartType.Cylinder)
        body.CFrame*=CFrame.Angles(0,0,math.pi/2)
        part("Stem",Vector3.new(0.35,2,0.35),Vector3.new(0,3,0),color)
        part("Spoon",Vector3.new(1.6,2,0.45),Vector3.new(0,4,0),cream,Enum.PartType.Ball)
        for _,side in {-1,1} do
            local leaf=part("Leaf",Vector3.new(1.8,0.45,0.9),Vector3.new(side*1.15,2.8,0),color,Enum.PartType.Ball)
            leaf.CFrame*=CFrame.Angles(0,0,side*0.45)
        end
    elseif species.tier==2 then
        body=part("Waffle",Vector3.new(3.2,3.2,1.2),Vector3.new(0,2.5,0),color)
        for _,v in {-0.85,0,0.85} do
            part("WaffleLine",Vector3.new(0.13,2.8,0.12),Vector3.new(v,2.5,-0.66),Color3.fromRGB(186,123,44))
            part("WaffleLine",Vector3.new(2.8,0.13,0.12),Vector3.new(0,2.5+v,-0.66),Color3.fromRGB(186,123,44))
        end
        for _,side in {-1,1} do part("Roller",Vector3.new(1.4,0.9,1.6),Vector3.new(side*0.95,0.65,0),Color3.fromRGB(140,115,205),Enum.PartType.Ball) end
    else
        body=part("Bubble",Vector3.new(3.1,3.1,3.1),Vector3.new(0,2.7,0),color,Enum.PartType.Ball)
        part("BubbleSmall",Vector3.new(1.4,1.4,1.4),Vector3.new(-1.3,4,0.4),Color3.fromRGB(180,226,249),Enum.PartType.Ball)
        part("BubbleTiny",Vector3.new(0.9,0.9,0.9),Vector3.new(1.3,3.8,0.2),cream,Enum.PartType.Ball)
        for _,side in {-1,1} do part("Boot",Vector3.new(1.35,1.3,2.3),Vector3.new(side*0.85,0.8,-0.35),Color3.fromRGB(247,185,67)) end
    end
    for _,side in {-1,1} do
        part("Eye",Vector3.new(0.24,0.38,0.2),Vector3.new(side*0.5,2.7,-(if species.tier==3 then 1.48 else 0.79)),navy,Enum.PartType.Ball)
    end
    model.PrimaryPart=body
    Factory.label(body,"T"..species.tier.." · "..species.name.."\n"..species.value.." Coins / Mini",200,50)
    model.Parent=parent
    return model
end
function Factory.mini(parent: Instance, token: any, species: any): Part
    local p=Factory.part(parent,token.id,Vector3.new(1.15,1.5,1.15),CFrame.new(token.x,token.y,token.z),Color3.fromRGB(table.unpack(species.color)),Enum.PartType.Ball)
    p.Material=Enum.Material.Neon
    p:SetAttribute("OwnerUserId",token.owner)
    return p
end
return Factory
