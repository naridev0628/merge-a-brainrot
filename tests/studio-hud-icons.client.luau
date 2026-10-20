-- Private UI clones; no live HUD or character changes.
local icons=require(game.Players.LocalPlayer.PlayerScripts.Controllers.Icon3D)
local templates=assert(game.ReplicatedStorage:FindFirstChild('UIModels'))
local sandbox=Instance.new('Frame');sandbox.ZIndex=5
local result={}
for kind,name in {book='Book',rebirth='Rebirth',gear='Gear',merge='Merge'} do
    local source=assert(templates:FindFirstChild(name))
    local viewport=assert(icons.create(sandbox,kind,UDim2.fromScale(0,0),UDim2.fromScale(1,1)))
    assert(viewport:IsA('ViewportFrame') and viewport.BackgroundTransparency==1 and not viewport.Active)
    assert(viewport:GetAttribute('BlenderAuthored') and viewport.ZIndex==6)
    local sculpture=viewport.Sculpture:FindFirstChild(name)
    assert(sculpture and sculpture~=source,'Viewport must own its own sculpture clone')
    local count,prisms=0,0
    for _,piece in sculpture:GetDescendants() do
        if piece:IsA('BasePart') then
            count+=1
            assert(piece.Anchored and not piece.CanCollide and not piece.CanTouch and not piece.CanQuery)
            assert(math.min(piece.Size.X,piece.Size.Y,piece.Size.Z)>0,'Every icon solid needs volume')
            if piece:IsA('WedgePart') then prisms+=1 end
        end
    end
    assert(count>10 and count<=64 and viewport:GetAttribute('SolidCount')==count)
    if kind=='rebirth' then assert(prisms==4,'Rebirth arrowheads need two solid prisms each') end
    if kind=='merge' then assert(prisms==2,'Merge arrowhead needs solid extrusion') end
    local camera=assert(viewport.CurrentCamera)
    local bounds=sculpture:GetBoundingBox()
    assert((camera.CFrame.LookVector-(bounds.Position-camera.CFrame.Position).Unit).Magnitude<.001)
    assert(camera.Parent==viewport and viewport.LightColor.R>viewport.Ambient.R)
    result[kind]=count
end
assert(icons.create(sandbox,'unsupported',UDim2.new(),UDim2.new())==nil,'Unknown artwork must preserve the existing fallback')
sandbox:Destroy()
return result
