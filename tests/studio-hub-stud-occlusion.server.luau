-- Read-only: run after rebuilding the world. Independently check every stud's
-- eight corners against actual opaque Parts, without using the cull helper.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local hub=assert(root:FindFirstChild('StuddedOctagonalPlatform'))
local covers={}
for _,part in root:GetChildren() do
    if part.Name=='LobbyWalkway' or part.Name=='GatheringCircle' then
        assert(part:IsA('Part') and part.Transparency==0,'Only opaque cover Parts can hide grass studs')
        table.insert(covers,part)
    end
end
assert(#covers==7,'Expected six walkways and the plaza')
local radius=hub:GetAttribute('Radius')
assert(radius==96,'Update this fixture deliberately if the hub layout changes')
local pitch,width=radius/25,.55
local a=radius*(math.sqrt(2)-1)
local limit=math.floor((radius-width)/pitch)
local actual={}
local count,solids=0,0
for _,part in hub:GetChildren() do
    if part:IsA('BasePart') then
        if part.Name=='SquareStud' then
            local ix,iz=math.round(part.Position.X/pitch),math.round(part.Position.Z/pitch)
            local key=ix..':'..iz
            assert(not actual[key],'Duplicate hub stud')
            assert((part.Position-Vector3.new(ix*pitch,.07,iz*pitch)).Magnitude<.0001,'Visible stud grid changed')
            assert((part.Size-Vector3.new(width,.14,width)).Magnitude<.0001,'Visible stud size changed')
            assert(not part.CanCollide and not part.CanQuery and not part.CanTouch)
            actual[key]=part;count+=1
        else
            assert(part.CanCollide,'Preserve the solid octagonal foundation')
            solids+=1
        end
    end
end
local function fullyInside(x,z,cover)
    for _,dx in {-width/2,width/2} do for _,dz in {-width/2,width/2} do for _,y in {0,.14} do
        local point=cover.CFrame:PointToObjectSpace(Vector3.new(x+dx,y,z+dz))
        local half=cover.Size/2
        -- Tiny tolerance accounts only for Roblox's float CFrame storage.
        if cover.Shape==Enum.PartType.Cylinder then
            if math.abs(point.X)>half.X+.00001 or point.Y*point.Y+point.Z*point.Z>half.Y*half.Y+.00001 then return false end
        elseif math.abs(point.X)>half.X+.00001 or math.abs(point.Y)>half.Y+.00001 or math.abs(point.Z)>half.Z+.00001 then
            return false
        end
    end end end
    return true
end
local culled,candidates=0,0
for ix=-limit,limit do for iz=-limit,limit do
    local x,z=ix*pitch,iz*pitch
    if math.abs(x)+math.abs(z)+width<=radius+a then
        candidates+=1
        local covered=false
        for _,cover in covers do if fullyInside(x,z,cover) then covered=true;break end end
        local key=ix..':'..iz
        if covered then
            assert(not actual[key],'Fully hidden stud was retained: '..key)
            culled+=1
        else
            assert(actual[key],'Visible or partly exposed stud was removed: '..key)
        end
        actual[key]=nil
    end
end end
assert(next(actual)==nil,'Unexpected studs outside the original grid')
assert(solids==9 and candidates==2037 and count==1480 and culled==557,'Unexpected geometry reduction')
return 'PASS 557 fully enclosed hub studs removed; all 1480 visible/partial studs and 9 collision slabs preserved'
