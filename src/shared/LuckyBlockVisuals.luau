--!strict
local Appearance=require(script.Parent.LuckyAppearance)
local Visuals={}
local DECORATION='LuckyQuestionMarks'
local DECORATION_VERSION=2
-- The authored block's seven-row pixel glyph, merged into seven runs per face.
-- Native white boxes keep it legible after removing the baked gold texture.
local runs={{0,0,5},{1,0,1},{1,4,1},{2,3,2},{3,2,2},{4,2,1},{6,2,1}}
local function whitePart(block: BasePart,folder: Folder,name: string,size: Vector3,cf: CFrame)
    local mark=Instance.new('Part');mark.Name=name;mark.Size=size;mark.CFrame=cf
    mark.Color=Color3.new(1,1,1);mark.Material=Enum.Material.SmoothPlastic
    mark.TopSurface=Enum.SurfaceType.Smooth;mark.BottomSurface=Enum.SurfaceType.Smooth
    mark.Anchored=false;mark.Massless=true;mark.CastShadow=false
    mark.CanCollide=false;mark.CanQuery=false;mark.CanTouch=false;mark.Parent=folder
    local weld=Instance.new('WeldConstraint');weld.Name='QuestionWeld';weld.Part0=block;weld.Part1=mark;weld.Parent=mark
end
local function questionMarks(block: BasePart,upgraded: boolean)
    local folder=Instance.new('Folder');folder.Name=DECORATION;folder.Parent=block
    local size=block.Size
    local cellY=size.Y*.35/4.0845
    local depth=math.min(size.X,size.Y,size.Z)*.006
    for face=1,4 do
        local onZ=face<=2
        local width=if onZ then size.X else size.Z
        local outward=if face==1 then Vector3.new(0,0,-1) elseif face==2 then Vector3.new(0,0,1)
            elseif face==3 then Vector3.new(-1,0,0) else Vector3.new(1,0,0)
        local half=if onZ then size.Z/2 else size.X/2
        local center=outward*(half+depth/2)
        local faceFrame=CFrame.lookAt(center,center-outward)
        local cellX=width*.35/4.01
        for index,run in runs do
            whitePart(block,folder,'Question'..face..'_'..index,Vector3.new(run[3]*cellX,cellY,depth),
                block.CFrame*faceFrame*CFrame.new((run[2]+run[3]/2-2.5)*cellX,(3-run[1])*cellY,0))
        end
    end
    if upgraded then
        -- build_bonus_props.py: centers (±1.80,±1.80,.15/3.76), sizes
        -- (.35,.35,.30), Blender Z-up. Imported mesh Y center is 1.98775.
        -- A .002 outward skin avoids coplanar blue faces while staying inside
        -- the authored mesh's overall bounds (4.01 × 4.0845 × 4.01).
        local scale=size/Vector3.new(4.01,4.0845,4.01)
        local capSize=Vector3.new(.354,.304,.354)*scale
        local index=0
        for _,x in {-1,1} do for _,z in {-1,1} do for _,top in {false,true} do
            index+=1
            local center=Vector3.new(x*1.80,(if top then 3.76 else .15)-1.98775,z*1.80)*scale
            if not block:IsA('MeshPart') then
                -- A plain fallback cube fills the whole bounds; place its
                -- caps on those corners instead of burying them in the cube.
                center=(size-capSize)/2*Vector3.new(x,if top then 1 else -1,z)
                    +Vector3.new(x,if top then 1 else -1,z)*scale*.002
            end
            whitePart(block,folder,'Corner'..index,capSize,block.CFrame*CFrame.new(center))
        end end end
    end
end
function Visuals.apply(block: BasePart,baseTier: number?)
    local appearance=Appearance.forTier(baseTier)
    local isMesh=block:IsA('MeshPart')
    if block:GetAttribute('LuckyOriginalColor')==nil then
        block:SetAttribute('LuckyOriginalColor',block.Color)
        if block:IsA('MeshPart') then block:SetAttribute('LuckyOriginalTexture',block.TextureID) end
    end
    if block:IsA('MeshPart') then
        block.TextureID=if appearance.key=='basic' then block:GetAttribute('LuckyOriginalTexture') else ''
        block.Color=if appearance.key=='basic' then block:GetAttribute('LuckyOriginalColor') else Color3.fromRGB(table.unpack(appearance.body))
    else
        block.Color=Color3.fromRGB(table.unpack(appearance.body))
    end
    local marks=block:FindFirstChild(DECORATION)
    local needsMarks=not isMesh or appearance.key=='upgraded'
    local unchanged=block:GetAttribute('LuckyAppearance')==appearance.key and block:GetAttribute('LuckyDecorationSize')==block.Size
        and block:GetAttribute('LuckyDecorationVersion')==DECORATION_VERSION
    block:SetAttribute('LuckyAppearance',appearance.key)
    if unchanged and ((marks~=nil)==needsMarks) then return end
    if marks then marks:Destroy() end
    block:SetAttribute('LuckyDecorationSize',block.Size)
    block:SetAttribute('LuckyDecorationVersion',DECORATION_VERSION)
    if needsMarks then questionMarks(block,appearance.key=='upgraded') end
end
return Visuals
