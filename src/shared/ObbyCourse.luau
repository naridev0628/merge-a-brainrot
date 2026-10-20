--!strict
-- Original native-brick course. ObbyConfig owns every landing footprint and
-- top height; decoration never changes the server-sampled jump route.
local Config=require(script.Parent.ObbyConfig)
local Style=require(script.Parent.TextStyle)
local Course={}
local orange=Color3.fromRGB(255,157,34)
local orangeLight=Color3.fromRGB(255,184,69)
local darkOrange=Color3.fromRGB(207,104,24)
local cream=Color3.fromRGB(255,238,182)
local cyan=Color3.fromRGB(25,190,217)
local gold=Color3.fromRGB(255,215,40)
local navy=Color3.fromRGB(29,48,63)

local function part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,solid: boolean?): Part
    local block=Instance.new('Part')
    block.Name=name;block.Size=size;block.CFrame=cf;block.Color=color
    block.Material=Enum.Material.Plastic;block.Anchored=true
    block.CanCollide=solid==true;block.CanQuery=solid==true;block.CanTouch=false
    block.TopSurface=Enum.SurfaceType.Smooth;block.BottomSurface=Enum.SurfaceType.Smooth
    block.Parent=parent
    return block
end
local function surface(block: BasePart,name: string,value: string,face: Enum.NormalId,color: Color3)
    local gui=Instance.new('SurfaceGui')
    gui.Name=name;gui.Face=face;gui.CanvasSize=Vector2.new(300,150)
    gui.LightInfluence=0;gui.AlwaysOnTop=false;gui.MaxDistance=90;gui.Parent=block
    local text=Instance.new('TextLabel')
    text.Name='Text';text.BackgroundTransparency=1;text.Size=UDim2.fromScale(1,1)
    text.Text=value;text.TextScaled=true;text.TextWrapped=false;text.Parent=gui
    Style.apply(text,52,color,3)
    local padding=Instance.new('UIPadding')
    padding.PaddingLeft=UDim.new(.15,0);padding.PaddingRight=UDim.new(.15,0)
    padding.PaddingTop=UDim.new(.12,0);padding.PaddingBottom=UDim.new(.12,0);padding.Parent=text
    return gui
end
local function landing(root: Instance,decor: Instance,name: string,spec: any,index: number): Part
    local finish=index>#Config.Checkpoints
    local color=if finish then gold elseif index==1 then cyan elseif index%2==0 then orangeLight else orange
    -- Keep the broad finish slab light; the smaller steps have deeper bases.
    local height=if finish then 1 else 1.35
    local block=part(root,name,Vector3.new(spec.halfX*2,height,spec.halfZ*2),
        CFrame.new(spec.x,spec.y-height/2,spec.z),color,true)
    block.TopSurface=Enum.SurfaceType.Studs
    block:SetAttribute('ObbyCheckpoint',index)
    local center=CFrame.new(spec.x,spec.y,spec.z)
    if not finish then
        part(decor,'InsetBrickBase',Vector3.new(spec.halfX*2-.5,.28,spec.halfZ*2-.5),
            center*CFrame.new(0,-height-.14,0),darkOrange)
    end
    -- Four narrow side bands leave the entire original top surface clear.
    for _,side in {-1,1} do
        if not finish or side==-1 then
            part(decor,'LandingRim',Vector3.new(spec.halfX*2,.18,.12),
                center*CFrame.new(0,-.31,side*(spec.halfZ+.04)),cream)
            part(decor,'LandingRim',Vector3.new(.12,.18,spec.halfZ*2),
                center*CFrame.new(side*(spec.halfX+.04),-.31,0),cream)
        end
    end
    for _,x in {-1,1} do for _,z in {-1,1} do
        local studX=if finish then -2.75+x*1.25 else x*(spec.halfX-.5)
        local studZ=if finish then -2.75+z*1.25 else z*(spec.halfZ-.5)
        local stud=part(decor,'CornerStud',Vector3.new(.48,.12,.48),
            center*CFrame.new(studX,.06,studZ),cream)
        stud.TopSurface=Enum.SurfaceType.Studs
    end end
    if finish then
        surface(block,'FinishText','FINISH',Enum.NormalId.Top,navy)
    else
        local number=surface(block,'StepNumber',tostring(index),Enum.NormalId.Top,Color3.new(1,1,1))
        number.CanvasSize=Vector2.new(200,200)
        surface(block,'StepNumberFront',tostring(index),Enum.NormalId.Front,cream)
        surface(block,'StepNumberBack',tostring(index),Enum.NormalId.Back,cream)
    end
    return block
end
function Course.build(root: Instance): Model
    local decor=Instance.new('Model')
    decor.Name='ObbyCourse';decor.WorldPivot=CFrame.identity;decor:SetAttribute('NativeBrickArt',true);decor.Parent=root
    for index,spec in Config.Checkpoints do
        landing(root,decor,'ParkourStep'..index,spec,index)
    end
    local finish=landing(root,decor,'ParkourFinish',Config.Finish,#Config.Checkpoints+1)
    local first=Config.Checkpoints[1]
    local outward=Vector3.new(first.x,0,first.z).Unit
    local startPosition=outward*21+Vector3.new(0,.49,0)
    local startFrame=CFrame.lookAt(startPosition,Vector3.new(first.x,.49,first.z))
    local marker=part(decor,'StartMarker',Vector3.new(6.6,.08,4.2),startFrame,cyan)
    surface(marker,'StartText','START',Enum.NormalId.Top,Color3.new(1,1,1))
    -- Flat chevrons lead to the first jump; no doorway, posts or arch on its arc.
    for index=1,2 do
        for _,side in {-1,1} do
            part(decor,'StartChevron',Vector3.new(1.15,.06,.24),
                startFrame*CFrame.new(side*.39,.07,-2.8-index*.65)*CFrame.Angles(0,side*-.6,0),cream)
        end
    end
    -- The last jump arrives from the outside of the spiral. Keep the flag on
    -- the inward corner, away from both the approach and the landing center.
    local flagBase=Vector3.new(Config.Finish.x-3.35,Config.Finish.y,Config.Finish.z-3.35)
    part(decor,'FinishFlagFoot',Vector3.new(.9,.22,.9),CFrame.new(flagBase+Vector3.new(0,.11,0)),orange)
    part(decor,'FinishFlagPole',Vector3.new(.18,5.4,.18),CFrame.new(flagBase+Vector3.new(0,2.7,0)),cream)
    part(decor,'FinishFlagCap',Vector3.new(.34,.34,.34),CFrame.new(flagBase+Vector3.new(0,5.5,0)),gold)
    local flag=part(decor,'FinishFlag',Vector3.new(2.25,1.35,.12),CFrame.new(flagBase+Vector3.new(-1.12,4.38,0)),cyan)
    surface(flag,'FlagFront','★',Enum.NormalId.Front,cream)
    surface(flag,'FlagBack','★',Enum.NormalId.Back,cream)
    local reward=Instance.new('BillboardGui')
    reward.Name='RewardLabel';reward.Size=UDim2.fromOffset(250,35);reward.StudsOffset=Vector3.new(0,3.3,0)
    reward.MaxDistance=90;reward.AlwaysOnTop=false;reward.Parent=finish
    local text=Instance.new('TextLabel')
    text.Name='Text';text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1
    text.Text=string.format('+%.2fx Minis for %dm',Config.BonusHundredths/100,Config.BoostSeconds/60)
    text.TextScaled=true;text.Parent=reward;Style.apply(text,25,cream,2)
    return decor
end
return table.freeze(Course)
