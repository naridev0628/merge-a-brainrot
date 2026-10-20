--!strict
-- Native brick island foundations. Plot geometry is authored in logical coordinates:
-- call buildPlot before WorldBuilder scales and positions the whole plot.
local Config=require(script.Parent.Config)
local Map=require(script.Parent.MapSpec)
local GroundSurface=require(script.Parent.GroundSurface)
local Landmarks={}

local grass=Color3.fromRGB(106,193,31)
local foundationBottom=-7.7

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
local function edgeDetails(parent: Instance,outline: {Vector3},depth: number)
    for index,from in outline do
        local to=outline[index%#outline+1]
        local along=to-from
        local length=along.Magnitude
        local outward=Vector3.new(along.Z,0,-along.X).Unit
        local midpoint=(from+to)/2
        local frame=CFrame.lookAt(midpoint,midpoint+outward)
        GroundSurface.panel(parent,frame*CFrame.new(0,-depth/2,0),length,depth,'Edge')
    end
end

function Landmarks.buildPlot(parent: Instance): Model
    local result=model(nil,'FarmLandmarks')
    local foundations=model(result,'IslandFoundations')
    local rearDepth=Config.PlotBackZ-Config.PlotRearStartZ
    local rearCenter=(Config.PlotBackZ+Config.PlotRearStartZ)/2
    foundation(foundations,'FrontIslandFoundation',0,3,Map.FrontWidth,82,-.9)
    foundation(foundations,'RearIslandFoundation',0,rearCenter,Map.RearWidth,rearDepth,-.9)
    foundation(foundations,'FarmerAlcoveFoundation',Map.FarmerAlcoveCenter.X,Map.FarmerAlcoveCenter.Z,
        Map.FarmerAlcoveSize.X,Map.FarmerAlcoveSize.Z,-.9)
    local alcoveLeft=Map.FarmerAlcoveCenter.X-Map.FarmerAlcoveSize.X/2
    local alcoveRight=Map.FarmerAlcoveCenter.X+Map.FarmerAlcoveSize.X/2
    local alcoveFront=Map.FarmerAlcoveCenter.Z-Map.FarmerAlcoveSize.Z/2
    local outline={
        Vector3.new(-Map.FrontWidth/2,0,-38),Vector3.new(alcoveLeft,0,-38),
        Vector3.new(alcoveLeft,0,alcoveFront),Vector3.new(alcoveRight,0,alcoveFront),
        Vector3.new(alcoveRight,0,-38),Vector3.new(Map.FrontWidth/2,0,-38),
        Vector3.new(Map.FrontWidth/2,0,Config.PlotRearStartZ),Vector3.new(Map.RearWidth/2,0,Config.PlotRearStartZ),
        Vector3.new(Map.RearWidth/2,0,Config.PlotBackZ),Vector3.new(-Map.RearWidth/2,0,Config.PlotBackZ),
        Vector3.new(-Map.RearWidth/2,0,Config.PlotRearStartZ),Vector3.new(-Map.FrontWidth/2,0,Config.PlotRearStartZ),
    }
    edgeDetails(foundations,outline,7.7)
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
    },5.5)
    result:PivotTo(center or CFrame.identity)
    result.Parent=parent
    return result
end

return table.freeze(Landmarks)
