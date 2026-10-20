--!strict
-- Blender-authored recessed tiles. Existing floors remain the walking surface.
local Surface={}
local Replicated=game:GetService('ReplicatedStorage')
local shades={Green=Color3.fromRGB(121,185,87),Gold=Color3.fromRGB(220,188,133),
    Brown=Color3.fromRGB(158,118,82),Edge=Color3.fromRGB(78,128,65)}
local function model(parent: Instance,name: string): Model
    local result=Instance.new('Model');result.Name=name
    result:SetAttribute('BlenderAuthored',true);result:SetAttribute('TileCount',0)
    result.Parent=parent;return result
end
local function tile(parent: Model,cf: CFrame,width: number,depth: number,palette: string,triangle: boolean?)
    local templates=Replicated:FindFirstChild('MapModels')
    local key=if palette=='Edge' then 'GroundGreenEdge' else 'Ground'..palette..(if triangle then 'Triangle' else 'Tile')
    local template=templates and templates:FindFirstChild(key)
    local part: BasePart
    if template and template:IsA('MeshPart') then
        part=template:Clone()
        part.Size=Vector3.new(width,.16,depth)
        part.CFrame=cf*CFrame.new(0,.10,0)
        -- The authored texture carries continuous grass hues within each tile.
        -- This low-frequency field modulates larger patches deterministically.
        local p=cf.Position
        local field=(math.sin(p.X/41+p.Z/63)+math.cos(p.Z/53-p.X/79))*.5
        if palette=='Green' then
            part.Color=Color3.new(.975+.025*field,.98+.02*field,.97+.03*field)
        else
            local tint=.97+.025*field
            part.Color=Color3.new(tint,tint,tint)
        end
    else
        parent:SetAttribute('MissingTemplate',true)
        if triangle then
            local wedge=Instance.new('WedgePart')
            wedge.Size=Vector3.new(.16,width,depth)
            wedge.CFrame=cf*CFrame.new(0,.10,0)*CFrame.fromMatrix(Vector3.zero,Vector3.yAxis,Vector3.xAxis,-Vector3.zAxis)
            wedge.RightSurface=Enum.SurfaceType.Studs;part=wedge
        else
            local block=Instance.new('Part')
            block.Size=Vector3.new(width,.16,depth)
            block.CFrame=cf*CFrame.new(0,.10,0);block.TopSurface=Enum.SurfaceType.Studs;part=block
        end
        part.Color=(shades :: any)[palette] or shades.Green
    end
    part.Name=key;part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
    part.CastShadow=false;part.Material=Enum.Material.Plastic
    part:SetAttribute('GroundPalette',palette);part.Parent=parent
    parent:SetAttribute('TileCount',(parent:GetAttribute('TileCount') :: number)+1)
end
local function rectangle(parent: Model,cf: CFrame,width: number,depth: number,palette: string)
    local nx=math.max(1,math.ceil(width/16))
    local nz=math.max(1,math.ceil(depth/(if palette=='Edge' then 8 else 16)))
    -- Equal-sized cells keep partial edges from squeezing a thin strip of studs.
    local sx,sz=width/nx,depth/nz
    for x=1,nx do for z=1,nz do
        tile(parent,cf*CFrame.new((x-(nx+1)/2)*sx,0,(z-(nz+1)/2)*sz),sx,sz,palette)
    end end
end
function Surface.cover(part: BasePart,palette: string?): Model
    local previous=part:FindFirstChild('AuthoredGround')
    if previous then previous:Destroy() end
    local result=model(part,'AuthoredGround')
    part.TopSurface=Enum.SurfaceType.Smooth
    rectangle(result,part.CFrame*CFrame.new(0,part.Size.Y/2,0),part.Size.X,part.Size.Z,palette or 'Green')
    return result
end
-- frontFrame's local -Z points out of the board; relief extends only .18 studs.
function Surface.panel(parent: Instance,frontFrame: CFrame,width: number,height: number,palette: string?): Model
    local result=model(parent,'Authored'..(palette or 'Brown')..'Panel')
    rectangle(result,frontFrame*CFrame.Angles(-math.pi/2,0,0),width,height,palette or 'Brown')
    return result
end
function Surface.sides(part: BasePart,depth: number,edges: {[string]: boolean}?): Model
    local previous=part:FindFirstChild('AuthoredIslandSides')
    if previous then previous:Destroy() end
    local result=model(part,'AuthoredIslandSides')
    local core=Instance.new('Part');core.Name='IslandDepth'
    core.Size=Vector3.new(part.Size.X,depth,part.Size.Z)
    core.CFrame=part.CFrame*CFrame.new(0,part.Size.Y/2-depth/2,0)
    core.Anchored=true;core.CanCollide=false;core.CanTouch=false;core.CanQuery=false
    core.Color=shades.Edge;core.Material=Enum.Material.Plastic;core.Parent=result
    for _,edge in {
        {key='Front',x=0,z=-part.Size.Z/2,angle=0,width=part.Size.X},
        {key='Back',x=0,z=part.Size.Z/2,angle=math.pi,width=part.Size.X},
        {key='Left',x=-part.Size.X/2,z=0,angle=math.pi/2,width=part.Size.Z},
        {key='Right',x=part.Size.X/2,z=0,angle=-math.pi/2,width=part.Size.Z},
    } do
        if not edges or edges[edge.key] then
            local frame=part.CFrame*CFrame.new(edge.x,part.Size.Y/2-depth/2,edge.z)*CFrame.Angles(0,edge.angle,0)
            rectangle(result,frame*CFrame.Angles(-math.pi/2,0,0),edge.width,depth,'Edge')
        end
    end
    return result
end
function Surface.octagon(parent: Instance,topFrame: CFrame,radius: number,palette: string?): Model
    local result=model(parent,'AuthoredOctagonalGround')
    local color=palette or 'Gold'
    local a=radius*(math.sqrt(2)-1);local leg=radius-a
    rectangle(result,topFrame,2*a,2*a,color)
    local count=math.max(1,math.ceil(leg/16));local size=leg/count
    for side=0,3 do
        local turn=topFrame*CFrame.Angles(0,side*math.pi/2,0)
        rectangle(result,turn*CFrame.new(a+leg/2,0,0),leg,2*a,color)
        local corner=turn*CFrame.new(a+leg/2,0,a+leg/2)
        for x=0,count-1 do for z=0,count-1-x do
            tile(result,corner*CFrame.new((x+.5)*size-leg/2,0,(z+.5)*size-leg/2),
                size,size,color,x+z==count-1)
        end end
    end
    return result
end
return table.freeze(Surface)
