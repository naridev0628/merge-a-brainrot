-- Run after the generated world is ready.
local root=workspace.MergeABrainrotGenerated
local Map=require(game.ReplicatedStorage.Shared.MapSpec)
local landings={}
for _,part in root:GetChildren() do
    if part.Name=='BridgeLanding' then
        assert(part.CanCollide and part.Transparency==0,'Landing must be visible and walkable')
        landings[part:GetAttribute('PlotId')]=part
    end
end
for id=1,6 do
    local plot=root['Plot'..id]
    local landing=assert(landings[id],'Bridge '..id..' needs a solid landing')
    local frame=plot:GetPivot()
    local center=frame:PointToObjectSpace(landing.Position)
    local front=-38*Map.PlotScale
    assert(center.Z-landing.Size.Z/2<front-.5 and center.Z+landing.Size.Z/2>front+.5,'Landing must overlap both bridge and plot')
    assert(math.abs(center.X)<.01 and landing.Size.X>=12,'Landing must span the open entrance')
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={root};params.RespectCanCollide=true
    for x=-5,5,5 do for z=front-2,front+2,.25 do
        local point=frame:PointToWorldSpace(Vector3.new(x,8,z))
        local hit=workspace:Raycast(point,Vector3.new(0,-12,0),params)
        assert(hit and hit.Instance.CanCollide and hit.Position.Y>=-.05,'Walkable bridge seam has a gap')
    end end
end
return 'PASS six visible bridge landings and walkable plot seams'
