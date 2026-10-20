--!strict
local Collection=game:GetService('CollectionService')
local MiniMotion=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('MiniMotion'))
local TierEffects=require(script.Parent:WaitForChild('TierEffects'))
local Conveyor={}; Conveyor.__index=Conveyor
local function smooth(t: number): number
    return t*t*(3-2*t)
end
function Conveyor.new()
    local self: any=setmetatable({models={},producers={},tierEffects=TierEffects.new()},Conveyor)
    local function add(instance: Instance)
        if instance:IsA('Model') then self.models[instance]={rotation=instance:GetPivot().Rotation,settled=false,landed=false} end
    end
    for _,m in Collection:GetTagged('ConveyorMini') do add(m) end
    Collection:GetInstanceAddedSignal('ConveyorMini'):Connect(add)
    Collection:GetInstanceRemovedSignal('ConveyorMini'):Connect(function(m) self.models[m]=nil end)
    local function addProducer(instance: Instance)
        if instance:IsA('Model') then self.producers[instance]={active=false} end
    end
    for _,m in Collection:GetTagged('BrainrotProducer') do addProducer(m) end
    Collection:GetInstanceAddedSignal('BrainrotProducer'):Connect(addProducer)
    Collection:GetInstanceRemovedSignal('BrainrotProducer'):Connect(function(m) self.producers[m]=nil;self.tierEffects:remove(m) end)
    return self
end
function Conveyor.update(self: any,now: number)
    if self.tierEffects then self.tierEffects:update(self.producers,now) end
    -- Nearby settled minis give slightly when an arriving mini joins the pile.
    -- This is a brief visual contact response; final pickup centers stay fixed.
    for model,record in self.models do
        local ready=model:GetAttribute('ReadyAt')
        local target=model:GetAttribute('ConveyorEnd')
        if not record.landed and ready and target and now>=ready then
            record.landed=true
            if now-ready<.45 then
                local scale=model:GetAttribute('PlotScale') or .5
                for neighbor,other in self.models do
                    local otherTarget=neighbor:GetAttribute('ConveyorEnd')
                    if neighbor~=model and other.landed and otherTarget and (otherTarget-target).Magnitude<3*scale then
                        other.jostledAt=now
                    end
                end
            end
        end
    end
    for model,record in self.models do
        if not model.Parent then continue end
        local start=model:GetAttribute('ConveyorStart'); local drop=model:GetAttribute('ConveyorDrop')
        local center=model:GetAttribute('ConveyorCenter'); local target=model:GetAttribute('ConveyorEnd')
        local spawned=model:GetAttribute('SpawnedAt'); local ready=model:GetAttribute('ReadyAt')
        if not start or not drop or not center or not target or not spawned or not ready then continue end
        local scale=model:GetAttribute('PlotScale') or .5
        local finalRotation=model:GetAttribute('FinalRotation') or record.rotation
        local t=MiniMotion.progress(now,spawned,ready)
        if not t then continue end
        local phase,alpha,lift=MiniMotion.phase(t)
        local floorOffset=if model:GetAttribute('FinalRotation') then (model:GetAttribute('RestingLift') or Vector3.zero)*math.clamp((t-.77)/.23,0,1) else model:GetAttribute('FloorOffset') or Vector3.zero
        if record.target and record.target~=target and t>=1 then
            record.repackFrom=model:GetPivot(); record.repackAt=now; record.settled=false
        end
        record.target=target
        local point: Vector3; local rotation: CFrame
        local fallen=record.rotation*CFrame.Angles(0,.65,1.2)
        if phase==1 then
            local fall=math.sqrt(alpha)
            point=start:Lerp(drop,alpha)
            rotation=record.rotation*CFrame.Angles(fall*math.pi*2,fall*.65,fall*1.2)
        elseif phase==2 then
            local slide=alpha
            point=drop:Lerp(center,slide)
            rotation=fallen*CFrame.Angles(math.sin(slide*18)*.08,slide*.4,math.sin(slide*13)*.08)
        elseif phase==3 then
            local arc=alpha
            point=center:Lerp(target,arc)+Vector3.new(0,lift*scale,0)
            rotation=(fallen*CFrame.Angles(0,.4,0)):Lerp(finalRotation,smooth(arc))*CFrame.Angles(math.sin(arc*math.pi)*math.pi*2,0,0)
        else
            local elapsed=now-ready
            point=target; rotation=finalRotation
            if record.repackAt then
                local settle=math.clamp((now-record.repackAt)/.42,0,1)
                local pose=record.repackFrom:Lerp(CFrame.new(target+floorOffset)*finalRotation,smooth(settle))
                point=pose.Position-floorOffset; rotation=pose.Rotation
                if settle>=1 then record.repackAt=nil end
            elseif elapsed<.42 then
                local settle=elapsed/.42
                point+=Vector3.new(0,math.abs(math.sin(settle*math.pi*2))*(1-settle)*.35*scale,0)
                rotation*=CFrame.Angles(math.sin(settle*math.pi*3)*(1-settle)*.16,0,0)
            end
            if record.jostledAt then
                local jostle=math.clamp((now-record.jostledAt)/.35,0,1)
                local amount=math.sin(jostle*math.pi*2)*(1-jostle)
                point+=Vector3.new(amount*.14*scale,math.abs(amount)*.08*scale,0)
                rotation*=CFrame.Angles(0,0,amount*.09)
                if jostle>=1 then record.jostledAt=nil end
            end
            if record.settled and not record.repackAt and not record.jostledAt then continue end
            record.settled=elapsed>=.42 and not record.repackAt and not record.jostledAt
        end
        model:PivotTo(CFrame.new(point+floorOffset)*rotation)
    end
    for model,record in self.producers do
        if not model.Parent then continue end
        local rest=model:GetAttribute('RestingPivot'); local produced=model:GetAttribute('ProducedAt')
        if not rest or not produced then continue end
        local elapsed=now-produced
        if elapsed>=0 and elapsed<.55 then
            local sway=math.sin(elapsed/.55*math.pi)
            -- Turn gently around the vertical axis; feet stay on the brick stand.
            model:PivotTo(CFrame.new(rest.Position)*CFrame.Angles(0,sway*.06,0)*rest.Rotation)
            record.active=true
        elseif record.active then
            model:PivotTo(rest); record.active=false
        end
    end
end
return Conveyor
