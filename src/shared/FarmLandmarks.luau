--!strict
-- Original native brick landmarks, informed by the farm's broad island edges
-- and tall banded silo. Plot geometry is authored in logical coordinates:
-- call buildPlot before WorldBuilder scales and positions the whole plot.
local Config=require(script.Parent.Config)
local Map=require(script.Parent.MapSpec)
local Landmarks={}

local grass=Color3.fromRGB(106,193,31)
local grassLight=Color3.fromRGB(129,214,43)
local grassDark=Color3.fromRGB(77,151,26)
local red=Color3.fromRGB(213,42,43)
local redLight=Color3.fromRGB(235,68,65)
local redDark=Color3.fromRGB(164,31,34)
local cream=Color3.fromRGB(255,245,220)
local white=Color3.fromRGB(255,252,239)
local foundationBottom=-7.7
local siloCenter=Vector3.new(-55,0,-23)

local function block(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,solid: boolean?): Part
    local part=Instance.new('Part')
    part.Name=name
    part.Size=size
    part.CFrame=cf
    part.Color=color
    part.Material=Enum.Material.Plastic
    part.Anchored=true
    part.CanCollide=solid==true
    part.CanQuery=solid==true
    part.CanTouch=false
    part.TopSurface=Enum.SurfaceType.Smooth
    part.BottomSurface=Enum.SurfaceType.Smooth
    if solid then part:SetAttribute('FoundationSolid',true) end
    part.Parent=parent
    return part
end

local function model(parent: Instance?,name: string): Model
    local result=Instance.new('Model')
    result.Name=name
    result.WorldPivot=CFrame.identity
    result:SetAttribute('NativeBrickArt',true)
    result.Parent=parent
    return result
end

local function foundation(parent: Instance,name: string,x: number,z: number,width: number,depth: number,top: number)
    block(parent,name,Vector3.new(width,top-foundationBottom,depth),
        CFrame.new(x,(top+foundationBottom)/2,z),grass,true)
end

-- Use the external outline only: internal seams between the lawn, rear bank
-- and farmer alcove do not get floating trim or duplicate stud rows.
local function edgeDetails(parent: Instance,outline: {Vector3},upperY: number,lowerY: number,pitch: number)
    for index,from in outline do
        local to=outline[index%#outline+1]
        local along=to-from
        local length=along.Magnitude
        local outward=Vector3.new(along.Z,0,-along.X).Unit
        local midpoint=(from+to)/2
        local frame=CFrame.lookAt(midpoint,midpoint+outward)
        block(parent,'GrassEdgeLip',Vector3.new(length,.38,.16),frame*CFrame.new(0,upperY,0),grassLight)
        block(parent,'LowerGreenCourse',Vector3.new(length,.58,.18),frame*CFrame.new(0,lowerY,0),grassDark)
        local count=math.max(1,math.floor(length/pitch))
        for i=1,count do
            local position=from+along*((i-.5)/count)+outward*.11
            for _,y in {upperY-1.45,upperY-3.2} do
                block(parent,'IslandSideStud',Vector3.new(.72,.72,.22),
                    CFrame.lookAt(position+Vector3.new(0,y,0),position+Vector3.new(0,y,0)+outward),grassLight)
            end
        end
    end
end

local function silo(parent: Instance): Model
    local result=model(parent,'FarmSilo')
    local origin=CFrame.new(siloCenter)
    block(result,'SiloFoot',Vector3.new(11.3,.7,11.3),origin*CFrame.new(0,.35,0),redDark)
    block(result,'RedSiloBody',Vector3.new(10.4,31.8,10.4),origin*CFrame.new(0,16.3,0),red)
    -- Four pale vertical corner ribs connect the white horizontal courses.
    for _,x in {-5.13,5.13} do for _,z in {-5.13,5.13} do
        block(result,'PaleCornerRib',Vector3.new(.72,32.2,.72),origin*CFrame.new(x,16.7,z),cream)
    end end
    for level=1,4 do
        local bandY=level*8
        block(result,'WhiteSiloBand',Vector3.new(11.2,1.65,11.2),origin*CFrame.new(0,bandY,0),cream)
        for face=0,3 do
            local facing=origin*CFrame.Angles(0,face*math.pi/2,0)
            for _,x in {-2.5,2.5} do
                block(result,'BandStud',Vector3.new(.72,.64,.18),facing*CFrame.new(x,bandY,-5.69),white)
                for _,height in {bandY-5.55,bandY-2.65} do
                    block(result,'RedSiloStud',Vector3.new(.78,.78,.2),facing*CFrame.new(x,height,-5.3),redLight)
                end
            end
        end
    end
    for index,width in {12,10.7,9.2,7.4} do
        block(result,'PaleRoofCap',Vector3.new(width,.75,width),
            origin*CFrame.new(0,32.7+(index-.5)*.75,0),if index%2==0 then white else cream)
    end
    for _,x in {-2.5,0,2.5} do for _,z in {-2.5,0,2.5} do
        block(result,'RoofStud',Vector3.new(.85,.17,.85),origin*CFrame.new(x,35.785,z),white)
    end end
    return result
end

-- The silo occupies an outboard bay beside the cash/farmer area. Its outer
-- roof bounds are x [-61,-49], z [-29,-17]. The original x=-48 side fence
-- completely separates this bay from the lawn; no play route is narrowed.
function Landmarks.buildPlot(parent: Instance): Model
    local result=model(nil,'FarmLandmarks')
    local foundations=model(result,'IslandFoundations')
    local rearDepth=Config.PlotBackZ-Config.PlotRearStartZ
    local rearCenter=(Config.PlotBackZ+Config.PlotRearStartZ)/2
    foundation(foundations,'FrontIslandFoundation',0,3,96,82,-.9)
    foundation(foundations,'RearIslandFoundation',0,rearCenter,112,rearDepth,-.9)
    foundation(foundations,'FarmerAlcoveFoundation',Map.FarmerAlcoveCenter.X,Map.FarmerAlcoveCenter.Z,
        Map.FarmerAlcoveSize.X,Map.FarmerAlcoveSize.Z,-.9)
    local bay=block(foundations,'SiloBay',Vector3.new(14,-foundationBottom,22),
        CFrame.new(-55,foundationBottom/2,-24),grass,true)
    bay.TopSurface=Enum.SurfaceType.Studs
    local alcoveLeft=Map.FarmerAlcoveCenter.X-Map.FarmerAlcoveSize.X/2
    local alcoveRight=Map.FarmerAlcoveCenter.X+Map.FarmerAlcoveSize.X/2
    local alcoveFront=Map.FarmerAlcoveCenter.Z-Map.FarmerAlcoveSize.Z/2
    local outline={
        Vector3.new(-48,0,-38),Vector3.new(alcoveLeft,0,-38),
        Vector3.new(alcoveLeft,0,alcoveFront),Vector3.new(alcoveRight,0,alcoveFront),
        Vector3.new(alcoveRight,0,-38),Vector3.new(48,0,-38),
        Vector3.new(48,0,Config.PlotRearStartZ),Vector3.new(56,0,Config.PlotRearStartZ),
        Vector3.new(56,0,Config.PlotBackZ),Vector3.new(-56,0,Config.PlotBackZ),
        Vector3.new(-56,0,Config.PlotRearStartZ),Vector3.new(-48,0,Config.PlotRearStartZ),
        Vector3.new(-48,0,-13),Vector3.new(-62,0,-13),Vector3.new(-62,0,-35),Vector3.new(-48,0,-35),
    }
    edgeDetails(foundations,outline,-1.15,-6.75,10)
    silo(result)
    result:SetAttribute('PartBudget',300)
    result.Parent=parent
    return result
end

-- World-space helper for the existing radius-96 hub with top Y=0. Its skirt
-- overlaps the original slab by .1 stud, extends down to -5.5, and never adds
-- an upper surface above the original slab. No additional top studs.
function Landmarks.buildHub(parent: Instance,center: CFrame?,radius: number?): Model
    local r=radius or 96
    assert(r>0,'Hub radius must be positive')
    local result=model(nil,'HubIslandSkirt')
    local a=r*(math.sqrt(2)-1)
    local leg=r-a
    local thickness=4.6
    local y=-.9-thickness/2
    block(result,'HubCenterFoundation',Vector3.new(2*a,thickness,2*a),CFrame.new(0,y,0),grass,true)
    for side=0,3 do
        local turn=CFrame.Angles(0,side*math.pi/2,0)
        block(result,'HubStraightFoundation',Vector3.new(leg,thickness,2*a),turn*CFrame.new(a+leg/2,y,0),grass,true)
        local wedge=Instance.new('WedgePart')
        wedge.Name='HubCornerFoundation'
        wedge.Size=Vector3.new(thickness,leg,leg)
        wedge.CFrame=turn*CFrame.fromMatrix(Vector3.new(a+leg/2,y,a+leg/2),Vector3.yAxis,Vector3.xAxis,-Vector3.zAxis)
        wedge.Color=grass
        wedge.Material=Enum.Material.Plastic
        wedge.Anchored=true
        wedge.CanCollide=true
        wedge.CanQuery=true
        wedge.CanTouch=false
        wedge.TopSurface=Enum.SurfaceType.Smooth
        wedge.BottomSurface=Enum.SurfaceType.Smooth
        wedge:SetAttribute('FoundationSolid',true)
        wedge.Parent=result
    end
    edgeDetails(result,{
        Vector3.new(-a,0,-r),Vector3.new(a,0,-r),Vector3.new(r,0,-a),Vector3.new(r,0,a),
        Vector3.new(a,0,r),Vector3.new(-a,0,r),Vector3.new(-r,0,a),Vector3.new(-r,0,-a),
    },-1.1,-5.1,10)
    result:PivotTo(center or CFrame.identity)
    result.Parent=parent
    return result
end

return table.freeze(Landmarks)
