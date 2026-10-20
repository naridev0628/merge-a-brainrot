--!strict
-- Architectural trim only. Build in logical plot coordinates before PlotScale.
local Config=require(script.Parent.Config)
local Factory=require(script.Parent.ModelFactory)
local Map=require(script.Parent.MapSpec)
local Facade={}

local gold=Color3.fromRGB(255,180,25)
local goldLight=Color3.fromRGB(255,220,79)
local goldShade=Color3.fromRGB(209,131,21)
local cream=Color3.fromRGB(224,205,151)
local creamLight=Color3.fromRGB(255,236,179)
local red=Color3.fromRGB(185,43,44)

local function part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3): Part
    local result=Factory.part(parent,name,size,cf,color)
    result.CanQuery=false
    result.CanTouch=false
    result.CanCollide=name=='DisplayFoundation' or name=='DisplayFascia'
    if result.CanCollide then result.CanQuery=true end
    return result
end

local function beam(parent: Instance,name: string,a: Vector3,b: Vector3,width: number,height: number,color: Color3): Part
    return part(parent,name,Vector3.new(width,height,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color)
end

local function wheat(parent: Instance,side: number,endX: number)
    -- Saved reference frames 020 and 040 show small upright gold crop clusters
    -- at the lane ends. Keep the accent out of the open lawn and purchase row.
    local cluster=Instance.new('Model')
    cluster.Name=if side==-1 then 'ConveyorWheatLeft' else 'ConveyorWheatRight'
    cluster.WorldPivot=CFrame.identity;cluster.Parent=parent
    local origin=CFrame.new(endX,0,Config.BeltZ-7.4)
    for _,spec in {{-1.1,-.2,3.4},{-.55,.35,4.1},{0,-.25,4.6},{.6,.3,3.9},{1.15,-.1,3.1}} do
        local x,z,height=spec[1],spec[2],spec[3]
        local stem=origin*CFrame.new(x,0,z)
        part(cluster,'WheatStem',Vector3.new(.18,height,.18),stem*CFrame.new(0,height/2,0),goldShade)
        local grain=part(cluster,'WheatGrainLower',Vector3.new(.56,.65,.5),stem*CFrame.new(0,height-.15,0),gold)
        grain.TopSurface=Enum.SurfaceType.Studs
        local crown=part(cluster,'WheatGrainCrown',Vector3.new(.45,.55,.45),stem*CFrame.new(0,height+.42,0),goldLight)
        crown.TopSurface=Enum.SurfaceType.Studs
        local lean=if x>0 then -1 else 1
        part(cluster,'WheatLeaf',Vector3.new(.18,.9,.36),
            stem*CFrame.new(lean*.23,height*.46,0)*CFrame.Angles(0,0,-lean*.4),gold)
    end
    part(cluster,'WheatBinding',Vector3.new(2.9,.18,.5),origin*CFrame.new(0,1.45,0),goldShade)
end

function Facade.build(parent: Instance): Model
    local root=Instance.new('Model')
    root.Name='ConveyorFacade'
    root.WorldPivot=CFrame.identity
    root.Parent=parent

    local displayWidth=Config.Columns*Config.ColumnSpacing+1
    local width=Map.ConveyorWidth
    local platformHeight=Config.DisplayPlatformHeight
    local fasciaFront=Config.BeltZ+5.25
    local fasciaBack=Config.DisplayZ-3.7
    local fasciaDepth=fasciaBack-fasciaFront
    local tray=Config.Tray
    local halfWidth,halfDepth=tray.Width/2,tray.Depth/2
    local trayFront=Config.TrayZ-halfDepth
    local rimBack=math.min(Config.TrayZ+halfDepth,Config.BeltZ-4)
    local rimDepth,rimCenter=rimBack-trayFront,(rimBack+trayFront)/2
    local laneOuter=Map.ConveyorWidth/2
    local laneWidth=laneOuter-halfWidth
    local laneCenter=(laneOuter+halfWidth)/2

    -- The bright apron bridges the narrow gap below the producer row. Its top
    -- stops at the existing stand plane, leaving every actor and fall visible.
    part(root,'DisplayFoundation',Vector3.new(width,.28,fasciaDepth),
        CFrame.new(0,.14,(fasciaFront+fasciaBack)/2),goldShade)
    part(root,'DisplayFascia',Vector3.new(width,platformHeight-.28,fasciaDepth),
        CFrame.new(0,platformHeight/2+.14,(fasciaFront+fasciaBack)/2),gold)
    part(root,'DisplayApronLip',Vector3.new(width+.35,.18,fasciaDepth+.12),
        CFrame.new(0,platformHeight-.09,(fasciaFront+fasciaBack)/2),goldLight)
    part(root,'DisplayLowerReveal',Vector3.new(width,.12,.12),
        CFrame.new(0,.32,fasciaFront-.065),goldShade)
    for x=-width/2+1.5,width/2-1.5,3 do
        for _,y in {.68,1.27} do
            part(root,'FasciaBrickStud',Vector3.new(.48,.38,.12),
                CFrame.new(x,y,fasciaFront-.065),gold:Lerp(goldLight,.28))
        end
        part(root,'ApronBrickStud',Vector3.new(.58,.12,.58),
            CFrame.new(x,platformHeight+.06,fasciaFront+.55),goldLight)
    end

    -- Cream outer skirts and gold crowns make the same sloped red lanes read
    -- as one substantial machine. They stay outside the belt's playable width.
    for _,side in {-1,1} do
        -- Shorten the inner ends while retaining the original slope and outer height.
        local laneCF=CFrame.new(side*laneCenter,1.95+(laneCenter-30)*math.tan(.022),Config.BeltZ-4.95)
            *CFrame.Angles(0,0,side*.022)
        part(root,'ConveyorCreamSkirt',Vector3.new(laneWidth,3,.65),
            laneCF*CFrame.new(0,-1.7,-.15),cream)
        part(root,'ConveyorSkirtFoot',Vector3.new(laneWidth,.15,.82),
            CFrame.new(side*laneCenter,.16,Config.BeltZ-5.1),creamLight)
        part(root,'ConveyorGoldCrown',Vector3.new(laneWidth,.42,.78),laneCF,gold)
        part(root,'ConveyorCrownHighlight',Vector3.new(laneWidth,.1,.84),
            laneCF*CFrame.new(0,.25,0),goldLight)
        part(root,'ConveyorRedReveal',Vector3.new(laneWidth,.16,.1),
            laneCF*CFrame.new(0,-.37,-.5),red)
        for course=0,2 do
            local seam=part(root,'SkirtBrickCourse',Vector3.new(laneWidth,.045,.025),
                laneCF*CFrame.new(0,-.55-course*.65,-.485),goldShade)
            seam.Transparency=.35
            for x=-laneWidth/2+1.5+(course%2)*1.5,laneWidth/2-1,3 do
                part(root,'SkirtBrickJoint',Vector3.new(.045,.60,.025),
                    laneCF*CFrame.new(x,-.85-course*.65,-.485),goldShade)
            end
        end
        for x=-laneWidth/2+2,laneWidth/2-2,4 do
            part(root,'SkirtBrickStud',Vector3.new(.55,.5,.12),
                laneCF*CFrame.new(x,-.75,-.54),creamLight)
        end

        local endX=side*(Map.ConveyorWidth/2-.6)
        part(root,'OuterConveyorEnd',Vector3.new(1.1,2.25,10.5),
            CFrame.new(endX,1.125,Config.BeltZ),cream)
        part(root,'OuterConveyorCap',Vector3.new(1.4,.38,10.7),
            CFrame.new(endX,2.4,Config.BeltZ),gold)
        part(root,'OuterConveyorHighlight',Vector3.new(.8,.1,10.7),
            CFrame.new(endX,2.64,Config.BeltZ),goldLight)

        -- Open triangular end frames echo the reference display silhouette.
        -- They sit outside all ten bays; no extra wall covers a producer.
        local front=Vector3.new(endX,platformHeight+.25,Config.DisplayZ-4.6)
        local rear=Vector3.new(endX,platformHeight+5.95,Config.DisplayZ+3.95)
        part(root,'DisplayEndFoot',Vector3.new(1.8,.38,9.4),
            CFrame.new(endX,.24,Config.DisplayZ-.3),goldShade)
        part(root,'DisplayEndPost',Vector3.new(1.1,rear.Y,1.1),
            CFrame.new(endX,rear.Y/2,rear.Z),goldShade)
        beam(root,'DisplayEndDiagonal',front,rear,1.15,.48,gold)
        beam(root,'DisplayEndDiagonalHighlight',front+Vector3.new(0,.26,0),
            rear+Vector3.new(0,.26,0),.62,.1,goldLight)
        part(root,'DisplayEndPostCap',Vector3.new(1.55,.28,1.55),
            CFrame.new(endX,rear.Y+.13,rear.Z),goldLight)
        for _,y in {2.1,4.2,6.3} do
            part(root,'EndFrameStud',Vector3.new(.13,.5,.5),
                CFrame.new(endX+side*.62,y,rear.Z),goldLight)
        end
        wheat(root,side,endX)
    end

    -- A shallow cream plinth and separate gold edge finish the existing red
    -- collection floor. No overlay changes its height or the center chute.
    part(root,'TrayFoundation',Vector3.new(tray.Width+2.4,.18,tray.Depth+1.2),
        CFrame.new(0,.13,Config.TrayZ),cream)
    part(root,'TrayFrontGoldEdge',Vector3.new(tray.Width+1,.22,.48),
        CFrame.new(0,1.1,trayFront-.18),goldLight)
    part(root,'TrayFrontRedInlay',Vector3.new(tray.Width,.18,.1),
        CFrame.new(0,.58,trayFront-.66),red)
    for _,side in {-1,1} do
        -- The floor overlaps beneath the belt; raised trim stops at its open front.
        part(root,'TraySideGoldEdge',Vector3.new(.4,.18,rimDepth),
            CFrame.new(side*(halfWidth+.3),1.25,rimCenter),goldLight)
        part(root,'TraySideCreamBand',Vector3.new(.35,.55,rimDepth),
            CFrame.new(side*(halfWidth+.65),.51,rimCenter),creamLight)
        part(root,'TraySideRedInlay',Vector3.new(.1,.18,rimDepth-.5),
            CFrame.new(side*(halfWidth+.87),.6,rimCenter),red)
        for _,z in {trayFront+.3,rimBack-.3} do
            part(root,'TrayCornerCap',Vector3.new(.6,.18,.6),
                CFrame.new(side*(halfWidth+.3),1.43,z),gold)
        end
    end
    return root
end

return Facade
