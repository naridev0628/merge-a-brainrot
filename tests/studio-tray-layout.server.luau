-- Read-only native acceptance after a fresh world build. Safe during normal Play.
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Map=require(Shared.MapSpec)
local generated=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local function bounds(part,frame)
    local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        local p=frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))/Map.PlotScale
        lo=lo:Min(p);hi=hi:Max(p)
    end end end
    return lo,hi
end
local function close(actual,expected,message)
    assert(math.abs(actual-expected)<.01,message..': '..actual..' expected '..expected)
end
local function inert(part)
    assert(part.Anchored and not part.CanCollide and not part.CanTouch,part.Name..' must stay decorative')
end
for id=1,6 do
    local plot=assert(generated:FindFirstChild('Plot'..id))
    local frame=plot:GetPivot()
    local floor=plot.CollectionTray
    local lo,hi=bounds(floor,frame)
    close(hi.X-lo.X,24,'The collection floor must widen')
    close(hi.Z-lo.Z,16,'The collection floor must deepen')
    close((hi.Z+lo.Z)/2,67,'Keep the tray centered')
    close(hi.Y,.65,'Preserve the red floor height')
    assert(floor.Anchored and floor.CanCollide and not floor.CanTouch,'Reviewed tray must support standing players')
    assert(floor.TopSurface==Enum.SurfaceType.Studs)
    local padBases={}
    for _,name in {'Buy5Base','Buy10Base','MergePadBase'} do
        local part=assert(plot:FindFirstChild(name))
        local a,b=bounds(part,frame)
        table.insert(padBases,{name=name,lo=a,hi=b})
        inert(part)
    end
    for _,spec in {{'Buy1',Config.BuyPads['1'],Config.BuyZ},{'Buy5',Config.BuyPads['5'],Config.BuyZ},
        {'Buy10',Config.BuyPads['10'],Config.BuyZ},{'Buy100',Config.BuyPads['100'],Config.BuyZ},{'MergePad',Config.MergeX,Config.MergeZ}} do
        local p=frame:PointToObjectSpace(plot[spec[1]].Position)/Map.PlotScale
        close(p.X,spec[2],spec[1]..' X');close(p.Z,spec[3],spec[1]..' Z')
    end
    local trayParts={floor}
    local studCount,rimCount,railCount=0,0,0
    for _,part in plot:GetChildren() do
        if part.Name=='TrayStud' then
            studCount+=1;inert(part);table.insert(trayParts,part)
            local a,b=bounds(part,frame)
            assert(a.X>=lo.X+.5 and b.X<=hi.X-.5 and a.Z>=lo.Z+.5 and b.Z<=hi.Z-.5)
        elseif part.Name=='TrayRim' then
            rimCount+=1;table.insert(trayParts,part)
            local a,b=bounds(part,frame)
            close(math.abs((a.X+b.X)/2),12,'Side rim position')
            close(a.Z,59,'Side rim front');close(b.Z,73,'Side rim must stop before the belt')
            close(b.Y,1.2,'Preserve side collision height')
            assert(part.CanCollide and not part.CanTouch and part.Anchored)
        elseif part.Name=='ConveyorFrontRail' then
            railCount+=1
            local a,b=bounds(part,frame)
            close(b.X-a.X,Map.ConveyorWidth/2-12,'Rails must span the wider conveyor')
            close(math.min(math.abs(a.X),math.abs(b.X)),12,'Rail inner end')
            close(math.max(math.abs(a.X),math.abs(b.X)),Map.ConveyorWidth/2,'Rail outer end')
            assert(part.CanCollide and not part.CanTouch and part.Anchored)
        end
    end
    assert(studCount==35 and rimCount==2 and railCount==2,'Keep bounded tray accents and existing collision part counts')
    local front=plot.TrayFront
    table.insert(trayParts,front)
    local a,b=bounds(front,frame)
    close(b.X-a.X,24,'Front rim span');close((a.Z+b.Z)/2,59,'Front rim position')
    close(b.Y,1,'Preserve front collision height')
    assert(front.CanCollide and not front.CanTouch and front.Anchored)
    local facade=plot.ConveyorFacade
    local facadeCount,brickCourses=0,0
    for _,part in facade:GetDescendants() do
        if not part:IsA('BasePart') then continue end
        facadeCount+=1
        if part.Name=='SkirtBrickCourse' then brickCourses+=1 end
        if part.Name:match('^Tray') then
            table.insert(trayParts,part);inert(part);assert(not part.CanQuery)
            local a,b=bounds(part,frame)
            if part.Name:match('^TraySide') or part.Name=='TrayCornerCap' then
                assert(b.Z<=73.01,'Raised rear trim must leave the full red belt open')
            end
        end
    end
    assert(facadeCount>=213 and facadeCount<=360 and brickCourses==6,'Reviewed skirts need bounded detail and three brick courses per side')
    -- Include every visible base/trim overhang, not only the red floor/pad surfaces.
    for _,part in trayParts do
        local a,b=bounds(part,frame)
        for _,pad in padBases do
            local gap=math.max(pad.lo.X-b.X,a.X-pad.hi.X,pad.lo.Z-b.Z,a.Z-pad.hi.Z)
            assert(gap>=2.4-.01,part.Name..' narrows the walking approach beside '..pad.name)
        end
    end
    -- The center plate and four shallow chute facets must join the collidable
    -- tray without leaving a hole in the red walking surface.
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    local centerSurfaces={plot.ConveyorCenter,floor}
    for _,part in plot:GetChildren() do if part.Name=='ConveyorChuteSlope' then table.insert(centerSurfaces,part) end end
    params.FilterDescendantsInstances=centerSurfaces
    params.RespectCanCollide=true
    for z=73.1,80.9,.3 do
        assert(workspace:Raycast(frame:PointToWorldSpace(Vector3.new(0,10,z)*Map.PlotScale),
            Vector3.new(0,-12,0),params),'Center belt collision has a hole at '..z)
    end
    assert(not plot:FindFirstChild('Pass_autoCollect'),'Removed Auto Collect placeholder must stay absent')
    close(Config.MergeZ,52,'Merge uses the old Auto Collect position')
    close(Config.LuckyZ,65,'Lucky outside-edge pickup target')
end
return 'PASS six collidable 24x16 trays, 35 accents, bounded brick facades, clear walking gaps, current pad targets and complete center/chute collision'
