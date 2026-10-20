-- Run in a fresh Studio server after the generated world is ready.
-- Catches decorative geometry that obstructs Mini travel, producers, or pads.
local Config=require(game.ReplicatedStorage.Shared.Config)
local Map=require(game.ReplicatedStorage.Shared.MapSpec)
local Motion=require(game.ReplicatedStorage.Shared.MiniMotion)
local generated=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))

local function bounds(part: BasePart,frame: CFrame,scale: number): (Vector3,Vector3)
    local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        local point=frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))/scale
        lo=lo:Min(point);hi=hi:Max(point)
    end end end
    return lo,hi
end

local function overlaps(lo: Vector3,hi: Vector3,a: Vector3,b: Vector3): boolean
    return lo.X<b.X-.01 and hi.X>a.X+.01 and lo.Y<b.Y-.01 and hi.Y>a.Y+.01 and lo.Z<b.Z-.01 and hi.Z>a.Z+.01
end

for id=1,Config.PlotCount do
    local plot=assert(generated:FindFirstChild('Plot'..id))
    local facade=assert(plot:FindFirstChild('ConveyorFacade'),'Missing facade on plot '..id)
    local frame=plot:GetPivot()
    local scale=Map.PlotScale
    local parts={}
    local protected={
        {name='red belt',lo=Vector3.new(-51.5,.6,Config.BeltZ-4),hi=Vector3.new(51.5,5,Config.BeltZ+4)},
        {name='collection tray',lo=Vector3.new(-7.5,.6,Config.TrayZ-5.4),hi=Vector3.new(7.5,5,Config.TrayZ+5.8)},
        {name='center chute',lo=Vector3.new(-7,.6,Config.TrayZ+5.5),hi=Vector3.new(7,5,Config.BeltZ+4)},
        {name='producer standing space',lo=Vector3.new(-50.5,Config.DisplayPlatformHeight+.15,Config.DisplayZ-3.6),hi=Vector3.new(50.5,Config.RowHeight*5,Config.DisplayZ+3.6)},
    }
    for _,child in plot:GetChildren() do
        if child:IsA('BasePart') and (child.Name:match('^Buy%d+$') or child.Name:match('^Pass_') or child.Name=='MergePad') then
            local lo,hi=bounds(child,frame,scale)
            table.insert(protected,{name=child.Name,lo=Vector3.new(lo.X,0,lo.Z),hi=Vector3.new(hi.X,5,hi.Z)})
        end
    end
    for _,child in facade:GetDescendants() do
        if child:IsA('BasePart') then
            table.insert(parts,child)
            assert(child.Anchored and not child.CanCollide and not child.CanTouch and not child.CanQuery,child.Name..' must remain decoration only')
            local lo,hi=bounds(child,frame,scale)
            for _,zone in protected do
                assert(not overlaps(lo,hi,zone.lo,zone.hi),child.Name..' obstructs '..zone.name)
            end
        end
    end
    assert(#parts>0 and #parts<220,'Facade must stay below 220 parts per plot')

    -- Sample real shared trajectories from both ends, every bay, and each row.
    -- A misplaced fascia should fail even if it is noncollidable.
    for row=0,4 do for column=1,Config.Columns do
        local token={
            startX=(column-(Config.Columns+1)/2)*Config.ColumnSpacing,
            startY=Config.DisplayPlatformHeight+row*Config.RowHeight+1,
            startZ=Config.DisplayZ-2,
            x=0,y=1.3,z=Config.TrayZ,spawnedAt=0,readyAt=Config.TransitSeconds,
        }
        for step=0,40 do
            local position=assert(Motion.position(Config,token,Config.TransitSeconds*step/40))
            local point=frame:PointToWorldSpace(Vector3.new(position.x,position.y,position.z)*scale)
            for _,part in parts do
                local localPoint=part.CFrame:PointToObjectSpace(point)
                local half=part.Size/2+Vector3.one*(.12*scale)
                assert(math.abs(localPoint.X)>half.X or math.abs(localPoint.Y)>half.Y or math.abs(localPoint.Z)>half.Z,part.Name..' clips a moving Mini')
            end
        end
    end end
end
print('PASS: six decorative conveyor facades stay below budget and clear pads, producer bays, red surfaces and Mini trajectories')
