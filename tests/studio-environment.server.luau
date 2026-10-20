-- Run in a fresh Studio server after the generated world is ready.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local Config=require(game.ReplicatedStorage.Shared.Config)
local Map=require(game.ReplicatedStorage.Shared.MapSpec)
local function footprint(part: BasePart,frame: CFrame)
    local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        local p=frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))
        lo=lo:Min(p);hi=hi:Max(p)
    end end end
    return lo,hi
end
local baseline
for id=1,Config.PlotCount do
    local plot=assert(root:FindFirstChild('Plot'..id))
    local decor=assert(plot:FindFirstChild('PlotDecor'),'Missing shared plot decoration layout')
    local frame=plot:GetPivot()
    local protected={}
    for _,p in plot:GetChildren() do
        if p:IsA('BasePart') and (p.Name:match('^Buy%d+$') or p.Name:match('^Pass_') or p.Name=='DepositPad' or p.Name=='CoinPad' or p.Name=='UpgradePad' or p.Name=='FinishNowPad' or p.Name=='MergePad' or p.Name=='GroupRewardPad') then
            local lo,hi=footprint(p,frame);table.insert(protected,{lo=lo,hi=hi,name=p.Name})
        end
    end
    local s=Map.PlotScale
    table.insert(protected,{lo=Vector3.new(-34,0,62)*s,hi=Vector3.new(34,0,70)*s,name='Producer rows'})
    table.insert(protected,{lo=Vector3.new(-52,0,50)*s,hi=Vector3.new(52,0,60)*s,name='Conveyor lanes'})
    local signatures={}
    for _,p in decor:GetDescendants() do if p:IsA('BasePart') then
        local lo,hi=footprint(p,frame)
        for _,zone in protected do
            assert(hi.X<=zone.lo.X-.15 or lo.X>=zone.hi.X+.15 or hi.Z<=zone.lo.Z-.15 or lo.Z>=zone.hi.Z+.15,p:GetFullName()..' overlaps '..zone.name)
        end
        local values={frame:ToObjectSpace(p.CFrame):GetComponents()}
        table.insert(values,p.Size.X);table.insert(values,p.Size.Y);table.insert(values,p.Size.Z)
        table.insert(signatures,{name=p.Name,color=p.Color,values=values})
    end end
    if baseline then
        assert(#signatures==#baseline,'Decoration counts differ')
        for i,part in signatures do
            assert(part.name==baseline[i].name and part.color==baseline[i].color,'Decoration identity differs')
            for j,value in part.values do assert(math.abs(value-baseline[i].values[j])<.001,'Decoration layout differs on plot '..id) end
        end
    else baseline=signatures end
    local anchor=plot.OwnerBadgeAnchor
    local position=frame:PointToObjectSpace(anchor.Position)/s
    assert(position.Y>=40 and math.abs(position.Z-Config.DisplayZ)<.01,'Badge must sit high above the rear display')
end
local lily,rocks=0,0
for _,p in root:GetChildren() do
    if p.Name=='BrickLilyPad' or p.Name=='BrickRockIsland' then
        assert(p:IsA('MeshPart') and p.Anchored and p.CanCollide and p.CanQuery,'Water props must support players')
        if p.Name=='BrickLilyPad' then lily+=1 else rocks+=1 end
    end
end
assert(lily==30 and rocks==3)
print('PASS: identical decoration on six plots; pads, conveyors and producer rows clear; raised rear badges; 30 jumpable lilies and three rock islands')
