--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Factory=require(Shared.ModelFactory)
local Map=require(Shared.MapSpec)
local Catalog=require(Shared.CreatureCatalog)
local Config=require(Shared.Config)
local PassConfig=require(Shared.PassConfig)
local Core=require(script.Parent.Parent.Domain.FarmCore)
local layout=Core.new(Config,Catalog)
local World={}
local orange=Color3.fromRGB(255,174,22)
local function placeScaled(model: Model,transform: CFrame)
    local pivot=model:GetPivot()
    model:ScaleTo(model:GetScale()*Map.PlotScale)
    model:PivotTo(transform*CFrame.new(pivot.Position*Map.PlotScale)*pivot.Rotation)
end
local function point(world: any,value: Vector3): Vector3
    return world.frame:PointToWorldSpace(value*Map.PlotScale)
end
local function pad(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3)
    Factory.part(parent,name..'Base',size+Vector3.new(.5,.15,.5),cf-Vector3.new(0,.17,0),Color3.fromRGB(128,79,29))
    local p=Factory.part(parent,name,size,cf,color); p.TopSurface=Enum.SurfaceType.Studs
    for x=-size.X/2+1,size.X/2-1,2 do for z=-size.Z/2+1,size.Z/2-1,2 do
        Factory.part(parent,name..'Stud',Vector3.new(.65,.12,.65),cf*CFrame.new(x,size.Y/2+.06,z),color)
    end end
    return p
end
local function fence(parent: Instance,cf: CFrame,length: number)
    local wood=Color3.fromRGB(171,111,65)
    for _,y in {1.7,4.1} do
        Factory.part(parent,'FenceRail',Vector3.new(length,.85,.55),cf*CFrame.new(0,y,0),wood)
        Factory.part(parent,'RailTopHighlight',Vector3.new(length,.12,.62),cf*CFrame.new(0,y+.46,0),Color3.fromRGB(204,147,92))
        for x=-length/2+1.8,length/2-1.8,3 do
            for _,side in {-1,1} do Factory.part(parent,'FenceStud',Vector3.new(.75,.65,.17),cf*CFrame.new(x,y,side*.34),Color3.fromRGB(202,146,93)) end
        end
    end
    local count=math.ceil(length/16)
    for index=0,count do
        local x=-length/2+index*length/count
        local post=Factory.part(parent,'FencePost',Vector3.new(1.5,5.7,1.5),cf*CFrame.new(x,2.85,0),Color3.fromRGB(112,67,37)); post.TopSurface=Enum.SurfaceType.Studs
        Factory.part(parent,'PostCap',Vector3.new(1.8,.35,1.8),cf*CFrame.new(x,5.85,0),Color3.fromRGB(151,92,48))
        for _,y in {1.7,4.1} do Factory.part(parent,'PostPeg',Vector3.new(.38,.38,.16),cf*CFrame.new(x,y,-.84),Color3.fromRGB(91,51,27)) end
    end
    local barrier=Factory.part(parent,'FenceBarrier',Vector3.new(length,8,.8),cf*CFrame.new(0,4,0),wood,nil,true);barrier.Transparency=1
end
local function buildPlot(parent: Instance,id: number,transform: CFrame)
    local root=Instance.new('Model'); root.Name='Plot'..id; root.WorldPivot=CFrame.identity
    local lawn=Factory.part(root,'StuddedLawn',Vector3.new(112,1,112),CFrame.new(0,-.5,18),Color3.fromRGB(114,210,37),nil,true)
    lawn.TopSurface=Enum.SurfaceType.Studs
    for x=-54,54,4 do for z=-36,72,4 do Factory.part(root,'LawnStud',Vector3.new(1,.12,1),CFrame.new(x,.06,z),Color3.fromRGB(124,217,37)) end end
    for _,x in {-56,56} do fence(root,CFrame.new(x,0,18)*CFrame.Angles(0,math.pi/2,0),112) end
    for _,x in {-32,32} do fence(root,CFrame.new(x,0,-38),48) end
    local back=Factory.part(root,'BackWall',Vector3.new(112,5,1.5),CFrame.new(0,2.5,74),orange,nil,true); back.TopSurface=Enum.SurfaceType.Studs
    local pads={}
    for _,quantity in {'1','5','10','100'} do
        local purchase=pad(root,'Buy'..quantity,Vector3.new(10,.4,7),CFrame.new(Config.BuyPads[quantity],.2,Config.BuyZ),if quantity=='1' then Color3.fromRGB(96,238,43) else Color3.fromRGB(244,90,94))
        pads[quantity]=Factory.label(purchase,'BUY '..quantity,130,64); pads[quantity].TextSize=17
    end
    local deposit=pad(root,'DepositPad',Vector3.new(14,.4,10),CFrame.new(Map.Sell),Color3.fromRGB(255,223,45))
    local depositLabel=Factory.label(deposit,'Deposit Minis',135,30);depositLabel.TextSize=16;depositLabel.Parent.StudsOffset=Vector3.new(0,1.1,0)
    for _,side in {-1,1} do
        local a=Factory.part(root,'DepositGlow',Vector3.new(14.3,.08,.15),CFrame.new(Map.Sell+Vector3.new(0,.25,side*5)),Color3.fromRGB(255,255,90));a.Material=Enum.Material.Neon
        local b=Factory.part(root,'DepositGlow',Vector3.new(.15,.08,10),CFrame.new(Map.Sell+Vector3.new(side*7,.25,0)),Color3.fromRGB(255,255,90));b.Material=Enum.Material.Neon
    end
    local glow=Instance.new('PointLight');glow.Color=Color3.fromRGB(255,230,65);glow.Brightness=1.2;glow.Range=8;glow.Parent=deposit
    local booth=Instance.new('Model'); booth.Name='DepositBooth'; booth.Parent=root
    for _,dx in {-6,6} do Factory.part(booth,'BoothPost',Vector3.new(.8,8,.8),CFrame.new(-30+dx,4,-4),Color3.fromRGB(115,73,39)) end
    for stripe=1,8 do
        local awning=Factory.part(booth,'Awning',Vector3.new(1.7,.6,7),CFrame.new(-37.65+stripe*1.7,8,-3),if stripe%2==0 then Color3.fromRGB(255,240,208) else Color3.fromRGB(243,87,85)); awning.TopSurface=Enum.SurfaceType.Studs
    end
    Factory.part(booth,'Counter',Vector3.new(13,.6,3),CFrame.new(-30,2.8,-5),Color3.fromRGB(134,82,36))
    Factory.prop(booth,'Shopkeeper',CFrame.new(-30,0,-2),.95)
    local boothFrame=CFrame.new(43,0,12)*CFrame.Angles(0,math.pi/2,0)*CFrame.new(30,0,3)
    for _,part in booth:GetDescendants() do if part:IsA('BasePart') then part.CFrame=boothFrame*part.CFrame end end
    -- A readable sign replaces the bulky processor machine.
    for _,x in {-43,-25} do Factory.part(root,'ProcessorPost',Vector3.new(.7,8,.7),CFrame.new(x,4,29),Color3.fromRGB(102,65,34)) end
    local processor=Factory.part(root,'Processor',Vector3.new(23,10,1),CFrame.new(-34,9,29),Color3.fromRGB(143,94,49),nil,true)
    for _,side in {-1,1} do
        for x=-10,10,1.6 do for y=-4,4,1.6 do Factory.part(root,'SignStud',Vector3.new(.72,.72,.16),CFrame.new(-34+x,9+y,29+side*.56),Color3.fromRGB(181,126,78)) end end
    end
    for _,y in {3.8,14.2} do Factory.part(root,'SignFrame',Vector3.new(23.6,.55,1.4),CFrame.new(-34,y,29),Color3.fromRGB(103,61,31)) end
    for _,x in {-45.7,-22.3} do Factory.part(root,'SignFrame',Vector3.new(.55,10.4,1.4),CFrame.new(x,9,29),Color3.fromRGB(103,61,31)) end
    local textFace=Factory.part(root,'ProcessorTextFace',Vector3.new(23,10,.02),CFrame.new(-34,9,28.3),Color3.new(1,1,1));textFace.Transparency=1;textFace.CanQuery=false
    local surface=Instance.new('SurfaceGui'); surface.Name='ProcessorDisplay'; surface.Adornee=textFace; surface.Face=Enum.NormalId.Front; surface.CanvasSize=Vector2.new(690,300); surface.Parent=processor
    local function signLine(name: string,value: string,y: number,height: number,size: number,color: Color3)
        local label=Instance.new('TextLabel');label.Name=name;label.Text=value;label.Position=UDim2.fromOffset(0,y);label.Size=UDim2.new(1,0,0,height);label.BackgroundTransparency=1;label.Font=Enum.Font.FredokaOne;label.TextSize=size;label.TextColor3=color;label.TextStrokeTransparency=0;label.TextStrokeColor3=Color3.fromRGB(30,19,14);label.Parent=surface
        local stroke=Instance.new('UIStroke');stroke.Thickness=2;stroke.Color=label.TextStrokeColor3;stroke.Parent=label
        return label
    end
    signLine('Title','Selling Brainrots',18,53,46,Color3.fromRGB(255,236,242))
    signLine('FriendBoost','(No Friend Boost)',72,32,28,Color3.fromRGB(83,207,255))
    local processorLabel=signLine('Queued','0',100,116,102,Color3.fromRGB(255,231,183))
    local processorRate=signLine('Rate','2 per second',220,52,40,Color3.fromRGB(255,231,202))
    local upgrade=pad(root,'UpgradePad',Vector3.new(11,.4,7),CFrame.new(Map.Upgrade),Color3.fromRGB(95,245,70))
    local upgradeLabel=Factory.label(upgrade,'UPGRADE PROCESSOR\n100 Coins',190,55)
    local finish=pad(root,'FinishNowPad',Vector3.new(10,.4,7),CFrame.new(Map.FinishNow),Color3.fromRGB(255,213,35)); finish:SetAttribute('ProductKey','finishNow')
    Factory.label(finish,'Finish now\nComing soon',140,52)
    for key,position in Map.PassPads do
        local passPad=pad(root,'Pass_'..key,Vector3.new(8,.4,6),CFrame.new(position),Color3.fromRGB(255,222,35))
        passPad:SetAttribute('PassKey',key); local label=Factory.label(passPad,PassConfig[key].name..'\nComing soon',125,54); label.TextSize=14; label.Parent.MaxDistance=26
    end
    local claim=pad(root,'CoinPad',Vector3.new(15,.4,10),CFrame.new(Map.Claim),Color3.fromRGB(107,234,82))
    local saleLabel=Factory.label(claim,'Collect cash\n$0',155,50);saleLabel.TextColor3=Color3.fromRGB(130,255,44);saleLabel.TextSize=20
    local merge=pad(root,'MergePad',Vector3.new(10,.4,7),CFrame.new(Map.Merge),Color3.fromRGB(252,219,50))
    Factory.label(merge,'MERGE',140,44)
    local sign=Factory.part(root,'OwnerSign',Vector3.new(14,4,1),CFrame.new(0,4,72),Color3.fromRGB(157,91,31))
    local ownerLabel=Factory.label(sign,'BRAINROT FARM',260,58)
    local badgePart=Factory.part(root,'OwnerBadgeAnchor',Vector3.one,CFrame.new(0,24,-14),orange); badgePart.Transparency=1
    local badge=Instance.new('BillboardGui'); badge.Name='OwnerBadge'; badge.Size=UDim2.fromOffset(220,120); badge.MaxDistance=500; badge.AlwaysOnTop=true; badge.Parent=badgePart
    local portrait=Instance.new('ImageLabel'); portrait.Name='Portrait'; portrait.BackgroundColor3=Color3.fromRGB(80,160,250); portrait.Size=UDim2.fromOffset(76,76); portrait.Position=UDim2.new(.5,-38,0,0); portrait.Parent=badge
    local round=Instance.new('UICorner'); round.CornerRadius=UDim.new(1,0); round.Parent=portrait
    local rim=Instance.new('UIStroke'); rim.Thickness=3; rim.Color=Color3.new(0,0,0); rim.Parent=portrait
    local ownerName=Instance.new('TextLabel'); ownerName.Name='Username'; ownerName.Size=UDim2.new(1,0,0,40); ownerName.Position=UDim2.fromOffset(0,78); ownerName.BackgroundTransparency=1
    ownerName.Font=Enum.Font.FredokaOne; ownerName.TextSize=20; ownerName.TextColor3=Color3.new(1,1,1); ownerName.TextStrokeTransparency=0; ownerName.Text='Available plot'; ownerName.Parent=badge
    portrait.Visible=false
    -- Two red lanes converge at the center, then feed a gold-rimmed collection tray.
    local belt=Factory.part(root,'ConveyorBelt',Vector3.new(102,.4,8),CFrame.new(0,.5,Config.BeltZ),Color3.fromRGB(222,61,62),nil,true); belt.TopSurface=Enum.SurfaceType.Studs
    Factory.part(root,'ConveyorBackRail',Vector3.new(104,1,1),CFrame.new(0,.9,Config.BeltZ+4.6),orange,nil,true)
    for _,x in {-30,30} do Factory.part(root,'ConveyorFrontRail',Vector3.new(44,1,1),CFrame.new(x,.9,Config.BeltZ-4.6),orange,nil,true) end
    Factory.part(root,'ConveyorCenter',Vector3.new(14,.4,12),CFrame.new(0,.5,49),Color3.fromRGB(222,61,62))
    Factory.part(root,'CollectionTray',Vector3.new(16,.4,12),CFrame.new(0,.45,Config.TrayZ),Color3.fromRGB(239,95,71))
    for _,x in {-8,8} do Factory.part(root,'TrayRim',Vector3.new(.7,.8,12),CFrame.new(x,.8,Config.TrayZ),orange,nil,true) end
    Factory.part(root,'TrayFront',Vector3.new(16,.6,.7),CFrame.new(0,.7,Config.TrayZ-6),orange,nil,true)
    belt.Transparency=1;belt.CanCollide=false
    for _,side in {-1,1} do
        local rampCF=CFrame.new(side*26,1.2,Config.BeltZ)*CFrame.Angles(0,0,side*.032)
        local ramp=Factory.part(root,'StuddedConveyorRamp',Vector3.new(51,.35,8),rampCF,Color3.fromRGB(222,61,62),nil,true);ramp.TopSurface=Enum.SurfaceType.Studs
        for x=-24,24,2 do for z=-3,3,2 do Factory.part(root,'ConveyorStud',Vector3.new(.5,.10,.5),rampCF*CFrame.new(x,.23,z),Color3.fromRGB(238,84,82)) end end
    end
    for _,x in {-51,51} do for _,z in {-24,65} do
        Factory.prop(root,'BrickTree',CFrame.new(x,0,z),1.15)
    end end
    for i,point in {Vector3.new(-47,0,-29),Vector3.new(28,0,-28),Vector3.new(49,0,42),Vector3.new(-48,0,43)} do
        Factory.prop(root,'BrickBush',CFrame.new(point)*CFrame.Angles(0,i*.8,0))
        Factory.prop(root,'BrickLog',CFrame.new(point+Vector3.new(4,0,2))*CFrame.Angles(0,i,0))
        for flower=1,3 do Factory.prop(root,'BrickFlower',CFrame.new(point+Vector3.new(flower*1.2,0,-3+(flower%2))),.8+flower*.1) end
        Factory.prop(root,'BrickGrass',CFrame.new(point+Vector3.new(-2,0,1)),1.2)
    end
    local barn=Factory.prop(root,'BrickBarn',CFrame.new(43,0,-27)*CFrame.Angles(0,-.25,0),.85)
    if barn then
        local roofGuest=Factory.producer(root,'BarnMascot',Catalog[string.format('tier_%02d',(id-1)%4+1)],Vector3.new(43,barn.Size.Y,-27),true)
        roofGuest:ScaleTo(1.2)
        local guestPivot=roofGuest:GetPivot()
        roofGuest:PivotTo(CFrame.lookAt(guestPivot.Position,Vector3.new(0,guestPivot.Position.Y,18)))
    end
    local spawn=Instance.new('SpawnLocation'); spawn.Name='FarmSpawn'; spawn.Anchored=true; spawn.Transparency=1
    spawn.CanCollide=false; spawn.CanTouch=false; spawn.Size=Vector3.new(6,1,6); spawn.CFrame=Map.Spawn; spawn.Neutral=true; spawn.Parent=root
    local producers=Instance.new('Folder'); producers.Name='Producers'; producers.Parent=root
    local tokens=Instance.new('Folder'); tokens.Name='Minis'; tokens.Parent=root
    local rows=Instance.new('Folder'); rows.Name='StackRows'; rows.Parent=root
    placeScaled(root,transform)
    root.Parent=parent; task.wait()
    local lighting=game:GetService('Lighting'); lighting.ClockTime=13; lighting.Brightness=2; lighting.Ambient=Color3.fromRGB(170,170,170)
    return {id=id,frame=transform,root=root,producers=producers,tokens=tokens,rows=rows,ownerLabel=ownerLabel,pads=pads,saleLabel=saleLabel,portrait=portrait,ownerName=ownerName,processorLabel=processorLabel,processorRate=processorRate,upgradeLabel=upgradeLabel,spawn=spawn}
end
function World.build()
    local old=workspace:FindFirstChild('MergeABrainrotGenerated'); if old then old:Destroy() end
    local root=Instance.new('Folder'); root.Name='MergeABrainrotGenerated'; root.Parent=workspace
    local water=Factory.part(root,'Water',Vector3.new(1000,1,1000),CFrame.new(0,-5,0),Color3.fromRGB(46,174,224),nil,true); water.Material=Enum.Material.Glass; water.Transparency=.15
    local plaza=Factory.part(root,'CentralPlaza',Vector3.new(440,1,94),CFrame.new(0,-.5,0),Color3.fromRGB(115,210,38),nil,true); plaza.TopSurface=Enum.SurfaceType.Studs
    local plots={}
    for _,z in {126,-126} do for _,x in {-120,0,120} do
        local transform=CFrame.new(x,0,z)*(if z<0 then CFrame.Angles(0,math.pi,0) else CFrame.new())
        table.insert(plots,buildPlot(root,#plots+1,transform))
        local bridge=Factory.part(root,'Bridge',Vector3.new(14,1,64),CFrame.new(x,-.2,if z>0 then 77 else -77),Color3.fromRGB(162,111,63),nil,true); bridge.TopSurface=Enum.SurfaceType.Studs
        local bridgeMesh=Factory.prop(root,'BrickBridge',CFrame.new(x,-.1,if z>0 then 77 else -77))
        if bridgeMesh then bridge.Transparency=1 end
        for _,side in {-1,1} do local rail=Factory.part(root,'BridgeBarrier',Vector3.new(.6,4,64),bridge.CFrame*CFrame.new(side*6.8,2.2,0),orange,nil,true); rail.Transparency=1 end
        for i=1,4 do Factory.prop(root,'BrickLilyPad',CFrame.new(x+(if i%2==0 then -1 else 1)*(15+i*5),-4.38,if z>0 then 55+i*10 else -55-i*10)*CFrame.Angles(0,i*1.6,0),.8+i*.22) end
    end end
    local boards={}
    local circle=Factory.part(root,'GatheringCircle',Vector3.new(.3,68,68),CFrame.new(0,.15,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(255,192,98),Enum.PartType.Cylinder,true)
    circle.TopSurface=Enum.SurfaceType.Studs
    for i=1,10 do
        local angle=i*.7
        local block=Factory.part(root,'ParkourStep'..i,Vector3.new(5,1,5),CFrame.new(math.cos(angle)*14,i*3,math.sin(angle)*14),orange,nil,true); block.TopSurface=Enum.SurfaceType.Studs
    end
    Factory.part(root,'ParkourFinish',Vector3.new(9,1,9),CFrame.new(math.cos(7)*7,33,math.sin(7)*7),Color3.fromRGB(255,225,41),nil,true)
    for _,x in {-190,-110,-65,65,110,190} do for _,z in {-30,30} do
        Factory.prop(root,'BrickTree',CFrame.new(x,0,z),.9)
        for flower=1,3 do
            local px=x+5+flower*2
            Factory.prop(root,'BrickFlower',CFrame.new(px,0,z+5),.8+flower*.1)
        end
    end end
    for index,position in {Vector3.new(-67,-4.4,86),Vector3.new(67,-4.4,-86),Vector3.new(190,-4.4,112)} do
        Factory.prop(root,'BrickRockIsland',CFrame.new(position)*CFrame.Angles(0,index*.9,0),1.25)
        Factory.prop(root,'BrickLilyPad',CFrame.new(position+Vector3.new(10,0,4)),1.2)
        Factory.prop(root,'BrickLilyPad',CFrame.new(position+Vector3.new(-6,0,-8)),.9)
    end
    for index,position in {Vector3.new(-155,0,22),Vector3.new(155,0,-24)} do
        local facing=CFrame.Angles(0,if index==1 then -.4 else math.pi-.4,0)
        Factory.prop(root,'BrickBarn',CFrame.new(position)*facing,.85)
        Factory.prop(root,'CoolTralalero',CFrame.new(position+Vector3.new(6,0,-2))*facing,.65)
        Factory.prop(root,'BrickGrass',CFrame.new(position+Vector3.new(-4,0,-3)),1.4)
        Factory.prop(root,'BrickFlower',CFrame.new(position+Vector3.new(4,0,3)),1.1)
    end
    for i,title in {'TIME PLAYED','NET WORTH','TOTAL BRAINROTS'} do
        local board=Factory.part(root,'Leaderboard'..i,Vector3.new(25,18,1),CFrame.new((i-2)*37,10,-32),Color3.fromRGB(79,49,31),nil,true)
        local surface=Instance.new('SurfaceGui'); surface.Face=Enum.NormalId.Front; surface.CanvasSize=Vector2.new(500,380); surface.Parent=board
        local label=Instance.new('TextLabel'); label.Name='Ranking'; label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.TextColor3=Color3.new(1,1,1); label.Font=Enum.Font.FredokaOne; label.TextSize=28; label.TextWrapped=true; label.Text=title..'\nCURRENT SERVER'; label.Parent=surface
        boards[i]=label
        local rear=surface:Clone(); rear.Face=Enum.NormalId.Back; rear.Parent=board
    end
    return {root=root,plots=plots,boards=boards}
end
function World.setOwner(world: any,player: Player)
    world.renderGeneration=(world.renderGeneration or 0)+1
    world.ownerId=player.UserId; world.ownerName.Text=player.Name.."'s Plot"; world.ownerLabel.Text=player.DisplayName.."'s BRAINROT FARM"; world.portrait.Visible=true
    task.spawn(function()
        local ok,uri=pcall(game.Players.GetUserThumbnailAsync,game.Players,player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150)
        if ok and world.ownerId==player.UserId then world.portrait.Image=uri end
    end)
end
function World.updateBoards(hub: any,entries: {any})
    for index,key in {'time','coins','count'} do
        local ordered=table.clone(entries); table.sort(ordered,function(a,b) return if a[key]==b[key] then a.name<b.name else a[key]>b[key] end)
        local rows={({'TIME PLAYED','NET WORTH','TOTAL BRAINROTS'})[index],'CURRENT SERVER',''}
        for rank,entry in ordered do table.insert(rows,rank..'. '..entry.name..'  -  '..(if key=='time' then math.floor(entry.time/60)..'m '..entry.time%60 ..'s' else tostring(entry[key]))) end
        local label=hub.boards[index]; label.Text=table.concat(rows,'\n')
        for _,surface in label.Parent.Parent:GetChildren() do if surface:IsA('SurfaceGui') then surface.Ranking.Text=label.Text end end
    end
end
function World.render(world: any,state: any)
    world.renderGeneration=(world.renderGeneration or 0)+1
    local generation=world.renderGeneration
    local block=world.root:FindFirstChild('LuckyBlock')
    if state.lucky and not block then
        block=Factory.prop(world.root,'LuckyBlock',world.frame*CFrame.new(Vector3.new(0,.4,24)*Map.PlotScale),Map.PlotScale)
        if not block then block=Factory.part(world.root,'LuckyBlock',Vector3.new(3.5,3.5,3.5)*Map.PlotScale,world.frame*CFrame.new(Vector3.new(0,2.5,24)*Map.PlotScale),Color3.fromRGB(255,203,21)) end
        Factory.label(block,'LUCKY BLOCK\nOpen to see rewards',170,55)
        if not block:IsA('MeshPart') then for _,face in {Enum.NormalId.Front,Enum.NormalId.Back,Enum.NormalId.Left,Enum.NormalId.Right} do
            local gui=Instance.new('SurfaceGui'); gui.Face=face; gui.CanvasSize=Vector2.new(100,100); gui.Parent=block
            local q=Instance.new('TextLabel'); q.Size=UDim2.fromScale(1,1); q.Text='?'; q.TextSize=80; q.Font=Enum.Font.FredokaOne; q.TextColor3=Color3.new(1,1,1); q.BackgroundTransparency=1; q.Parent=gui
        end end
    elseif not state.lucky and block then block:Destroy() end
    local present={}
    for _,p in state.producers do
        present[p.id]=true
        local pos=layout:slotPosition(p.slot); local target=Vector3.new(pos.x,pos.y,pos.z)
        local model=world.producers:FindFirstChild(p.id)
        if not model then
            model=Factory.producer(world.producers,p.id,Catalog[p.speciesId],target)
            placeScaled(model,world.frame)
            model:SetAttribute('RestingPivot',model:GetPivot())
            game:GetService('CollectionService'):AddTag(model,'BrainrotProducer')
        else
            local previous=model:GetAttribute('BasePosition')
            if previous~=target then
                local rest=model:GetAttribute('RestingPivot') or model:GetPivot()
                model:PivotTo(rest+world.frame:VectorToWorldSpace((target-previous)*Map.PlotScale));model:SetAttribute('BasePosition',target);model:SetAttribute('RestingPivot',model:GetPivot())
            end
        end
    end
    for _,child in world.producers:GetChildren() do if not present[child.Name] then child:Destroy() end end
    local rowCount=math.max(1,math.ceil(#state.producers/Config.Columns))
    for row=1,rowCount do
        if not world.rows:FindFirstChild(tostring(row)) then
            local shelf=Instance.new('Model'); shelf.Name=tostring(row); shelf.WorldPivot=CFrame.identity
            local base=Factory.part(shelf,'ShelfBase',Vector3.new(67,.35,7),CFrame.new(0,.2+(row-1)*Config.RowHeight,Config.DisplayZ),orange)
            base.TopSurface=Enum.SurfaceType.Studs
            for column=1,Config.Columns do
                local slot=(row-1)*Config.Columns+column; local pos=layout:slotPosition(slot)
                local plinth=Factory.part(shelf,'DisplayPlatform',Vector3.new(5.7,.22,5.7),CFrame.new(pos.x,.35+(row-1)*Config.RowHeight,Config.DisplayZ),Color3.fromRGB(255,223,122)); plinth.TopSurface=Enum.SurfaceType.Studs
                Factory.prop(shelf,'BrainrotNest',CFrame.new(pos.x,(row-1)*Config.RowHeight+.25,Config.DisplayZ))
                Factory.part(shelf,'DisplayBack',Vector3.new(6.4,5.8,.25),CFrame.new(pos.x,3.1+(row-1)*Config.RowHeight,Config.DisplayZ+3.45),Color3.fromRGB(178,128,52))
                Factory.part(shelf,'DisplayDivider',Vector3.new(.22,4.5,6.8),CFrame.new(pos.x-3.2,2.45+(row-1)*Config.RowHeight,Config.DisplayZ),Color3.fromRGB(217,164,66))
                local glow=Factory.part(shelf,'Slot'..slot,Vector3.new(5.9,.12,5.9),CFrame.new(pos.x,.28+(row-1)*Config.RowHeight,Config.DisplayZ),orange); glow.Material=Enum.Material.Neon
                local h=(row-1)*Config.RowHeight
                for x=-2.4,2.4,1.2 do
                    for y=1,5.2,1.05 do Factory.part(shelf,'BackStud',Vector3.new(.42,.42,.15),CFrame.new(pos.x+x,h+y,Config.DisplayZ+3.25),Color3.fromRGB(212,164,87)) end
                    for _,z in {-2.7,2.7} do Factory.part(shelf,'PlatformStud',Vector3.new(.42,.12,.42),CFrame.new(pos.x+x,h+.52,Config.DisplayZ+z),Color3.fromRGB(255,234,150)) end
                end
                for _,side in {-1,1} do for z=-2.5,2.5,1.25 do for y=1,4.2,1.05 do
                    Factory.part(shelf,'DividerStud',Vector3.new(.15,.42,.42),CFrame.new(pos.x-3.2+side*.18,h+y,Config.DisplayZ+z),Color3.fromRGB(242,199,112))
                end end end
                Factory.part(shelf,'DividerTopTrim',Vector3.new(.38,.22,7),CFrame.new(pos.x-3.2,h+4.8,Config.DisplayZ),Color3.fromRGB(255,215,103))
                Factory.part(shelf,'BayTopTrim',Vector3.new(6.4,.25,.42),CFrame.new(pos.x,h+6,Config.DisplayZ+3.45),Color3.fromRGB(255,215,103))
                Factory.part(shelf,'PlatformFrontTrim',Vector3.new(6.4,.5,.4),CFrame.new(pos.x,h+.2,Config.DisplayZ-3.4),Color3.fromRGB(255,195,42))
            end
            placeScaled(shelf,world.frame); shelf.Parent=world.rows; task.wait()
            if generation~=world.renderGeneration then return end
        end
    end
    for _,row in world.rows:GetChildren() do if tonumber(row.Name)>rowCount then row:Destroy() end end
    for _,producer in state.producers do local row=world.rows:FindFirstChild(tostring(math.ceil(producer.slot/Config.Columns))); local glow=row and row:FindFirstChild('Slot'..producer.slot); if glow and glow:IsA('BasePart') then glow.Color=Color3.fromRGB(table.unpack(Catalog[producer.speciesId].color)) end end
    present={}
    for _,t in state.tokens do
        present[t.id]=true
        local mini=world.tokens:FindFirstChild(t.id)
        if not mini then
        mini=Factory.mini(world.tokens,t,Catalog[t.speciesId]); placeScaled(mini,world.frame)
        mini:SetAttribute('ConveyorStart',point(world,Vector3.new(t.startX,t.startY,t.startZ)))
        mini:SetAttribute('ConveyorDrop',point(world,Vector3.new(t.startX,1.4+math.abs(t.startX)*.032,Config.BeltZ)))
        mini:SetAttribute('ConveyorCenter',point(world,Vector3.new(0,.75,Config.BeltZ)))
        mini:SetAttribute('SpawnedAt',t.spawnedAt); mini:SetAttribute('ReadyAt',t.readyAt)
        local seed=0;for i=1,#t.id do seed=(seed*31+string.byte(t.id,i))%65521 end
        seed=bit32.bxor(seed,bit32.lshift(seed,13)); seed=bit32.bxor(seed,bit32.rshift(seed,17)); seed=bit32.bxor(seed,bit32.lshift(seed,5))
        local yaw=(seed%10007)/10007*math.pi*2
        local roll=(math.floor(seed/101)%101/100-.5)*.3
        local lying=if t.speciesId=='tier_06' then CFrame.Angles(roll*.5,0,roll)
            elseif seed%2==0 then CFrame.Angles(math.pi/2+roll,0,0)
            else CFrame.Angles(0,0,-math.pi/2+roll)
        mini:SetAttribute('FinalRotation',world.frame.Rotation*CFrame.Angles(0,yaw,0)*lying)
        mini:SetAttribute('PlotScale',Map.PlotScale)
        mini:SetAttribute('ConveyorEnd',point(world,Vector3.new(t.x,t.y,t.z)))
        game:GetService('CollectionService'):AddTag(mini,'ConveyorMini')
        local producer=world.producers:FindFirstChild(t.origin)
        if producer then producer:SetAttribute('ProducedAt',t.spawnedAt) end
        end
        mini:SetAttribute('ConveyorEnd',point(world,Vector3.new(t.x,t.y,t.z)))
    end
    for _,child in world.tokens:GetChildren() do if not present[child.Name] then child:Destroy() end end
    for quantity,label in world.pads do
        local unlocked=state.rebirths>=Config.BuyUnlocks[quantity]
        local free=quantity=='1' and not state.starterClaimed
        local amount=if quantity=='100' then math.min(100,Config.Slots-#state.producers) else tonumber(quantity)
        label.Text=(if free then 'BUY FIRST\n$5' elseif amount==0 then 'STACK FULL\nMERGE TO MAKE ROOM' else 'BUY '..(if quantity=='100' then 'UP TO 100' else quantity)..'\n$'..(amount*Config.BuyUnits/4))..(if unlocked then '' else '\nRebirth '..Config.BuyUnlocks[quantity]..' required')
        label.TextColor3=if unlocked then Color3.fromRGB(130,255,62) else Color3.fromRGB(255,195,195)
    end
    world.saleLabel.Text='Collect cash\n$'..string.format('%g',state.soldUnits/4)
    world.processorLabel.Text=tostring(#state.saleQueue)
    world.processorRate.Text=Config.ProcessorRates[state.processorLevel+1]..' per second'
    local upgradeCost=Config.ProcessorCosts[state.processorLevel+1]
    world.upgradeLabel.Text=if upgradeCost then '+'..(Config.ProcessorRates[state.processorLevel+2]-Config.ProcessorRates[state.processorLevel+1])..' per second\n$'..(upgradeCost/4) else 'PROCESSOR MAXED'
end
function World.clear(world: any)
    world.renderGeneration=(world.renderGeneration or 0)+1
    local block=world.root:FindFirstChild('LuckyBlock'); if block then block:Destroy() end
    world.producers:ClearAllChildren(); world.tokens:ClearAllChildren(); world.rows:ClearAllChildren(); world.ownerLabel.Text='BRAINROT FARM'
    world.ownerId=nil; world.ownerName.Text='Available plot'; world.portrait.Visible=false; world.portrait.Image=''
    world.saleLabel.Text='Collect cash\n$0'
end
return World
