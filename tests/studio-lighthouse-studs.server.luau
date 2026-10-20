-- Read-only after rebuilding the world. The baseline describes the original
-- lighthouse. Corner tests use actual cover Parts, independently of the helper.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local model=assert(root:FindFirstChild('RedWhiteLighthouse',true))
local scale,pivot=model:GetScale(),model:GetPivot()
local cream=Color3.fromRGB(255,239,190)
local red=Color3.fromRGB(211,43,36)
local white=Color3.fromRGB(255,249,224)
local dark=Color3.fromRGB(37,51,58)
local baseline={}
local tower,roof={},{}
local function body(name,size,cf,color,solid,studGroup,sides,material,transparency)
    local entry={name=name,size=size,cf=cf,color=color,solid=solid,studGroup=studGroup,sides=sides,
        material=material or Enum.Material.Plastic,transparency=transparency or 0}
    table.insert(baseline,entry)
    if studGroup then table.insert(if studGroup=='tower' then tower else roof,entry) end
    return entry
end
body('CreamFoundation',Vector3.new(10.6,1,10.6),CFrame.new(0,.5,0),cream,true,'tower')
for index=0,5 do
    local y=1+index*4
    body('RedTowerBand',Vector3.new(8.2,3,8.2),CFrame.new(0,y+1.5,0),red,true,'tower',true)
    body('WhiteTowerBand',Vector3.new(8.7,1,8.7),CFrame.new(0,y+3.5,0),white,true,'tower',true)
end
body('DoorFrame',Vector3.new(2.6,4.1,.35),CFrame.new(0,3.05,-4.23),cream,false)
body('Door',Vector3.new(1.8,3.35,.42),CFrame.new(0,2.7,-4.42),dark,false)
body('DoorKnob',Vector3.new(.25,.25,.25),CFrame.new(.55,2.6,-4.71),cream,false)
for side=0,3 do
    local turn=CFrame.Angles(0,side*math.pi/2,0)
    for _,y in {10.5,18.5} do
        body('WindowFrame',Vector3.new(1.7,2.1,.27),turn*CFrame.new(0,y,-4.22),cream,false)
        body('BlueWindow',Vector3.new(1.1,1.5,.3),turn*CFrame.new(0,y,-4.4),Color3.fromRGB(65,125,152),false)
    end
end
body('LanternBalcony',Vector3.new(10,.8,10),CFrame.new(0,25.4,0),cream,true,'tower')
for _,x in {-3.65,3.65} do for _,z in {-3.65,3.65} do
    body('LanternPillar',Vector3.new(.65,4.3,.65),CFrame.new(x,27.9,z),white,true)
end end
for side=0,3 do
    local turn=CFrame.Angles(0,side*math.pi/2,0)
    body('LanternGlass',Vector3.new(6.6,3.7,.12),turn*CFrame.new(0,27.9,-3.65),Color3.fromRGB(170,224,232),false,nil,nil,Enum.Material.Glass,.6)
    body('LanternRail',Vector3.new(7.7,.3,.35),turn*CFrame.new(0,27,-3.8),white,false)
end
body('Beacon',Vector3.new(1.5,2.7,1.5),CFrame.new(0,27.9,0),Color3.fromRGB(255,221,90),false,nil,nil,Enum.Material.Neon)
for index,width in {10.3,8.5,6.5,4.3} do
    body('SteppedCreamRoof',Vector3.new(width,.7,width),CFrame.new(0,30.25+(index-1)*.7,0),cream,true,'roof')
end
body('RoofFinial',Vector3.new(.75,1.3,.75),CFrame.new(0,33.35,0),red,false)
local function key(name,position)
    return name..string.format(':%d:%d:%d',math.round(position.X*1000),math.round(position.Y*1000),math.round(position.Z*1000))
end
local function worldFrame(cf)
    return pivot*CFrame.new(cf.Position*scale)*cf.Rotation
end
local function sameGeometry(part,size,cf,color)
    assert((part.Size-size*scale).Magnitude<.0001,'Part size changed: '..part.Name)
    local expected=worldFrame(cf)
    assert((part.Position-expected.Position).Magnitude<.0001,'Part position changed: '..part.Name)
    assert((part.CFrame.RightVector-expected.RightVector).Magnitude<.0001
        and (part.CFrame.UpVector-expected.UpVector).Magnitude<.0001,'Part orientation changed: '..part.Name)
    -- BasePart stores blended colors at 8-bit precision (for example, the
    -- cream stud's 239.75/192.55 channels read back as 239/192 in Studio).
    -- Base colors are already integer RGB and retain the tighter comparison.
    local colorTolerance=if part.Name=='SquareStud' then 1/255+.000001 else .0001
    assert(math.abs(part.Color.R-color.R)<=colorTolerance and math.abs(part.Color.G-color.G)<=colorTolerance
        and math.abs(part.Color.B-color.B)<=colorTolerance,'Part color changed: '..part.Name)
end
local bodies,studs={},{}
local solidCount,bodyCount,studCount=0,0,0
for _,part in model:GetChildren() do
    assert(part:IsA('Part') and part.Shape==Enum.PartType.Block,'Unexpected lighthouse geometry')
    assert(part.Anchored and not part.CanTouch,'Lighthouse part physics changed')
    local position=pivot:PointToObjectSpace(part.Position)/scale
    local k=key(part.Name,position)
    local list=if part.Name=='SquareStud' then studs else bodies
    assert(not list[k],'Duplicate lighthouse part')
    list[k]=part
    if part.Name=='SquareStud' then
        assert(not part.CanCollide and not part.CanQuery and part.Transparency==0
            and part.Material==Enum.Material.Plastic,'Stud physics/material changed')
        studCount+=1
    else
        bodyCount+=1
        if part.CanCollide then solidCount+=1 end
    end
end
for _,entry in baseline do
    local k=key(entry.name,entry.cf.Position)
    local part=assert(bodies[k],'Missing original lighthouse part: '..k)
    sameGeometry(part,entry.size,entry.cf,entry.color)
    assert(part.CanCollide==entry.solid and part.CanQuery==entry.solid,'Collision changed: '..k)
    assert(part.Material==entry.material and math.abs(part.Transparency-entry.transparency)<.0001,'Material changed: '..k)
    entry.actual=part
    bodies[k]=nil
end
assert(next(bodies)==nil and bodyCount==51 and solidCount==22,'Non-stud geometry changed')
local beacon=assert(model:FindFirstChild('Beacon'))
local light=assert(beacon:FindFirstChild('BeaconGlow'))
assert(light:IsA('PointLight') and light.Enabled and light.Brightness==1.5 and light.Range>0 and light.Color==beacon.Color,
    'Beacon light changed')

local function fullyInside(cf,cover)
    assert(cover.Transparency==0 and cover.Shape==Enum.PartType.Block,'Cover must be an opaque brick')
    local transform=worldFrame(cf)
    local half=cover.Size/2
    -- Native float transforms have a small rounding error after plot rotation.
    local epsilon=.00003
    for _,x in {-.24,.24} do for _,y in {-.07,.07} do for _,z in {-.24,.24} do
        local point=cover.CFrame:PointToObjectSpace(transform:PointToWorldSpace(Vector3.new(x,y,z)*scale))
        if math.abs(point.X)>half.X+epsilon or math.abs(point.Y)>half.Y+epsilon
            or math.abs(point.Z)>half.Z+epsilon then return false end
    end end end
    return true
end
local budget={tower=660,roof=110}
local candidates,culled,kept=0,0,0
local function checkStud(cf,color,group,cover)
    if budget[group]<=0 then return end
    budget[group]-=1;candidates+=1
    local k=key('SquareStud',cf.Position)
    local actual=studs[k]
    if cover and fullyInside(cf,cover) then
        assert(not actual,'Fully hidden lighthouse stud retained: '..k)
        culled+=1
    else
        assert(actual,'Visible/partly exposed lighthouse stud removed: '..k)
        sameGeometry(actual,Vector3.new(.48,.14,.48),cf,color:Lerp(white,.075))
        kept+=1
    end
    studs[k]=nil
end
for _,group in {tower,roof} do for index,entry in group do
    local size,cf=entry.size,entry.cf
    local columns,rows=math.max(1,math.floor(size.X/1.55)),math.max(1,math.floor(size.Z/1.55))
    local cover=group[index+1] and group[index+1].actual
    for x=1,columns do for z=1,rows do
        checkStud(cf*CFrame.new((x-(columns+1)/2)*1.55,size.Y/2+.07,(z-(rows+1)/2)*1.55),entry.color,entry.studGroup,cover)
    end end
    if entry.sides then
        local levels=math.max(1,math.floor(size.Y/1.55))
        for level=1,levels do
            local y=(level-(levels+1)/2)*1.55
            for _,sign in {-1,1} do
                for x=1,columns do
                    checkStud(cf*CFrame.new((x-(columns+1)/2)*1.55,y,sign*(size.Z/2+.07))*CFrame.Angles(math.pi/2,0,0),entry.color,entry.studGroup)
                end
                for z=1,rows do
                    checkStud(cf*CFrame.new(sign*(size.X/2+.07),y,(z-(rows+1)/2)*1.55)*CFrame.Angles(0,0,math.pi/2),entry.color,entry.studGroup)
                end
            end
        end
    end
end end
assert(next(studs)==nil,'Unexpected lighthouse studs outside the baseline')
assert(candidates==693 and culled==365 and kept==328 and studCount==328,'Unexpected lighthouse stud reduction')
return 'PASS lighthouse 744 -> 379 Parts: 365 enclosed top studs removed; 328 exposed/side studs, 51 body Parts, 22 colliders, glass/door/light preserved'
