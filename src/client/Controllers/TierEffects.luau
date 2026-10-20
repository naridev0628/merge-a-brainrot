--!strict
-- Sparse native accents. Never parent geometry into producers: their bounds and
-- resting pivots remain authoritative for grounded feet and nameplate clearance.
local Catalog=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('CreatureCatalog'))
local TierEffects={};TierEffects.__index=TierEffects
function TierEffects.new()
    return setmetatable({effects={},nextUpdate=0},TierEffects)
end
function TierEffects.remove(self: any,model: Model)
    local effect=self.effects[model]
    if effect then effect.folder:Destroy();self.effects[model]=nil end
end
function TierEffects.destroy(self: any)
    for model in self.effects do self:remove(model) end
end
function TierEffects.update(self: any,producers: {[Model]: any},now: number,origin: Vector3?)
    if now<self.nextUpdate then return end
    self.nextUpdate=now+.1
    local camera=workspace.CurrentCamera
    local eye=origin or (if camera then camera.CFrame.Position else Vector3.zero)
    local candidates={}
    for model in producers do
        if not model.Parent then continue end
        local species=Catalog[model:GetAttribute('SpeciesId')]
        local tier=if species then species.tier else model:GetAttribute('Tier')
        if typeof(tier)~='number' or tier<4 then continue end
        local distance=(model:GetPivot().Position-eye).Magnitude
        if distance<90 then table.insert(candidates,{model=model,tier=tier,distance=distance}) end
    end
    table.sort(candidates,function(a,b)return a.distance<b.distance end)
    local selected={}
    for index=1,math.min(16,#candidates) do selected[candidates[index].model]=candidates[index] end
    -- Remove before creating, so even a camera teleport stays within 32 parts.
    for model,effect in self.effects do
        local choice=selected[model]
        if not choice or choice.tier~=effect.tier then self:remove(model) end
    end
    for model,choice in selected do
        local effect=self.effects[model]
        local rest=model:GetAttribute('RestingPivot') or model:GetPivot()
        if not effect then
            local box,size=model:GetBoundingBox()
            local right,up,look=box.RightVector,box.UpVector,box.LookVector
            size=Vector3.new(math.abs(right.X),math.abs(right.Y),math.abs(right.Z))*size.X
                +Vector3.new(math.abs(up.X),math.abs(up.Y),math.abs(up.Z))*size.Y
                +Vector3.new(math.abs(look.X),math.abs(look.Y),math.abs(look.Z))*size.Z
            local folder=Instance.new('Folder');folder.Name='ProducerTierAccent';folder:SetAttribute('Tier',choice.tier);folder.Parent=workspace
            local pieces={}
            for index=1,2 do
                local part=Instance.new('Part');part.Name=if choice.tier==4 then 'Bubble' elseif choice.tier==5 then 'Mote' else 'Glint'
                part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.CastShadow=false
                part.Shape=if choice.tier==6 then Enum.PartType.Block else Enum.PartType.Ball
                part.Material=Enum.Material.Neon
                part.Color=if choice.tier==4 then Color3.fromRGB(117,214,255) elseif choice.tier==5 then Color3.fromRGB(255,239,191) else Color3.fromRGB(228,255,116)
                part.Size=Vector3.one*(if choice.tier==4 then .26 else .16);part.Transparency=.45;part.Parent=folder
                table.insert(pieces,part)
            end
            effect={folder=folder,parts=pieces,tier=choice.tier,size=size,offset=box.Position-rest.Position,phase=choice.distance*.17}
            self.effects[model]=effect
        end
        local center=rest.Position+effect.offset
        local size=effect.size
        local floor=center.Y-size.Y/2
        for index,part in effect.parts do
            local cycle=(now*.35+effect.phase+index*.5)%1
            local side=if index==1 then -1 else 1
            local x=center.X+side*(size.X*.42+.14)+math.sin(cycle*math.pi*2)*.1
            -- Fade before reaching the shoulders; labels sit above the model.
            local y=floor+size.Y*(.16+cycle*.42)
            part.CFrame=CFrame.new(x,y,center.Z-size.Z*.22)*CFrame.Angles(0,now*.5,math.pi/4)
            part.Transparency=.32+.68*math.abs(cycle*2-1)
        end
    end
end
return TierEffects
