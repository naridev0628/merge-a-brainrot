--!strict
-- Authored farmer stall, in unscaled plot coordinates. WorldBuilder scales
-- and positions the completed plot after the stall is built.
local Shared=script.Parent
local Factory=require(Shared.ModelFactory)
local Map=require(Shared.MapSpec)
local Catalog=require(Shared.CreatureCatalog)
local FarmerBooth={}

function FarmerBooth.build(parent: Instance): Model
    local booth=Instance.new('Model'); booth.Name='DepositBooth'; booth.Parent=parent
    local boothFloor=Factory.part(booth,'BoothFoundation',Vector3.new(15,.45,8),CFrame.new(-30,.22,-3),Color3.fromRGB(106,119,176));boothFloor.TopSurface=Enum.SurfaceType.Studs
    for _,dx in {-6,6} do
        Factory.part(booth,'BoothPost',Vector3.new(1.4,15,1.4),CFrame.new(-30+dx,7.5,-4),Color3.fromRGB(115,73,39))
        for stud=1,10 do Factory.part(booth,'PostStud',Vector3.new(.45,.45,.15),CFrame.new(-30+dx,1+(stud-1)*1.4,-4.76),Color3.fromRGB(150,96,53)) end
    end
    for stripe=1,8 do
        local stripeColor=if stripe%2==0 then Color3.fromRGB(255,240,208) else Color3.fromRGB(239,52,46)
        local awning=Factory.part(booth,'Awning',Vector3.new(1.7,1.8,7),CFrame.new(-37.65+stripe*1.7,15,-3),stripeColor); awning.TopSurface=Enum.SurfaceType.Studs
        Factory.part(booth,'AwningFringe',Vector3.new(1.7,2.4,.8),CFrame.new(-37.65+stripe*1.7,14.7,-6.15),stripeColor)
        for _,y in {14,14.9} do Factory.part(booth,'AwningStud',Vector3.new(.65,.45,.18),CFrame.new(-37.65+stripe*1.7,y,-6.62),stripeColor:Lerp(Color3.new(1,1,1),.1)) end
    end
    local counter=Factory.part(booth,'Counter',Vector3.new(13,.6,3),CFrame.new(-30,3.2,-5),Color3.fromRGB(134,82,36))
    -- Broad blue counter body, informed by reference frames 015/079. Three
    -- inert panels stay under the existing slab; native studs add no Parts.
    local panelBottom=boothFloor.Position.Y+boothFloor.Size.Y/2
    local panelTop=counter.Position.Y-counter.Size.Y/2
    local panelHeight,panelY=panelTop-panelBottom,(panelTop+panelBottom)/2
    local function counterPanel(name: string,size: Vector3,position: Vector3)
        -- Deeper blue stays legible under the warm yellow deposit light.
        local panel=Factory.part(booth,name,size,CFrame.new(position),Color3.fromRGB(55,66,165))
        panel.CanCollide=false;panel.CanQuery=false;panel.CanTouch=false
        panel.FrontSurface=Enum.SurfaceType.Studs;panel.LeftSurface=Enum.SurfaceType.Studs;panel.RightSurface=Enum.SurfaceType.Studs
    end
    counterPanel('CounterFrontPanel',Vector3.new(13,panelHeight,.4),Vector3.new(-30,panelY,-6.3))
    counterPanel('CounterSidePanel',Vector3.new(.4,panelHeight,2.6),Vector3.new(-36.3,panelY,-4.8))
    counterPanel('CounterSidePanel',Vector3.new(.4,panelHeight,2.6),Vector3.new(-23.7,panelY,-4.8))
    local farmer=Factory.prop(booth,'Shopkeeper',CFrame.new(-30,.45,-2))
    if farmer then
        farmer.Size*=(5.5/Map.PlotScale)/farmer.Size.Y
        farmer.CFrame=CFrame.new(-30,.45+farmer.Size.Y/2,-2)
    end
    Factory.part(booth,'MiniSignFrame',Vector3.new(11.6,3.8,.6),CFrame.new(-30,11.5,-4.8),Color3.fromRGB(87,53,38))
    Factory.part(booth,'MiniSignFace',Vector3.new(10.8,3.1,.1),CFrame.new(-30,11.5,-5.16),Color3.fromRGB(152,111,91))
    for i,tier in {1,2,4} do
        local icon=Factory.producer(booth,'SignMini',Catalog[string.format('tier_%02d',tier)],Vector3.new(-33+i*2.4,10.2,-5.5),true)
        icon:ScaleTo(1.1)
    end
    -- Raised brick arrow stays visible with the miniature models on the sign.
    local function arrowLayer(padding: number,color: Color3,depth: number)
        Factory.part(booth,'DepositArrow',Vector3.new(.55+padding,1.8+padding,.1),CFrame.new(-34,11.6,depth),color)
        for _,side in {-1,1} do
            Factory.part(booth,'DepositArrow',Vector3.new(.55+padding,1.2+padding,.1),CFrame.new(-34+side*.36,11,depth)*CFrame.Angles(0,0,-side*math.pi/4),color)
        end
    end
    arrowLayer(.17,Color3.fromRGB(42,27,17),-5.38)
    arrowLayer(0,Color3.fromRGB(255,237,184),-5.49)
    local boothFrame=CFrame.new(Map.FarmerCenter)*CFrame.Angles(0,math.pi,0)*CFrame.new(30,0,3)
    for _,part in booth:GetDescendants() do if part:IsA('BasePart') then
        local cf=part.CFrame;local pos=cf.Position
        part.CFrame=CFrame.new(-30+(pos.X+30)*1.25,pos.Y,-3+(pos.Z+3)*1.25)*cf.Rotation
        if part.Parent==booth and part~=farmer then part.Size*=Vector3.new(1.25,1,1.25) end
        part.CFrame=boothFrame*part.CFrame
    end end
    return booth
end

return table.freeze(FarmerBooth)
