-- Run against the rebuilt map. The public approach paths must remain clear
-- even when imported prop bounding boxes differ from the authored examples.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local scenery=assert(root:FindFirstChild('HubScenery'))
local function bounds(part,frame)
    local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        local p=frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))
        lo=lo:Min(p);hi=hi:Max(p)
    end end end
    return lo,hi
end
local paths={}
for _,p in root:GetChildren() do if p.Name=='LobbyWalkway' then table.insert(paths,p) end end
assert(#paths==6,'Every plot needs a complete approach')
local checks=0
for _,path in paths do
    assert(path.Size.X==14 and path.Size.Z==62,'Walkway must join plaza and bridge')
    for _,p in scenery:GetDescendants() do if p:IsA('BasePart') and p.Position.Y+p.Size.Y/2>0 then
        local lo,hi=bounds(p,path.CFrame)
        assert(hi.X<=-7.3 or lo.X>=7.3 or hi.Z<=-31 or lo.Z>=31,
            p:GetFullName()..' screens a bridge approach')
        checks+=1
    end end
end
assert(root.Water.CanCollide and root.Water.Transparency==1,'Retain underwater fallback floor')
assert(workspace.Terrain.WaterWaveSize>0,'Ocean needs gentle visible wave detail')
return 'PASS: six open hub routes, '..checks..' prop clearance checks, ocean fallback'
