--!strict
-- Authored scenery stays between the six bridge approaches.
local Factory=require(script.Parent.ModelFactory)
local Environment=require(script.Parent.EnvironmentArt)
local Scenery={}

local function ornament(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3)
    local p=Factory.part(parent,name,size,cf,color)
    p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
    return p
end

local function wheat(parent: Instance,cf: CFrame)
    local gold=Color3.fromRGB(255,191,31)
    for i=1,5 do
        local stem=cf*CFrame.new((i-3)*.85,0,(i%2)*.6)
        local height=2.2+(i%3)*.35
        ornament(parent,'WheatStem',Vector3.new(.22,height,.22),stem*CFrame.new(0,height/2,0),gold)
        for level=1,3 do
            ornament(parent,'WheatHead',Vector3.new(.58,.4,.56),stem*CFrame.new(0,height-.65+level*.35,0),gold:Lerp(Color3.new(1,1,.6),level*.12))
        end
    end
end

function Scenery.build(parent: Instance): Model
    local root=Instance.new('Model');root.Name='HubScenery';root.WorldPivot=CFrame.identity
    root:SetAttribute('AuthoredLayout',true)
    for sector=1,6 do
        local angle=(sector-.5)*math.pi/3
        local cf=CFrame.new(math.sin(angle)*70,0,math.cos(angle)*70)*CFrame.Angles(0,angle,0)
        local garden=Instance.new('Model');garden.Name='Garden'..sector;garden.Parent=root
        if sector~=5 then
            Environment.tree(garden,cf*CFrame.new(-4,0,3),.76+(sector%3)*.1,sector%3+1)
        end
        Factory.prop(garden,'BrickBush',cf*CFrame.new(5,0,-3),1.1)
        Factory.prop(garden,'BrickBush',cf*CFrame.new(8,0,-1),.7)
        if sector%2==0 then
            -- Bring three existing logs into the open grass, with loose
            -- flowers rather than another tree or a full garden ring.
            local clearing=CFrame.new(math.sin(angle)*57,0,math.cos(angle)*57)*CFrame.Angles(0,angle,0)
            Factory.prop(garden,'BrickLog',clearing*CFrame.new(-5,0,0)*CFrame.Angles(0,.35,0),1.1)
            for _,flower in {{-1.7,-2.4,.9},{.1,-1.1,1.1},{1.6,-2.6,.85}} do
                Factory.prop(garden,'BrickFlower',clearing*CFrame.new(flower[1],0,flower[2]),flower[3])
            end
        else
            Factory.prop(garden,'BrickLog',cf*CFrame.new(1,0,-7)*CFrame.Angles(0,.35,0),.8)
        end
        wheat(garden,cf*CFrame.new(-7,0,-6))
        for flower=1,4 do
            Factory.prop(garden,'BrickFlower',cf*CFrame.new(2+flower*1.25,0,-8+(flower%2)*1.1),.75+(flower%2)*.15)
        end
        -- Low accents near the plaza do not screen the leaderboard text.
        local inner=CFrame.new(math.sin(angle)*45,0,math.cos(angle)*45)*CFrame.Angles(0,angle,0)
        Factory.prop(garden,'BrickBush',inner,if sector%2==1 then 1.45 else .85)
        if sector%2==1 then Factory.prop(garden,'BrickBush',inner*CFrame.new(-3.6,0,1.2),.8) end
        Factory.prop(garden,'BrickGrass',inner*CFrame.new(3,0,1.4),1)
        for flower=1,3 do Factory.prop(garden,'BrickFlower',inner*CFrame.new(flower-2,0,-2.4),.7) end
    end
    Environment.lighthouse(root,CFrame.new(-62,0,-62)*CFrame.Angles(0,math.pi/4,0),.7)
    for _,position in {Vector3.new(-76,0,0),Vector3.new(76,0,0)} do
        local facing=CFrame.lookAt(position,Vector3.new(0,0,0))
        Factory.prop(root,'BrickBarn',facing,.75)
        Factory.prop(root,'CoolTralalero',facing*CFrame.new(7,0,-7),.55)
    end
    for index,position in {Vector3.new(-67,-4.4,86),Vector3.new(67,-4.4,-86),Vector3.new(190,-4.4,112)} do
        Factory.prop(root,'BrickRockIsland',CFrame.new(position)*CFrame.Angles(0,index*.9,0),1.25)
        Factory.prop(root,'BrickLilyPad',CFrame.new(position+Vector3.new(10,0,4)),1.2)
        Factory.prop(root,'BrickLilyPad',CFrame.new(position+Vector3.new(-6,0,-8)),.9)
    end
    root.Parent=parent
    return root
end

return table.freeze(Scenery)
