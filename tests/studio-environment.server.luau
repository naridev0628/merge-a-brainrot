-- Run in a fresh Studio server after the generated world is ready.
local root=assert(workspace:FindFirstChild('MergeABrainrotGenerated'))
local Config=require(game.ReplicatedStorage.Shared.Config)
local Map=require(game.ReplicatedStorage.Shared.MapSpec)
local TextStyle=require(game.ReplicatedStorage.Shared.TextStyle)
local function matchesColor(a: Color3,b: Color3): boolean
    -- BasePart colors are stored in 8-bit channels.
    return math.abs(a.R-b.R)<=1/255 and math.abs(a.G-b.G)<=1/255 and math.abs(a.B-b.B)<=1/255
end
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
        local passKey=p.Name:match('^Pass_(.+)$')
        local isPassPad=passKey~=nil and Map.PassPads[passKey]~=nil
        if p:IsA('BasePart') and (p.Name:match('^Buy%d+$') or isPassPad or p.Name=='DepositPad' or p.Name=='CoinPad' or p.Name=='UpgradePad' or p.Name=='FinishNowPad' or p.Name=='MergePad' or p.Name=='GroupRewardPad') then
            local lo,hi=footprint(p,frame);table.insert(protected,{lo=lo,hi=hi,name=p.Name})
        end
    end
    local s=Map.PlotScale
    local displayHalfWidth=(Config.Columns*Config.ColumnSpacing+1)/2
    table.insert(protected,{lo=Vector3.new(-displayHalfWidth,0,Config.DisplayZ-4)*s,hi=Vector3.new(displayHalfWidth,0,Config.DisplayZ+4)*s,name='Producer rows'})
    table.insert(protected,{lo=Vector3.new(-52,0,Config.BeltZ-5)*s,hi=Vector3.new(52,0,Config.BeltZ+5)*s,name='Conveyor lanes'})
    for i,a in protected do for j=i+1,#protected do
        local b=protected[j]
        assert(a.hi.X<=b.lo.X-.15 or a.lo.X>=b.hi.X+.15 or a.hi.Z<=b.lo.Z-.15 or a.lo.Z>=b.hi.Z+.15,a.name..' overlaps '..b.name)
    end end
    local trayLo,trayHi=footprint(plot.CollectionTray,frame)
    for _,zone in protected do
        if zone.name=='Conveyor lanes' then continue end
        assert(trayHi.X<=zone.lo.X-.15 or trayLo.X>=zone.hi.X+.15 or trayHi.Z<=zone.lo.Z-.15 or trayLo.Z>=zone.hi.Z+.15,'Collection tray overlaps '..zone.name)
    end
    local frontLo,frontHi=footprint(plot.StuddedLawn,frame)
    local rearLo,rearHi=footprint(plot.WideFarmRear,frame)
    assert(math.abs(frontHi.Z-rearLo.Z)<.01,'Lawn must connect to rear bank without a gap')
    assert(math.abs(rearHi.Z-Config.PlotBackZ*s)<.01 and math.abs(frontLo.Z+38*s)<.01,'Expanded plot must retain its front edge and reach the back wall')
    assert(Config.BuyZ-Map.Spawn.Position.Z>=35,'Purchase row must leave an open forecourt')
    local chuteLo,chuteHi=footprint(plot.ConveyorCenter,frame)
    local beltLo=footprint(plot.ConveyorBelt,frame)
    assert(chuteLo.Z<=trayHi.Z+.01 and chuteHi.Z>=beltLo.Z-.01,'Tray and conveyor must have a continuous center chute')
    for _,quantity in {'1','5','10','50'} do
        local title=plot['Buy'..quantity].Label.Text
        assert(title.Font==Enum.Font.FredokaOne and title.TextSize>=30 and title:FindFirstChildOfClass('UIStroke'),'Purchase title needs a bold rounded outline')
        assert(title.Parent.Price.Position.Y.Offset>=title.Size.Y.Offset-2,'Purchase price must remain below its title')
    end
    for _,name in {'Buy1','Buy5','Buy10','Buy50','UpgradePad','CoinPad'} do
        local gui=plot[name].Label
        local title,price=gui.Text,assert(gui:FindFirstChild('Price'),name..' needs a separate value line')
        assert(title.TextColor3==TextStyle.Cream,name..' action must remain cream')
        assert(price.Position.Y.Offset>=title.Size.Y.Offset,name..' value must not overlap its action')
        assert(price.TextSize>=title.TextSize,name..' value must have stronger hierarchy')
        assert(title:FindFirstChild('TextOutline') and price:FindFirstChild('TextOutline'),'World text must use the shared outlined style')
    end
    local processor=plot.ProcessorSign.Processor
    local display=processor.ProcessorDisplay
    assert(display.SizingMode==Enum.SurfaceGuiSizingMode.FixedSize,'Board canvas must retain its authored text layout')
    assert(not display:FindFirstChild('FriendBoost'),'Do not advertise an unimplemented friend boost')
    assert(display.Queued.Text~='' and display.Rate.Text~='','Processor status and rate must be readable')
    local face=display.Adornee
    assert(face and face:IsA('BasePart'),'Processor board needs an explicit text face')
    local front=processor.CFrame:PointToObjectSpace(face.Position)
    assert(front.Z<-processor.Size.Z/2-.08*s,'Board text must clear the studded front surface')
    local group=plot.GroupRewardBoard
    local groupDisplay=group.GroupRewardDisplay
    assert(not groupDisplay.AlwaysOnTop and groupDisplay.Adornee==plot.GroupRewardTextFace,'Group board must use the verified world-space render path')
    local groupFront=group.CFrame:PointToObjectSpace(groupDisplay.Adornee.Position)
    assert(groupFront.Z<-group.Size.Z/2-.16*s,'Group board text must clear every raised wood stud')
    for _,name in {'Buy1','Buy5','Buy10','Buy50','UpgradePad'} do
        local pad=plot[name]
        local affordable=pad:GetAttribute('Affordable')
        if affordable~=nil then
            local color=if affordable then Color3.fromRGB(96,238,43) else Color3.fromRGB(244,90,94)
            assert(pad.Color==color,name..' must show its current affordability')
            for _,detail in plot:GetChildren() do
                if detail.Name==name..'Stud' then assert(matchesColor(detail.Color,color:Lerp(Color3.new(1,1,1),.12)),'Stud affordability color is stale')
                elseif detail.Name==name..'Edge' then assert(matchesColor(detail.Color,color:Lerp(Color3.new(1,1,1),.3)),'Trim affordability color is stale') end
            end
        end
    end
    local farmer=assert(plot.DepositBooth:FindFirstChild('Shopkeeper'))
    assert(math.abs(farmer.Size.Y-5.5)<.01,'Farmer must be avatar height in world studs')
    for _,row in plot.StackRows:GetChildren() do for _,part in row:GetChildren() do
        if part.Name=='DisplayPlatform' then
            assert(math.abs(part.Size.Y-Config.DisplayPlatformHeight*s)<.01,'Producer stands must retain their raised thickness')
            assert(part.Size.X>=8.8*s-.01,'Widened bays need a broad stand under each unchanged-size producer')
        elseif part.Name=='ShelfBase' then
            assert(part.Size.X>=plot.WideFarmRear.Size.X*.88 and part.Size.X<=plot.WideFarmRear.Size.X-8*s,'Producer row must span the rear bank with fence clearance')
        end
    end end
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
