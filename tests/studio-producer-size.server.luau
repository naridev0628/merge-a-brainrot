-- Run explicitly during final native verification. Private unparented fixtures;
-- no live producers, templates, player progress, or scripts are changed.
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Factory=require(Shared.ModelFactory)
local sandbox=Instance.new('Folder')
local results={}
local ok,problem=xpcall(function()
    for tier=1,Config.MaxTier do
        local id=string.format('tier_%02d',tier)
        local species=Catalog[id]
        local key=species.modelKey or id
        local folder=game.ReplicatedStorage:FindFirstChild(if species.modelKey then 'ExpansionModels' else 'CharacterModels')
        local template=folder and folder:FindFirstChild(key)
        assert(template and template:IsA('MeshPart'),'Missing imported producer '..key)
        local originalSize,originalFrame=template.Size,template.CFrame
        local position=Vector3.new(45,Config.DisplayPlatformHeight+Config.RowHeight*2,Config.DisplayZ)
        local model=Factory.producer(sandbox,'size-'..id,species,position)
        local mesh=assert(model.PrimaryPart)
        assert(mesh:IsA('MeshPart') and mesh.MeshId==template.MeshId,'Unexpected fallback or wrong imported character '..key)
        local pivot=model:GetPivot()
        model:ScaleTo(model:GetScale()*Config.PlotScale)
        local plot=CFrame.new(120,0,-60)*CFrame.Angles(0,math.pi/3,0)
        model:PivotTo(plot*CFrame.new(pivot.Position*Config.PlotScale)*pivot.Rotation)
        local box,size=model:GetBoundingBox()
        assert(math.abs(size.Y-3.15)<.001,'World height must be approximately half a standard avatar: '..key..' '..size.Y)
        assert(size.X<=Config.ColumnSpacing*.88*Config.PlotScale+.001,'Producer crosses a bay boundary: '..key)
        local floor=plot:PointToWorldSpace(position*Config.PlotScale)
        assert(math.abs(box.Position.Y-size.Y/2-floor.Y)<.001,'Feet left the platform: '..key)
        local nameplate=assert(mesh:FindFirstChild('CharacterLabel'))
        local labelTop=box.Position.Y+nameplate.StudsOffset.Y+nameplate.Size.Y.Scale/2
        local nextUnderside=floor.Y+(Config.RowHeight-Config.DisplayPlatformHeight)*Config.PlotScale
        assert(nextUnderside-labelTop>=.5,'Nameplate reaches the next shelf underside: '..key)
        assert(math.abs(model:GetScale()-Config.PlotScale)<.0001,'Plot scaling applied more than once')
        assert(template.Size==originalSize and template.CFrame==originalFrame,'Factory mutated imported template '..key)
        table.insert(results,{tier=tier,key=key,height=size.Y,width=size.X,depth=size.Z})
        model:Destroy()
    end
end,debug.traceback)
sandbox:Destroy()
assert(ok,problem)
return game.HttpService:JSONEncode({check='PASS native all-tier producer mesh, world size, bay width, floor and source-template invariants',tiers=results})
