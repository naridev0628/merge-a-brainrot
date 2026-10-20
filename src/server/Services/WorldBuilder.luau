--!strict
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Factory=require(Shared.ModelFactory)
local Environment=require(Shared.EnvironmentArt)
local Landmarks=require(Shared.FarmLandmarks)
local ConveyorFacade=require(Shared.ConveyorFacade)
local HubScenery=require(Shared.HubScenery)
local HubStudOcclusion=require(Shared.HubStudOcclusion)
local ObbyCourse=require(Shared.ObbyCourse)
local Decor=require(Shared.StallDecor)
local FarmerBooth=require(Shared.FarmerBooth)
local LuckyBlockVisuals=require(Shared.LuckyBlockVisuals)
local LeaderboardDisplay=require(script.Parent.LeaderboardDisplay)
local Map=require(Shared.MapSpec)
local Catalog=require(Shared.CreatureCatalog)
local Config=require(Shared.Config)
local Economy=require(Shared.Economy)
local PassConfig=require(Shared.PassConfig)
local TextStyle=require(Shared.TextStyle)
local Core=require(script.Parent.Parent.Domain.FarmCore)
local layout=Core.new(Config,Catalog)
local World={}
local orange=Color3.fromRGB(255,174,22)
local function cashText(units: number): string
    local digits=string.format('%.0f',units/4)
    local grouped=string.reverse(digits):gsub('(%d%d%d)','%1,')
    return '$'..string.reverse(grouped):gsub('^,','')
end
local function placeScaled(model: Model,transform: CFrame)
    local pivot=model:GetPivot()
    model:ScaleTo(model:GetScale()*Map.PlotScale)
    model:PivotTo(transform*CFrame.new(pivot.Position*Map.PlotScale)*pivot.Rotation)
end
local function point(world: any,value: Vector3): Vector3
    return world.frame:PointToWorldSpace(value*Map.PlotScale)
end
local function pad(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3)
    Factory.part(parent,name..'Base',size+Vector3.new(.7,.25,.7),cf-Vector3.new(0,.22,0),Color3.fromRGB(112,65,30))
    for _,side in {-1,1} do
        Factory.part(parent,name..'Edge',Vector3.new(size.X+.5,.12,.15),cf*CFrame.new(0,.05,side*(size.Z/2+.15)),color:Lerp(Color3.new(1,1,1),.3))
        Factory.part(parent,name..'Edge',Vector3.new(.15,.12,size.Z+.5),cf*CFrame.new(side*(size.X/2+.15),.05,0),color:Lerp(Color3.new(1,1,1),.3))
    end
    local p=Factory.part(parent,name,size,cf,color); p.TopSurface=Enum.SurfaceType.Studs
    for x=-size.X/2+1,size.X/2-1,2 do for z=-size.Z/2+1,size.Z/2-1,2 do
        Factory.part(parent,name..'Stud',Vector3.new(.7,.18,.7),cf*CFrame.new(x,size.Y/2+.09,z),color:Lerp(Color3.new(1,1,1),.12))
    end end
    return p
end
local function padAvailability(part: BasePart,affordable: boolean)
    if part:GetAttribute('Affordable')==affordable then return end
    part:SetAttribute('Affordable',affordable)
    local color=if affordable then Color3.fromRGB(96,238,43) else Color3.fromRGB(244,90,94)
    part.Color=color
    for _,detail in part.Parent:GetChildren() do
        if detail:IsA('BasePart') then
            if detail.Name==part.Name..'Stud' then detail.Color=color:Lerp(Color3.new(1,1,1),.12)
            elseif detail.Name==part.Name..'Edge' then detail.Color=color:Lerp(Color3.new(1,1,1),.3) end
        end
    end
end
local function actionLabel(part: BasePart,action: string,value: string,width: number?)
    local title=Factory.label(part,action,width or 180,102)
    title.Size=UDim2.new(1,0,0,38);title.TextWrapped=false
    TextStyle.apply(title,30,TextStyle.Cream,2.4)
    title.Parent.StudsOffset=Vector3.new(0,4.3,0);title.Parent.MaxDistance=75
    local price=title:Clone();price.Name='Price';price.Position=UDim2.fromOffset(0,38);price.Size=UDim2.new(1,0,0,42);price.Text=value;price.Parent=title.Parent
    TextStyle.apply(price,36,TextStyle.Price,2.6);price.TextScaled=true
    local priceSize=Instance.new('UITextSizeConstraint');priceSize.MinTextSize=18;priceSize.MaxTextSize=36;priceSize.Parent=price
    local detail=title:Clone();detail.Name='Detail';detail.Position=UDim2.fromOffset(0,80);detail.Size=UDim2.new(1,0,0,22);detail.Text='';detail.Parent=title.Parent
    TextStyle.apply(detail,13,TextStyle.Cream,1.5);detail.TextScaled=true
    local detailSize=Instance.new('UITextSizeConstraint');detailSize.MinTextSize=9;detailSize.MaxTextSize=13;detailSize.Parent=detail
    return title,price,detail
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
    local lawn=Factory.part(root,'StuddedLawn',Vector3.new(96,1,82),CFrame.new(0,-.5,3),Color3.fromRGB(114,210,37),nil,true)
    lawn.TopSurface=Enum.SurfaceType.Studs
    local rearDepth=Config.PlotBackZ-Config.PlotRearStartZ
    local rearCenter=(Config.PlotBackZ+Config.PlotRearStartZ)/2
    local rear=Factory.part(root,'WideFarmRear',Vector3.new(112,1,rearDepth),CFrame.new(0,-.5,rearCenter),lawn.Color,nil,true);rear.TopSurface=Enum.SurfaceType.Studs
    local stallFloor=Factory.part(root,'FarmerAlcove',Map.FarmerAlcoveSize,CFrame.new(Map.FarmerAlcoveCenter),lawn.Color,nil,true);stallFloor.TopSurface=Enum.SurfaceType.Studs
    for _,side in {-1,1} do
        fence(root,CFrame.new(side*48,0,3)*CFrame.Angles(0,math.pi/2,0),82)
        fence(root,CFrame.new(side*52,0,Config.PlotRearStartZ),8)
        fence(root,CFrame.new(side*56,0,rearCenter)*CFrame.Angles(0,math.pi/2,0),rearDepth)
    end
    local entranceHalf=7/Map.PlotScale
    local alcoveLeft=Map.FarmerAlcoveCenter.X-Map.FarmerAlcoveSize.X/2
    local alcoveRight=Map.FarmerAlcoveCenter.X+Map.FarmerAlcoveSize.X/2
    for _,span in {{-48,alcoveLeft},{alcoveRight,-entranceHalf},{entranceHalf,48}} do
        fence(root,CFrame.new((span[1]+span[2])/2,0,-38),span[2]-span[1])
    end
    fence(root,CFrame.new(Map.FarmerAlcoveCenter.X,0,-52),Map.FarmerAlcoveSize.X)
    for _,x in {alcoveLeft,alcoveRight} do fence(root,CFrame.new(x,0,-45)*CFrame.Angles(0,math.pi/2,0),14) end
    local back=Factory.part(root,'BackWall',Vector3.new(112,5,1.5),CFrame.new(0,2.5,Config.PlotBackZ),orange,nil,true); back.TopSurface=Enum.SurfaceType.Studs
    local pads={}
    for _,quantity in {'1','5','10','50'} do
        local purchase=pad(root,'Buy'..quantity,Vector3.new(10,.4,7),CFrame.new(Config.BuyPads[quantity],.2,Config.BuyZ),if quantity=='1' then Color3.fromRGB(96,238,43) else Color3.fromRGB(244,90,94))
        local title=actionLabel(purchase,'Buy '..quantity,if quantity=='1' then '$5' else cashText(Economy.buyCost(0,tonumber(quantity),1)))
        pads[quantity]=title
    end
    local deposit=pad(root,'DepositPad',Vector3.new(Map.DepositHalfSize.X*2,.4,Map.DepositHalfSize.Y*2),CFrame.new(Map.Sell),Color3.fromRGB(255,229,95))
    local depositLabel=Factory.label(deposit,'Deposit Minis',230,44);TextStyle.apply(depositLabel,30,TextStyle.Cream,2.6);depositLabel.Parent.StudsOffset=Vector3.new(0,3.3,0)
    -- A broad warm halo reads from the bridge; the studded top stays solid.
    local depositHalo=Factory.part(root,'DepositWarmHalo',Vector3.new(20.6,.06,12.6),CFrame.new(Map.Sell+Vector3.new(0,.06,0)),Color3.fromRGB(255,218,65));depositHalo.Material=Enum.Material.Neon;depositHalo.Transparency=.68;depositHalo.CanQuery=false
    for _,side in {-1,1} do
        local a=Factory.part(root,'DepositGlow',Vector3.new(18.6,.2,.5),CFrame.new(Map.Sell+Vector3.new(0,.28,side*5)),Color3.fromRGB(255,255,65));a.Material=Enum.Material.Neon
        local b=Factory.part(root,'DepositGlow',Vector3.new(.5,.2,10),CFrame.new(Map.Sell+Vector3.new(side*9,.28,0)),Color3.fromRGB(255,255,65));b.Material=Enum.Material.Neon
        local haloA=Factory.part(root,'DepositGlowHalo',Vector3.new(19.1,.08,1.05),CFrame.new(Map.Sell+Vector3.new(0,.22,side*5)),Color3.fromRGB(255,240,24));haloA.Material=Enum.Material.Neon;haloA.Transparency=.55
        local haloB=Factory.part(root,'DepositGlowHalo',Vector3.new(1.05,.08,10),CFrame.new(Map.Sell+Vector3.new(side*9,.22,0)),Color3.fromRGB(255,240,24));haloB.Material=Enum.Material.Neon;haloB.Transparency=.55
    end
    local glow=Instance.new('PointLight');glow.Color=Color3.fromRGB(255,230,65);glow.Brightness=2.8;glow.Range=12;glow.Parent=deposit
    FarmerBooth.build(root)
    for index,x in {-18,-36} do
        local crateCF=CFrame.new(x,0,-36)*CFrame.Angles(0,math.pi,0)
        Decor.place(root,'KeyCrate',crateCF,1.75)
        for n=1,3 do
            local key=Factory.expansionKeys[((id-1)*6+(index-1)*3+n-1)%#Factory.expansionKeys+1]
            local miniCF=CFrame.new(x+(n-2)*1.6,0,-36)*CFrame.Angles(0,math.pi,0)
            local mini=Factory.expansion(root,key,miniCF,true)
            -- Fit broad silhouettes into individual crate slots, with heads above the rim.
            mini.Size*=math.min(1.3,1.45/mini.Size.X)
            mini.CFrame=miniCF*CFrame.new(0,4.7-mini.Size.Y/2,0)
        end
    end
    Decor.place(root,'CashStash',CFrame.new(-38,0,-35)*CFrame.Angles(0,-.3,0),.9)
    Decor.place(root,'ShippingCrate',CFrame.new(-30,0,-47)*CFrame.Angles(0,.2,0),.8)
    -- Keep the sign along the side fence, clear of the purchase row.
    local processorGroup=Instance.new('Model');processorGroup.Name='ProcessorSign';processorGroup.Parent=root
    for _,x in {-43,-25} do Factory.part(processorGroup,'ProcessorPost',Vector3.new(.7,8,.7),CFrame.new(x,4,29),Color3.fromRGB(102,65,34)) end
    local processor=Factory.part(processorGroup,'Processor',Vector3.new(23,10,1),CFrame.new(-34,9,29),Color3.fromRGB(143,94,49),nil,true)
    for _,side in {-1,1} do
        for x=-10,10,1.6 do for y=-4,4,1.6 do Factory.part(processorGroup,'SignStud',Vector3.new(.72,.72,.16),CFrame.new(-34+x,9+y,29+side*.56),Color3.fromRGB(181,126,78)) end end
    end
    for _,y in {3.8,14.2} do Factory.part(processorGroup,'SignFrame',Vector3.new(23.6,.55,1.4),CFrame.new(-34,y,29),Color3.fromRGB(103,61,31)) end
    for _,x in {-45.7,-22.3} do Factory.part(processorGroup,'SignFrame',Vector3.new(.55,10.4,1.4),CFrame.new(x,9,29),Color3.fromRGB(103,61,31)) end
    local textFace=Factory.part(processorGroup,'ProcessorTextFace',Vector3.new(23,10,.02),CFrame.new(-34,9,28.3),Color3.new(1,1,1));textFace.Transparency=1;textFace.CanQuery=false
    local surface=Instance.new('SurfaceGui'); surface.Name='ProcessorDisplay'; surface.Adornee=textFace; surface.Face=Enum.NormalId.Front; surface.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;surface.CanvasSize=Vector2.new(690,300);surface.LightInfluence=0;surface.MaxDistance=100;surface.Parent=processor
    local function signLine(name: string,value: string,y: number,height: number,size: number,color: Color3)
        local label=Instance.new('TextLabel');label.Name=name;label.Text=value;label.Position=UDim2.fromOffset(15,y);label.Size=UDim2.new(1,-30,0,height);label.BackgroundTransparency=1;label.Parent=surface
        TextStyle.apply(label,size,color,3)
        return label
    end
    signLine('Title','MINI PROCESSOR',20,48,40,TextStyle.Cream)
    local processorLabel=signLine('Queued','No Minis queued',88,92,58,TextStyle.Cream)
    processorLabel.TextScaled=true
    local queueSize=Instance.new('UITextSizeConstraint');queueSize.MinTextSize=28;queueSize.MaxTextSize=58;queueSize.Parent=processorLabel
    local processorRate=signLine('Rate','2 per second',222,58,48,TextStyle.Cream)
    local signTransform=CFrame.new(-47,0,10)*CFrame.Angles(0,-math.pi/2,0)*CFrame.new(34,0,-29)
    for _,part in processorGroup:GetDescendants() do if part:IsA('BasePart') then part.CFrame=signTransform*part.CFrame end end
    local upgrade=pad(root,'UpgradePad',Vector3.new(11,.4,7),CFrame.new(Map.Upgrade),Color3.fromRGB(95,245,70))
    local upgradeLabel,upgradePrice=actionLabel(upgrade,'+3 per second','$10',240)
    upgradeLabel.TextScaled=true
    local upgradeSize=Instance.new('UITextSizeConstraint');upgradeSize.MinTextSize=18;upgradeSize.MaxTextSize=30;upgradeSize.Parent=upgradeLabel
    local finish=pad(root,'FinishNowPad',Vector3.new(10,.4,7),CFrame.new(Map.FinishNow),Color3.fromRGB(255,213,35)); finish:SetAttribute('ProductKey','finishNow')
    local _,finishStatus=actionLabel(finish,'Finish Now','Coming soon',205);TextStyle.apply(finishStatus,25,TextStyle.Cream,2);finishStatus:FindFirstChildOfClass('UITextSizeConstraint').MaxTextSize=25
    for key,position in Map.PassPads do
        local passPad=pad(root,'Pass_'..key,Vector3.new(8,.4,6),CFrame.new(position),Color3.fromRGB(255,222,35))
        passPad:SetAttribute('PassKey',key)
        local label,status=actionLabel(passPad,if key=='autoCollect' then 'Auto Collect' else PassConfig[key].name,'Coming soon',180)
        TextStyle.apply(label,if key=='autoCollect' then 27 else 22,TextStyle.Cream,2.2);TextStyle.apply(status,22,TextStyle.Cream,2)
        status:FindFirstChildOfClass('UITextSizeConstraint').MaxTextSize=22
        label.Parent.MaxDistance=if key=='autoCollect' then 75 else 40
    end
    local claim=pad(root,'CoinPad',Vector3.new(15,.4,10),CFrame.new(Map.Claim),Color3.fromRGB(92,231,139))
    local _,saleLabel=actionLabel(claim,'Collect Cash','$0',230)
    local merge=pad(root,'MergePad',Vector3.new(10,.4,7),CFrame.new(Map.Merge),Color3.fromRGB(252,219,50))
    local mergeLabel=Factory.label(merge,'Merge',160,44);TextStyle.apply(mergeLabel,32,TextStyle.Cream,2.6)
    local sign=Factory.part(root,'OwnerSign',Vector3.new(14,4,1),CFrame.new(0,4,Config.PlotBackZ-2),Color3.fromRGB(157,91,31))
    local ownerLabel=Factory.label(sign,'BRAINROT FARM',260,58)
    local badgePart=Factory.part(root,'OwnerBadgeAnchor',Vector3.one,CFrame.new(0,44,Config.DisplayZ),orange); badgePart.Transparency=1
    local badge=Instance.new('BillboardGui'); badge.Name='OwnerBadge'; badge.Size=UDim2.fromOffset(220,120); badge.MaxDistance=500; badge.AlwaysOnTop=true; badge.Parent=badgePart
    local portrait=Instance.new('ImageLabel'); portrait.Name='Portrait'; portrait.BackgroundColor3=Color3.fromRGB(80,160,250); portrait.Size=UDim2.fromOffset(76,76); portrait.Position=UDim2.new(.5,-38,0,0); portrait.Parent=badge
    local round=Instance.new('UICorner'); round.CornerRadius=UDim.new(1,0); round.Parent=portrait
    local rim=Instance.new('UIStroke'); rim.Thickness=3; rim.Color=Color3.new(0,0,0); rim.Parent=portrait
    local ownerName=Instance.new('TextLabel'); ownerName.Name='Username'; ownerName.Size=UDim2.new(1,0,0,40); ownerName.Position=UDim2.fromOffset(0,78); ownerName.BackgroundTransparency=1
    ownerName.Text='Available plot'; ownerName.Position=UDim2.fromOffset(0,40);ownerName.Parent=badge;TextStyle.apply(ownerName,22,TextStyle.Cream,2.2)
    portrait.Visible=false
    -- Two red lanes converge at the center, then feed a gold-rimmed collection tray.
    local traySpec=Config.Tray
    local trayHalfWidth,trayHalfDepth=traySpec.Width/2,traySpec.Depth/2
    local trayFront=Config.TrayZ-trayHalfDepth
    local rimBack=math.min(Config.TrayZ+trayHalfDepth,Config.BeltZ-4)
    local rimDepth,rimCenter=rimBack-trayFront,(rimBack+trayFront)/2
    local laneOuter=Config.Columns*Config.ColumnSpacing/2+2
    local laneWidth=laneOuter-trayHalfWidth
    local laneCenter=(laneOuter+trayHalfWidth)/2
    local belt=Factory.part(root,'ConveyorBelt',Vector3.new(102,.4,8),CFrame.new(0,.5,Config.BeltZ),Color3.fromRGB(222,61,62),nil,true); belt.TopSurface=Enum.SurfaceType.Studs
    Factory.part(root,'ConveyorBackRail',Vector3.new(104,1,1),CFrame.new(0,.9,Config.BeltZ+4.6),orange,nil,true)
    for _,side in {-1,1} do Factory.part(root,'ConveyorFrontRail',Vector3.new(laneWidth,1,1),CFrame.new(side*laneCenter,.9,Config.BeltZ-4.6),orange,nil,true) end
    -- Keep the complete belt center collidable even when the tray extends beneath it.
    local chuteStart=rimBack
    local chuteEnd=Config.BeltZ+4
    Factory.part(root,'ConveyorCenter',Vector3.new(14,.4,chuteEnd-chuteStart+1),CFrame.new(0,.5,(chuteStart+chuteEnd)/2),Color3.fromRGB(222,61,62),nil,true)
    local tray=Factory.part(root,'CollectionTray',Vector3.new(traySpec.Width,.4,traySpec.Depth),CFrame.new(0,.45,Config.TrayZ),Color3.fromRGB(222,61,62));tray.TopSurface=Enum.SurfaceType.Studs
    -- Keep 35 physical accents; native studs cover the larger red floor.
    for x=-3,3 do for z=-2,2 do Factory.part(root,'TrayStud',Vector3.new(.5,.1,.5),CFrame.new(x*traySpec.Width/8,.7,Config.TrayZ+z*(traySpec.Depth-4)/4),Color3.fromRGB(238,84,82)) end end
    for _,side in {-1,1} do Factory.part(root,'TrayRim',Vector3.new(.7,.8,rimDepth),CFrame.new(side*trayHalfWidth,.8,rimCenter),orange,nil,true) end
    Factory.part(root,'TrayFront',Vector3.new(traySpec.Width,.6,.7),CFrame.new(0,.7,trayFront),orange,nil,true)
    belt.Transparency=1;belt.CanCollide=false
    for _,side in {-1,1} do
        local rampCF=CFrame.new(side*26,1.2,Config.BeltZ)*CFrame.Angles(0,0,side*.032)
        local ramp=Factory.part(root,'StuddedConveyorRamp',Vector3.new(51,.35,8),rampCF,Color3.fromRGB(222,61,62),nil,true);ramp.TopSurface=Enum.SurfaceType.Studs
        for x=-24,24,2 do for z=-3,3,2 do Factory.part(root,'ConveyorStud',Vector3.new(.5,.10,.5),rampCF*CFrame.new(x,.23,z),Color3.fromRGB(238,84,82)) end end
    end
    local plotDecor=Instance.new('Model');plotDecor.Name='PlotDecor';plotDecor.WorldPivot=CFrame.identity;plotDecor.Parent=root
    -- Identical authored locations, variants and sizes on every plot; keep all play areas clear.
    for _,spec in {{Vector3.new(-49,0,65),.8,2,.3},{Vector3.new(49,0,65),.9,1,0},{Vector3.new(43,0,-7),.65,3,0}} do
        Environment.tree(plotDecor,CFrame.new(spec[1])*CFrame.Angles(0,spec[4],0),spec[2],spec[3])
    end
    for _,spot in {Vector3.new(43,0,18),Vector3.new(-44,0,0)} do
        Factory.prop(plotDecor,'BrickBush',CFrame.new(spot),.8)
        Factory.prop(plotDecor,'BrickLog',CFrame.new(spot+Vector3.new(0,0,5))*CFrame.Angles(0,math.pi/2,0),.65)
        Factory.prop(plotDecor,'BrickGrass',CFrame.new(spot+Vector3.new(-1,0,2.5)),.85)
        for flower=1,3 do Factory.prop(plotDecor,'BrickFlower',CFrame.new(spot+Vector3.new((flower-2)*1.4,0,-3)),.8) end
    end
    local barn=Factory.prop(root,'BrickBarn',CFrame.lookAt(Vector3.new(-41,0,-29),Vector3.new(0,0,18)),.95)
    if barn then
        local roofGuest=Factory.producer(root,'BarnMascot',Catalog[string.format('tier_%02d',(id-1)%4+1)],Vector3.new(-41,barn.Size.Y,-29),true)
        roofGuest:ScaleTo(1.2)
        local guestPivot=roofGuest:GetPivot()
        roofGuest:PivotTo(CFrame.lookAt(guestPivot.Position,Vector3.new(0,guestPivot.Position.Y,18)))
    end
    local groupCF=CFrame.new(47,9,6)*CFrame.Angles(0,math.pi/2,0)
    for _,x in {-6.5,6.5} do
        local support=Factory.part(root,'GroupBoardSupport',Vector3.new(.9,9,.9),groupCF*CFrame.new(x,-4.5,.1),Color3.fromRGB(101,62,34));support.TopSurface=Enum.SurfaceType.Studs
    end
    local groupBoard=Factory.part(root,'GroupRewardBoard',Vector3.new(17,10,.8),groupCF,Color3.fromRGB(153,101,56),nil,true)
    for x=-7,7,2 do for y=-4,4,2 do Factory.part(root,'GroupBoardStud',Vector3.new(.7,.7,.15),groupCF*CFrame.new(x,y,-.48),Color3.fromRGB(188,133,82)) end end
    for _,y in {-5,5} do Factory.part(root,'GroupBoardFrame',Vector3.new(17.6,.55,1),groupCF*CFrame.new(0,y,0),Color3.fromRGB(103,61,31)) end
    for _,x in {-8.5,8.5} do Factory.part(root,'GroupBoardFrame',Vector3.new(.55,10,1),groupCF*CFrame.new(x,0,0),Color3.fromRGB(103,61,31)) end
    -- Render through the same world-space path as the processor. In the verified
    -- Studio view AlwaysOnTop made this surface disappear; the forward plane also
    -- keeps the wood studs from cutting through the lettering.
    local groupFace=Factory.part(root,'GroupRewardTextFace',Vector3.new(17,10,.02),groupCF*CFrame.new(0,0,-.7),groupBoard.Color);groupFace.Transparency=1;groupFace.CanQuery=false
    local groupGui=Instance.new('SurfaceGui');groupGui.Name='GroupRewardDisplay';groupGui.Adornee=groupFace;groupGui.Face=Enum.NormalId.Front;groupGui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;groupGui.CanvasSize=Vector2.new(510,300);groupGui.AlwaysOnTop=false;groupGui.LightInfluence=0;groupGui.MaxDistance=100;groupGui.Parent=groupBoard
    for _,line in {
        {name='Reward',text='Group rewards',y=35,height=68,size=43,color=TextStyle.Cream},
        {name='Instructions',text='Coming soon',y=124,height=68,size=42,color=TextStyle.Gold},
        {name='Status',text='No reward available yet',y=237,height=34,size=25,color=TextStyle.Cream},
    } do
        local label=Instance.new('TextLabel');label.Name=line.name;label.Size=UDim2.new(1,-30,0,line.height);label.Position=UDim2.fromOffset(15,line.y);label.BackgroundTransparency=1;label.Text=line.text;label.Parent=groupGui
        TextStyle.apply(label,line.size,line.color,2.8)
    end
    local groupLogCF=groupCF*CFrame.new(0,-8.3,-1.8)
    local groupLog=Factory.part(root,'GroupBoardFootLog',Vector3.new(7,1.4,1.6),groupLogCF,Color3.fromRGB(145,88,43));groupLog.TopSurface=Enum.SurfaceType.Studs
    for x=-2.8,2.8,1.4 do for _,z in {-.4,.4} do Factory.part(root,'GroupLogStud',Vector3.new(.65,.18,.65),groupLogCF*CFrame.new(x,.79,z),Color3.fromRGB(184,120,65)) end end
    pad(root,'GroupRewardPad',Vector3.new(10,.4,7),CFrame.new(35,.2,6),Color3.fromRGB(181,170,133))
    local spawn=Instance.new('SpawnLocation'); spawn.Name='FarmSpawn'; spawn.Anchored=true; spawn.Transparency=1
    spawn.CanCollide=false; spawn.CanTouch=false; spawn.Size=Vector3.new(6,1,6); spawn.CFrame=Map.Spawn; spawn.Neutral=true; spawn.Parent=root
    local producers=Instance.new('Folder'); producers.Name='Producers'; producers.Parent=root
    local tokens=Instance.new('Folder'); tokens.Name='Minis'; tokens.Parent=root
    local rows=Instance.new('Folder'); rows.Name='StackRows'; rows.Parent=root
    Landmarks.buildPlot(root)
    ConveyorFacade.build(root)
    placeScaled(root,transform)
    root.Parent=parent; task.wait()
    local lighting=game:GetService('Lighting'); lighting.ClockTime=13; lighting.Brightness=2; lighting.Ambient=Color3.fromRGB(170,170,170)
    return {id=id,frame=transform,root=root,producers=producers,tokens=tokens,rows=rows,ownerLabel=ownerLabel,badgePart=badgePart,pads=pads,saleLabel=saleLabel,portrait=portrait,ownerName=ownerName,processorLabel=processorLabel,processorRate=processorRate,upgradeLabel=upgradeLabel,upgradePrice=upgradePrice,spawn=spawn}
end
function World.build()
    local old=workspace:FindFirstChild('MergeABrainrotGenerated'); if old then old:Destroy() end
    local root=Instance.new('Folder'); root.Name='MergeABrainrotGenerated'; root.Parent=workspace
    local water=Factory.part(root,'Water',Vector3.new(1000,1,1000),CFrame.new(0,-5,0),Color3.fromRGB(46,174,224),nil,true);water.Transparency=1
    local terrain=workspace.Terrain
    terrain.WaterColor=Color3.fromRGB(41,156,231)
    terrain.WaterTransparency=.24;terrain.WaterReflectance=.12
    terrain.WaterWaveSize=.12;terrain.WaterWaveSpeed=9
    terrain:FillBlock(CFrame.new(0,-6.6,0),Vector3.new(1000,4,1000),Enum.Material.Water)
    Landmarks.buildHub(root)
    local hubCovers: {HubStudOcclusion.Cover}={}
    for i=1,6 do
        local angle=(i-1)*math.pi/3
        local outward=Vector3.new(math.sin(angle),0,math.cos(angle))
        local walkCF=CFrame.lookAt(outward*65+Vector3.new(0,.08,0),outward*90+Vector3.new(0,.08,0))
        local walk=Factory.part(root,'LobbyWalkway',Vector3.new(14,.2,62),walkCF,Color3.fromRGB(245,204,123));walk.TopSurface=Enum.SurfaceType.Studs
        table.insert(hubCovers,{kind='box',x=walk.Position.X,z=walk.Position.Z,
            halfX=walk.Size.X/2,halfZ=walk.Size.Z/2,rightX=walk.CFrame.RightVector.X,rightZ=walk.CFrame.RightVector.Z,
            bottom=walk.Position.Y-walk.Size.Y/2,top=walk.Position.Y+walk.Size.Y/2})
        for _,side in {-1,1} do
            local edge=Factory.part(root,'WalkwayBrickEdge',Vector3.new(.3,.15,62),walkCF*CFrame.new(side*7,.08,0),Color3.fromRGB(255,222,153));edge.CanQuery=false
        end
    end
    local circle=Factory.part(root,'GatheringCircle',Vector3.new(.3,68,68),CFrame.new(0,.15,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(255,192,98),Enum.PartType.Cylinder,true)
    circle.TopSurface=Enum.SurfaceType.Studs
    -- Derive occlusion from the actual opaque cover Parts. The cylinder's local
    -- X axis is vertical; walkway rectangles are yawed around the world Y axis.
    table.insert(hubCovers,{kind='circle',x=circle.Position.X,z=circle.Position.Z,radius=circle.Size.Y/2,
        bottom=circle.Position.Y-circle.Size.X/2,top=circle.Position.Y+circle.Size.X/2})
    Environment.octagon(root,CFrame.identity,96,1,Color3.fromRGB(115,210,38),function(x,z,width,bottom,top)
        return HubStudOcclusion.isFullyCovered(x,z,width,bottom,top,hubCovers)
    end)
    for i=1,16 do
        local angle=i*math.pi/8; local x,z=math.cos(angle)*37,math.sin(angle)*37
        local edging=Factory.part(root,'CircleEdging',Vector3.new(6,.4,1.1),CFrame.new(x,.3,z)*CFrame.Angles(0,-angle+math.pi/2,0),orange);edging.TopSurface=Enum.SurfaceType.Studs
    end
    local plots={}
    for i=1,6 do
        local angle=(i-1)*math.pi/3
        local outward=Vector3.new(math.sin(angle),0,math.cos(angle))
        local plotRadius=131+38*Map.PlotScale
        local transform=CFrame.lookAt(outward*plotRadius,outward*(plotRadius-1))
        table.insert(plots,buildPlot(root,i,transform))
        local bridgeCF=CFrame.lookAt(outward*112.5+Vector3.new(0,-.2,0),outward*113.5+Vector3.new(0,-.2,0))
        local bridge=Factory.part(root,'Bridge',Vector3.new(14,1,39),bridgeCF,Color3.fromRGB(162,111,63),nil,true);bridge.TopSurface=Enum.SurfaceType.Studs
        local bridgeMesh=Factory.prop(root,'BrickBridge',bridgeCF+Vector3.new(0,.1,0))
        if bridgeMesh then bridgeMesh.Size=Vector3.new(bridgeMesh.Size.X,bridgeMesh.Size.Y,39);bridge.Transparency=1 end
        -- The mesh's rails extend beyond its planks. Solid landing planks cover
        -- that inset and overlap the island/plot instead of merely touching them.
        for _,radius in {94,plotRadius-38*Map.PlotScale} do
            local landingCF=CFrame.lookAt(outward*radius+Vector3.new(0,.15,0),outward*(radius+1)+Vector3.new(0,.15,0))
            local landing=Factory.part(root,if radius==94 then 'BridgeApproach' else 'BridgeLanding',Vector3.new(13.6,.5,3),landingCF,Color3.fromRGB(180,119,64),nil,true)
            landing.TopSurface=Enum.SurfaceType.Studs;landing:SetAttribute('PlotId',i)
            for _,x in {-5.8,5.8} do Factory.part(root,'LandingPeg',Vector3.new(.22,.08,.22),landingCF*CFrame.new(x,.29,0),Color3.fromRGB(105,64,32)) end
        end
        for _,side in {-1,1} do local rail=Factory.part(root,'BridgeBarrier',Vector3.new(.6,4,39),bridgeCF*CFrame.new(side*6.8,2.2,0),orange,nil,true);rail.Transparency=1 end
        for n=1,4 do Factory.prop(root,'BrickLilyPad',bridgeCF*CFrame.new((if n%2==0 then -1 else 1)*(12+n*2),-4.18,(n-2)*10)*CFrame.Angles(0,n*1.6,0),.8+n*.2) end
    end
    local boards={}
    -- Cylinder top faces do not use the normal Part top surface; give the plaza real studs.
    for x=-32,32,2 do
        for z=-32,32,2 do if x*x+z*z<33*33 then
            local stud=Factory.part(root,'PlazaStud',Vector3.new(.6,.14,.6),CFrame.new(x,.37,z),Color3.fromRGB(255,205,128));stud.CanQuery=false
        end end
        if x%10==0 then task.wait() end
    end
    HubScenery.build(root)
    ObbyCourse.build(root)
    local boardSpecs={
        {key='time',title='Time Played',color=Color3.fromRGB(86,178,255)},
        {key='coins',title='Net Worth',color=Color3.fromRGB(103,255,31)},
        {key='count',title='Total Brainrots',color=Color3.fromRGB(197,231,136)},
    }
    for i,spec in boardSpecs do
        local angle=(i-1)*math.pi*2/3-math.pi/2
        local position=Vector3.new(math.cos(angle)*30,14,math.sin(angle)*30)
        boards[i]=LeaderboardDisplay.new(root,spec.key,spec.title,spec.color,CFrame.lookAt(position,Vector3.new(0,14,0)))
    end
    return {root=root,plots=plots,boards=boards}
end
function World.setOwner(world: any,player: Player)
    world.renderGeneration=(world.renderGeneration or 0)+1
    world.ownerId=player.UserId; world.ownerName.Text=player.Name.."'s Plot"; world.ownerLabel.Text=player.DisplayName.."'s BRAINROT FARM"; world.portrait.Visible=true
    world.ownerName.Position=UDim2.fromOffset(0,78)
    task.spawn(function()
        local ok,uri=pcall(game.Players.GetUserThumbnailAsync,game.Players,player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150)
        if ok and world.ownerId==player.UserId then world.portrait.Image=uri end
    end)
end
function World.updateBoards(hub: any,entries: {any})
    for _,board in hub.boards do LeaderboardDisplay.update(board,entries) end
end
function World.render(world: any,state: any)
    world.renderGeneration=(world.renderGeneration or 0)+1
    local generation=world.renderGeneration
    local block=world.root:FindFirstChild('LuckyBlock')
    if state.lucky and not state.lucky.held and not block then
        block=Factory.prop(world.root,'LuckyBlock',world.frame*CFrame.new(Vector3.new(Config.LuckyX,.4,Config.LuckyZ)*Map.PlotScale),Map.PlotScale)
        if not block then block=Factory.part(world.root,'LuckyBlock',Vector3.new(3.5,3.5,3.5)*Map.PlotScale,world.frame*CFrame.new(Vector3.new(Config.LuckyX,2.5,Config.LuckyZ)*Map.PlotScale),Color3.fromRGB(255,203,21)) end
        Factory.label(block,'Lucky Block\nWalk near to hold',170,55)
        LuckyBlockVisuals.apply(block,state.lucky.baseTier)
    elseif (not state.lucky or state.lucky.held) and block then block:Destroy() end
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
    world.badgePart.CFrame=world.frame*CFrame.new(Vector3.new(0,44+(rowCount-1)*Config.RowHeight,Config.DisplayZ)*Map.PlotScale)
    for row=1,rowCount do
        if not world.rows:FindFirstChild(tostring(row)) then
            local shelf=require(Shared.DisplayShelves).buildRow(row,layout)
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
        local finalRotation=world.frame.Rotation*CFrame.Angles(0,yaw,0)*lying
        mini:SetAttribute('FinalRotation',finalRotation)
        local size=mini:GetExtentsSize()
        local halfHeight=(math.abs(finalRotation.RightVector.Y)*size.X+math.abs(finalRotation.UpVector.Y)*size.Y+math.abs(finalRotation.LookVector.Y)*size.Z)/2
        mini:SetAttribute('RestingLift',Vector3.new(0,math.max(0,halfHeight-.325),0))
        mini:SetAttribute('PlotScale',Map.PlotScale)
        mini:SetAttribute('ConveyorEnd',point(world,Vector3.new(t.x,t.y,t.z)))
        game:GetService('CollectionService'):AddTag(mini,'ConveyorMini')
        local producer=world.producers:FindFirstChild(t.origin)
        if producer then producer:SetAttribute('ProducedAt',t.spawnedAt) end
        else
            mini:SetAttribute('ConveyorEnd',point(world,Vector3.new(t.x,t.y,t.z)))
        end
    end
    for _,child in world.tokens:GetChildren() do if not present[child.Name] then child:Destroy() end end
    for quantity,label in world.pads do
        local quote=Economy.purchaseQuote(Config,state,quantity)
        local amount,tier,cost=quote.amount,quote.tier,quote.cost
        local unlocked=state.rebirths>=Config.BuyUnlocks[quantity]
        padAvailability(label.Parent.Parent,quote.code=='OK')
        label.Text=if amount==0 then 'Stack full' else 'Buy '..quantity
        local price=label.Parent.Price
        price.Text=if amount==0 then '' else cashText(cost)
        price.TextColor3=if unlocked then TextStyle.Price else Color3.fromRGB(255,195,195)
        label.Parent.Detail.Text=if not unlocked then 'Rebirth '..Config.BuyUnlocks[quantity]..' required' elseif quote.code=='PlotFull' then 'Merge to make room' elseif quantity=='50' then 'Up to 50 '..Catalog[string.format('tier_%02d',tier)].name else ''
    end
    world.saleLabel.Text='$'..string.format('%g',state.soldUnits/4)
    local queued=Economy.count(state.saleQueue)
    world.processorLabel.Text=if queued==0 then 'No Minis queued' else tostring(queued)..' Minis queued'
    world.processorRate.Text=Config.ProcessorRates[state.processorLevel+1]..' per second'
    local upgradeCost=Config.ProcessorCosts[state.processorLevel+1]
    padAvailability(world.upgradeLabel.Parent.Parent,upgradeCost~=nil and state.coinUnits>=upgradeCost)
    world.upgradeLabel.Text=if upgradeCost then '+'..(Config.ProcessorRates[state.processorLevel+2]-Config.ProcessorRates[state.processorLevel+1])..' per second' else 'PROCESSOR MAXED'
    world.upgradePrice.Text=if upgradeCost then '$'..(upgradeCost/4) else ''
end
function World.clear(world: any)
    world.renderGeneration=(world.renderGeneration or 0)+1
    local block=world.root:FindFirstChild('LuckyBlock'); if block then block:Destroy() end
    world.producers:ClearAllChildren(); world.tokens:ClearAllChildren(); world.rows:ClearAllChildren(); world.ownerLabel.Text='BRAINROT FARM'
    world.ownerId=nil; world.ownerName.Text='Available plot'; world.portrait.Visible=false; world.portrait.Image=''
    world.ownerName.Position=UDim2.fromOffset(0,40);world.badgePart.CFrame=world.frame*CFrame.new(Vector3.new(0,44,Config.DisplayZ)*Map.PlotScale)
    world.saleLabel.Text='$0'
end
return World
