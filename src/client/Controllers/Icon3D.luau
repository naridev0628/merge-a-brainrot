--!strict
-- Blender-authored solids, fixed camera and lighting; no per-frame work or uploads.
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local Icon3D={}
local names={book='Book',rebirth='Rebirth',gear='Gear',merge='Merge'}

function Icon3D.create(parent: Instance,kind: string,pos: UDim2,size: UDim2): ViewportFrame?
    local name=names[kind]
    local templates=ReplicatedStorage:FindFirstChild('UIModels')
    local template=if templates and name then templates:FindFirstChild(name) else nil
    if not template or not template:IsA('Model') then return nil end
    local model=template:Clone()
    local count=0
    for _,piece in model:GetDescendants() do
        if piece:IsA('BasePart') then
            count+=1
            piece.Anchored=true;piece.CanCollide=false;piece.CanQuery=false;piece.CanTouch=false
        end
    end
    if count==0 or count>64 then model:Destroy();return nil end
    local viewport=Instance.new('ViewportFrame')
    viewport.Name='Icon';viewport.Position=pos;viewport.Size=size
    viewport.BackgroundTransparency=1;viewport.BorderSizePixel=0;viewport.Active=false
    viewport.ZIndex=if parent:IsA('GuiObject') then parent.ZIndex+1 else 1
    viewport.Ambient=Color3.fromRGB(168,177,195)
    viewport.LightColor=Color3.fromRGB(255,246,225)
    viewport.LightDirection=Vector3.new(-.6,-1,-.8)
    viewport:SetAttribute('BlenderAuthored',true)
    viewport:SetAttribute('IconKind',kind)
    viewport:SetAttribute('SolidCount',count)
    local world=Instance.new('WorldModel');world.Name='Sculpture';world.Parent=viewport;model.Parent=world
    local bounds,extent=model:GetBoundingBox()
    local camera=Instance.new('Camera');camera.Name='IconCamera';camera.FieldOfView=35
    local distance=math.max(extent.X,extent.Y,extent.Z)*1.90
    local direction=Vector3.new(4,6,-12).Unit
    camera.CFrame=CFrame.lookAt(bounds.Position+direction*distance,bounds.Position)
    camera.Parent=viewport;viewport.CurrentCamera=camera
    viewport.Parent=parent
    return viewport
end

return Icon3D
