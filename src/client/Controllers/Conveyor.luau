--!strict
local Collection=game:GetService('CollectionService')
local MiniMotion=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('MiniMotion'))
local MiniNeighborIndex=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('MiniNeighborIndex'))
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Visibility=require(Shared:WaitForChild('AnimationVisibility'))
local bounds=Visibility.bounds(require(Shared:WaitForChild('Config')))
local TierEffects=require(script.Parent:WaitForChild('TierEffects'))
local Conveyor={}; Conveyor.__index=Conveyor
local function smooth(t: number): number
    return t*t*(3-2*t)
end
local function releaseGroup(self: any,record: any)
    local group=record and record.group
    if not group then return end
    group.count-=1
    if group.count<=0 then self.groups[group.plot]=nil end
end
local function groupFor(self: any,instance: Instance): any
    local folder=instance.Parent
    if not folder or (folder.Name~='Minis' and folder.Name~='Producers') then return nil end
    local plot=folder.Parent
    local id=plot and tonumber(plot.Name:match('^Plot(%d+)$'))
    if not plot or not plot:IsA('Model') or not id then return nil end
    local group=self.groups[plot]
    if not group then
        -- Farm transforms are fixed; cache a padded sphere once instead of
        -- projecting hundreds of moving model bounds on every render frame.
        group={plot=plot,count=0,update=true,schedule=Visibility.new(id),
            center=plot:GetPivot():PointToWorldSpace(Vector3.new(bounds.x,bounds.y,bounds.z)),
            view={radius=bounds.radius}}
        self.groups[plot]=group
    end
    group.count+=1
    return group
end
local function updateGroups(self: any,now: number)
    if not self.groups then return end -- Hand-built/no-camera fixtures keep the original path.
    local camera=self.cameraProvider and self.cameraProvider()
    local viewport=camera and camera.ViewportSize
    local usable=camera and viewport.X>0 and viewport.Y>0
    local tangent=if usable then math.tan(math.rad(math.min(85,camera.FieldOfView/2+Visibility.AngularPadding))) else 0
    local aspect=if usable then viewport.X/viewport.Y else 1
    for plot,group in self.groups do
        if not plot:IsDescendantOf(workspace) then
            -- Also handle a detached generated world whose tags still exist.
            for model,record in self.models do if record.group==group then self.models[model]=nil end end
            for model,record in self.producers do if record.group==group then
                self.producers[model]=nil
                if self.tierEffects then self.tierEffects:remove(model) end
            end end
            self.groups[plot]=nil
            continue
        end
        local fullRate=true
        if usable then
            local offset=camera.CFrame:PointToObjectSpace(group.center)
            local view=group.view
            view.x=offset.X;view.y=offset.Y;view.depth=-offset.Z
            view.tangent=tangent;view.aspect=aspect
            fullRate=Visibility.fullRate(view)
        end
        group.update=Visibility.shouldUpdate(group.schedule,now,fullRate)
    end
end
function Conveyor.new(cameraProvider: (() -> Camera?)?)
    local self: any=setmetatable({models={},producers={},groups={},connections={},tierEffects=TierEffects.new(),destroyed=false,
        cameraProvider=cameraProvider or function() return workspace.CurrentCamera end},Conveyor)
    local function add(instance: Instance)
        if instance:IsA('Model') then
            releaseGroup(self,self.models[instance])
            self.models[instance]={rotation=instance:GetPivot().Rotation,settled=false,landed=false,group=groupFor(self,instance)}
        end
    end
    for _,m in Collection:GetTagged('ConveyorMini') do add(m) end
    table.insert(self.connections,Collection:GetInstanceAddedSignal('ConveyorMini'):Connect(add))
    table.insert(self.connections,Collection:GetInstanceRemovedSignal('ConveyorMini'):Connect(function(m)
        releaseGroup(self,self.models[m]);self.models[m]=nil
    end))
    local function addProducer(instance: Instance)
        if instance:IsA('Model') then
            releaseGroup(self,self.producers[instance])
            self.producers[instance]={active=false,group=groupFor(self,instance)}
        end
    end
    for _,m in Collection:GetTagged('BrainrotProducer') do addProducer(m) end
    table.insert(self.connections,Collection:GetInstanceAddedSignal('BrainrotProducer'):Connect(addProducer))
    table.insert(self.connections,Collection:GetInstanceRemovedSignal('BrainrotProducer'):Connect(function(m)
        releaseGroup(self,self.producers[m]);self.producers[m]=nil;self.tierEffects:remove(m)
    end))
    return self
end
function Conveyor.destroy(self: any)
    if self.destroyed then return end
    self.destroyed=true
    for _,connection in self.connections do connection:Disconnect() end
    table.clear(self.connections)
    self.tierEffects:destroy()
    for model,record in self.producers do
        local rest=model:GetAttribute('RestingPivot')
        if record.active and rest and model.Parent then model:PivotTo(rest) end
    end
    table.clear(self.models)
    table.clear(self.producers)
    table.clear(self.groups)
    self.cameraProvider=nil
end
function Conveyor.update(self: any,now: number)
    if self.destroyed then return end
    updateGroups(self,now)
    if self.tierEffects then self.tierEffects:update(self.producers,now) end
    -- Nearby settled minis give slightly when an arriving mini joins the pile.
    -- This is a brief visual contact response; final pickup centers stay fixed.
    local neighbors: any=nil
    for model,record in self.models do
        if record.group and not record.group.update then continue end
        if record.landed then continue end
        local ready=model:GetAttribute('ReadyAt')
        local target=model:GetAttribute('ConveyorEnd')
        if not record.landed and ready and target and now>=ready then
            record.landed=true
            if neighbors then neighbors:insert(record,target.X,target.Y,target.Z) end
            if now-ready<.45 then
                local scale=model:GetAttribute('PlotScale') or .5
                if not neighbors then
                    -- Build once only when a fresh landing needs contact feedback.
                    -- Other farms are spatially distant and never need pair checks.
                    neighbors=MiniNeighborIndex.new(2)
                    for neighbor,other in self.models do
                        if other.group and not other.group.update then continue end
                        local otherTarget=neighbor:GetAttribute('ConveyorEnd')
                        if other.landed and otherTarget then
                            neighbors:insert(other,otherTarget.X,otherTarget.Y,otherTarget.Z)
                        end
                    end
                end
                local nearby=neighbors:query(target.X,target.Y,target.Z,3*scale)
                for _,other in nearby do
                    if other~=record then other.jostledAt=now end
                end
            end
        end
    end
    for model,record in self.models do
        if record.group and not record.group.update then continue end
        if not model.Parent then continue end
        local target=model:GetAttribute('ConveyorEnd')
        -- Settled geometry only wakes for a destination change or contact
        -- animation. Fixed spawn/rotation attributes need no per-frame reads.
        if record.settled and not record.repackAt and not record.jostledAt and record.target==target then continue end
        local start=model:GetAttribute('ConveyorStart'); local drop=model:GetAttribute('ConveyorDrop')
        local center=model:GetAttribute('ConveyorCenter')
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
        if record.group and not record.group.update then continue end
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
