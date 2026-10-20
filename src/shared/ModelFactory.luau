--!strict
-- Original Blender meshes with procedural fallbacks; no embedded third-party scripts.
local Factory={}
local cream=Color3.fromRGB(255,241,209)
local dark=Color3.fromRGB(39,27,22)
Factory.expansionKeys={
    'Fluriflura','GorilloSubwoofero','LiriliLarila','NoobiniPizzanini',
    'OdinDinDinDun','PipiPotato','RaccooniJandelini','TalpaDiFero',
    'TimCheese','ToilettoFocaccino','TukannoBananno',
}
-- Expansion Minis are already exported at two studs tall; do not apply the legacy .42 scale.
function Factory.expansion(parent: Instance,key: string,cf: CFrame,mini: boolean?): MeshPart
    local templates=game:GetService('ReplicatedStorage'):WaitForChild('ExpansionModels')
    local template=templates:FindFirstChild(key..(if mini then '_Mini' else ''))
    assert(template and template:IsA('MeshPart'),'Missing imported expansion character: '..key)
    local mesh=template:Clone()
    mesh.Name=if mini then 'CrateMini' else key
    mesh:SetAttribute('CharacterKey',key)
    mesh.CFrame=cf*CFrame.new(0,mesh.Size.Y/2,0)
    mesh.Anchored=true;mesh.CanCollide=false;mesh.CanTouch=false;mesh.CanQuery=false
    mesh.Parent=parent
    return mesh
end
function Factory.prop(parent: Instance,name: string,cf: CFrame,scale: number?): MeshPart?
    local templates=game:GetService('ReplicatedStorage'):FindFirstChild('MapModels')
    local template=templates and templates:FindFirstChild(name)
    if not template or not template:IsA('MeshPart') then return nil end
    local mesh=template:Clone(); mesh.Size*=scale or 1; mesh.CFrame=cf*CFrame.new(0,mesh.Size.Y/2,0)
    mesh.Anchored=true; mesh.CanCollide=false; mesh.CanTouch=false; mesh.Parent=parent
    if name=='BrickTree' then
        local s=scale or 1
        local trunk=Factory.part(parent,'TreeTrunkCollider',Vector3.new(2,6,2)*s,cf*CFrame.new(0,3*s,0),Color3.fromRGB(101,65,37),nil,true);trunk.Transparency=1
        for _,side in {-1,1} do
            local root=Factory.part(parent,'TreeRoot',Vector3.new(3,.5,.8)*s,cf*CFrame.new(side*1.2*s,.25*s,0)*CFrame.Angles(0,side*.4,0),Color3.fromRGB(105,66,36),nil,true);root.TopSurface=Enum.SurfaceType.Studs
            local branch=Factory.part(parent,'TreeBranch',Vector3.new(3,.65,.65)*s,cf*CFrame.new(side*1.5*s,4.4*s,0)*CFrame.Angles(0,side*.4,side*.35),Color3.fromRGB(105,66,36),nil,true);branch.TopSurface=Enum.SurfaceType.Studs
        end
    end
    return mesh
end
function Factory.part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,shape: Enum.PartType?,collide: boolean?): Part
    local p=Instance.new('Part'); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
    p.Shape=shape or Enum.PartType.Block; p.Material=Enum.Material.Plastic
    p.Anchored=true; p.CanCollide=collide==true; p.CanTouch=false
    p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent
    return p
end
function Factory.label(part: BasePart,value: string,width: number?,height: number?)
    local gui=Instance.new('BillboardGui'); gui.Name='Label'; gui.Size=UDim2.fromOffset(width or 170,height or 48)
    gui.StudsOffset=Vector3.new(0,3.2,0); gui.MaxDistance=65; gui.Parent=part
    local l=Instance.new('TextLabel'); l.Name='Text'; l.Size=UDim2.fromScale(1,1); l.BackgroundTransparency=1
    l.Text=value; l.TextColor3=Color3.new(1,1,1); l.TextStrokeColor3=Color3.new(0,0,0); l.TextStrokeTransparency=0
    l.Font=Enum.Font.FredokaOne; l.TextSize=18; l.TextWrapped=true; l.Parent=gui
    return l
end
function Factory.characterLabel(part: BasePart,species: any,offset: number)
    local gui=Instance.new('BillboardGui'); gui.Name='CharacterLabel'; gui.Size=UDim2.fromOffset(140,48); gui.StudsOffset=Vector3.new(0,offset-.7,0); gui.MaxDistance=32; gui.Parent=part
    local function line(name: string,value: string,y: number,height: number,fontSize: number,color: Color3)
        local label=Instance.new('TextLabel'); label.Name=name; label.Text=value; label.Position=UDim2.fromOffset(0,y); label.Size=UDim2.new(1,0,0,height); label.BackgroundTransparency=1; label.Font=Enum.Font.FredokaOne; label.TextSize=fontSize; label.TextColor3=color; label.TextStrokeTransparency=0; label.TextStrokeColor3=Color3.fromRGB(28,18,15); label.Parent=gui
    end
    line('Name',species.name,0,27,if #species.name>16 then 14 else 19,Color3.fromRGB(table.unpack(species.color)))
    line('Level','Level '..species.tier,26,19,14,Color3.fromRGB(255,244,222))
end
function Factory.producer(parent: Instance,id: string,species: any,position: Vector3,mini: boolean?): Model
    local m=Instance.new('Model'); m.Name=id
    local templates=game:GetService('ReplicatedStorage'):FindFirstChild('CharacterModels')
    local key=string.format('tier_%02d',species.tier)..(if mini then '_Mini' else '')
    local template=templates and templates:FindFirstChild(key)
    if template and template:IsA('MeshPart') then
        local mesh=template:Clone(); mesh.Name='Character'; mesh.Anchored=true; mesh.CanCollide=false; mesh.CanTouch=false
        mesh.Size*=if mini then .42 else 1
        mesh.CFrame=CFrame.new(position+Vector3.new(0,mesh.Size.Y/2,0))
        mesh.Parent=m; m.PrimaryPart=mesh; m:SetAttribute('BasePosition',position)
        if not mini then
            Factory.characterLabel(mesh,species,mesh.Size.Y/2+2)
        end
        m.Parent=parent; return m
    end
    local col=Color3.fromRGB(table.unpack(species.color))
    local function p(name: string,size: Vector3,offset: Vector3,color: Color3?,shape: Enum.PartType?)
        return Factory.part(m,name,size,CFrame.new(position+offset),color or col,shape)
    end
    local function ball(name: string,size: Vector3,offset: Vector3,color: Color3?) return p(name,size,offset,color,Enum.PartType.Ball) end
    local function cylinder(name: string,size: Vector3,offset: Vector3,color: Color3?)
        local a=p(name,size,offset,color,Enum.PartType.Cylinder); a.CFrame*=CFrame.Angles(0,0,math.pi/2); return a
    end
    local function face(y: number,z: number,spread: number)
        for _,side in {-1,1} do
            ball('EyeWhite',Vector3.new(.65,.75,.26),Vector3.new(side*spread,y,z),Color3.new(1,1,1))
            ball('Pupil',Vector3.new(.28,.38,.16),Vector3.new(side*spread,y,z-.16),dark)
        end
        p('Smile',Vector3.new(.65,.13,.16),Vector3.new(0,y-.6,z),dark)
    end
    local body: Part
    if species.tier==1 then
        body=cylinder('WoodenLog',Vector3.new(3.7,2.2,2.2),Vector3.new(0,3,0),col); body.Material=Enum.Material.Wood
        for _,side in {-1,1} do
            local arm=p('Arm',Vector3.new(.4,1.9,.4),Vector3.new(side*1.4,2.8,0),col); arm.CFrame*=CFrame.Angles(0,0,side*.18)
            p('Leg',Vector3.new(.42,1.1,.42),Vector3.new(side*.6,.9,0),col)
            ball('Foot',Vector3.new(.9,.5,1.35),Vector3.new(side*.6,.3,-.35),col)
        end
        local bat=cylinder('Bat',Vector3.new(3.7,.48,.48),Vector3.new(2,2,-.3),Color3.fromRGB(119,72,33)); bat.CFrame*=CFrame.Angles(0,0,-.22)
        face(3.5,-1.1,.48)
    elseif species.tier==2 then
        body=ball('BananaBody',Vector3.new(2.2,3.4,1.8),Vector3.new(0,2.4,0),col)
        local brown=Color3.fromRGB(102,66,38)
        ball('ChimpHead',Vector3.new(2.15,1.9,1.7),Vector3.new(0,4.1,-.15),brown)
        ball('Muzzle',Vector3.new(1.5,1.15,.65),Vector3.new(0,3.9,-.95),cream)
        for _,side in {-1,1} do
            ball('Ear',Vector3.new(.85,.9,.35),Vector3.new(side*1.1,4.1,-.1),cream)
            local peel=ball('BananaPeel',Vector3.new(.8,2.8,1),Vector3.new(side*1.1,1.7,0),col); peel.CFrame*=CFrame.Angles(0,0,side*.45)
            ball('Hand',Vector3.new(.7,.7,.7),Vector3.new(side*1.5,2.5,-.3),brown)
            ball('Foot',Vector3.new(.9,.6,1.25),Vector3.new(side*.65,.3,-.3),brown)
        end
        face(4.3,-1,.42)
    elseif species.tier==3 then
        body=cylinder('CoffeeCup',Vector3.new(1.8,2.4,2.4),Vector3.new(0,4.15,0),cream)
        cylinder('Coffee',Vector3.new(.1,2.05,2.05),Vector3.new(0,5.08,0),Color3.fromRGB(106,64,37))
        ball('FoamHeart',Vector3.new(1,.16,.9),Vector3.new(0,5.16,0),Color3.new(1,1,1))
        for _,o in {Vector3.new(1.5,4.7,0),Vector3.new(1.85,4.2,0),Vector3.new(1.5,3.7,0)} do ball('CupHandle',Vector3.new(.65,.65,.55),o,cream) end
        p('Bodice',Vector3.new(.9,1.3,.7),Vector3.new(0,2.6,0),col)
        ball('Tutu',Vector3.new(3,.65,2.7),Vector3.new(0,1.9,0),col)
        for _,side in {-1,1} do
            local arm=p('BalletArm',Vector3.new(1.35,.27,.3),Vector3.new(side*.95,2.9,0),cream); arm.CFrame*=CFrame.Angles(0,0,side*.3)
            p('Leg',Vector3.new(.27,1.3,.3),Vector3.new(side*.3,.95,0),cream)
            ball('Slipper',Vector3.new(.5,.35,.85),Vector3.new(side*.3,.2,-.15),col)
        end
        face(4.4,-1.2,.48)
    elseif species.tier==4 then
        body=ball('SharkBody',Vector3.new(2.8,2.7,4.1),Vector3.new(0,2.5,0),col)
        ball('WhiteBelly',Vector3.new(2.2,1.2,3.4),Vector3.new(0,1.9,-.3),cream)
        local fin=p('DorsalFin',Vector3.new(.35,1.7,1.4),Vector3.new(0,4,.5),col); fin.CFrame*=CFrame.Angles(.35,0,0)
        for _,o in {Vector3.new(-1.4,.55,-.5),Vector3.new(1.4,.55,-.5),Vector3.new(0,.55,1.8)} do
            ball('BlueSneaker',Vector3.new(1.25,.85,1.9),o,Color3.fromRGB(30,94,230))
            p('WhiteSole',Vector3.new(1.3,.2,1.95),o-Vector3.new(0,.35,0),Color3.new(1,1,1))
            p('Laces',Vector3.new(.8,.08,.5),o+Vector3.new(0,.42,-.2),Color3.new(1,1,1))
        end
        face(2.9,-1.95,.6)
    elseif species.tier==5 then
        local wood=Color3.fromRGB(108,74,44)
        body=cylinder('TreeTrunk',Vector3.new(3.4,2.3,2.3),Vector3.new(0,2.4,0),wood)
        for _,o in {Vector3.new(-1,4.4,0),Vector3.new(1,4.4,0),Vector3.new(0,5.1,.2)} do ball('TreeCanopy',Vector3.new(2.6,2.1,2.3),o,col) end
        ball('MonkeyFace',Vector3.new(1.7,1.9,.8),Vector3.new(0,3.05,-1),cream)
        for _,side in {-1,1} do
            local arm=p('BranchArm',Vector3.new(.5,2.8,.5),Vector3.new(side*1.5,2.7,0),wood); arm.CFrame*=CFrame.Angles(0,0,side*.5)
            ball('HugeFoot',Vector3.new(1.5,.8,2.5),Vector3.new(side*.9,.45,-.4),cream)
        end
        face(3.4,-1.45,.42)
    else
        body=ball('Fuselage',Vector3.new(1.8,1.7,4.3),Vector3.new(0,2.8,.7),col)
        ball('CrocodileHead',Vector3.new(2.4,1.5,2.5),Vector3.new(0,2.7,-1.8),col)
        p('LongSnout',Vector3.new(1.8,.75,2),Vector3.new(0,2.3,-2.6),col)
        p('Jaw',Vector3.new(1.8,.2,2),Vector3.new(0,1.9,-2.6),cream)
        p('Wings',Vector3.new(5.8,.25,1.7),Vector3.new(0,2.7,.5),Color3.fromRGB(120,133,105))
        p('Tailplane',Vector3.new(3,.2,1),Vector3.new(0,3,2.6),col)
        p('TailFin',Vector3.new(.25,1.5,1.1),Vector3.new(0,3.6,2.4),col)
        for _,side in {-1,1} do
            ball('Engine',Vector3.new(.8,.9,1.6),Vector3.new(side*2,2.7,.1),dark)
            p('Propeller',Vector3.new(.15,1.9,.12),Vector3.new(side*2,2.7,-.8),cream)
            ball('LandingWheel',Vector3.new(.7,.7,.7),Vector3.new(side*.7,.8,0),dark)
        end
        face(3,-2.85,.6)
    end
    m.PrimaryPart=body; m:SetAttribute('BasePosition',position)
    if mini then
        m:ScaleTo(.42)
        local box,extent=m:GetBoundingBox()
        m:PivotTo(m:GetPivot()+Vector3.new(position.X-box.Position.X,position.Y+extent.Y/2-box.Position.Y,position.Z-box.Position.Z))
    else
        Factory.characterLabel(body,species,4)
    end
    m.Parent=parent; return m
end
function Factory.mini(parent: Instance,token: any,species: any): Model
    local m=Factory.producer(parent,token.id,species,Vector3.new(token.x,.2,token.z),true)
    m:SetAttribute('OwnerUserId',token.owner); return m
end
return Factory
