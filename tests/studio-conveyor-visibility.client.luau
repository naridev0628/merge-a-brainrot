-- Fake models/camera only. Does not mutate the live camera, world or controller.
local Conveyor=require(game.Players.LocalPlayer.PlayerScripts.Controllers.Conveyor)
local Visibility=require(game.ReplicatedStorage.Shared.AnimationVisibility)
local camera={CFrame=CFrame.identity,FieldOfView=70,ViewportSize=Vector2.new(1280,720)}
local function group(slot,center)
    local plot={alive=true}
    function plot:IsDescendantOf() return self.alive end
    return {plot=plot,center=center,view={radius=5},schedule=Visibility.new(slot),count=0,update=true}
end
local function controller(groups)
    local c={models={},producers={},groups={},connections={},cameraProvider=function() return camera end}
    for _,g in groups do c.groups[g.plot]=g end
    return c
end
local function add(c,g,target,ready,landed)
    local attributes={ConveyorStart=target+Vector3.new(8,20,12),ConveyorDrop=target+Vector3.new(8,1,10),
        ConveyorCenter=target+Vector3.new(0,.75,10),ConveyorEnd=target,SpawnedAt=ready-4,ReadyAt=ready,
        PlotScale=.65,FinalRotation=CFrame.identity,RestingLift=Vector3.zero}
    local model={Parent=true,reads=0,pivots=0,pose=CFrame.new(attributes.ConveyorStart),attributes=attributes}
    function model:GetAttribute(name) self.reads+=1;return self.attributes[name] end
    function model:GetPivot() return self.pose end
    function model:PivotTo(pose) self.pivots+=1;self.pose=pose end
    local record={rotation=CFrame.identity,settled=landed==true,landed=landed==true,group=g}
    if landed then record.target=target;model.pose=CFrame.new(target) end
    c.models[model]=record
    if g then g.count+=1 end
    return model,record
end
local far=group(1,Vector3.new(0,0,120))
local gated=controller({far})
local model,record=add(gated,far,Vector3.new(0,1,120),4,false)
local producer={Parent=true,pivots=0,pose=CFrame.new(0,5,120)}
function producer:GetAttribute(name)
    return if name=='RestingPivot' then CFrame.new(0,5,120) elseif name=='ProducedAt' then 0 else nil
end
function producer:PivotTo(pose) self.pivots+=1;self.pose=pose end
local producerRecord={active=false,group=far}
gated.producers[producer]=producerRecord;far.count+=1
local baseline=controller({})
baseline.groups=nil -- Existing hand-built fixtures have no visibility/camera state.
local reference=add(baseline,nil,model.attributes.ConveyorEnd,4,false)
for frame=0,120 do
    Conveyor.update(gated,frame/60)
    Conveyor.update(baseline,frame/60)
end
assert(model.pivots>=30 and model.pivots<=32 and reference.pivots==121,'Offscreen transforms must reduce to 15 Hz')
assert(model.reads<reference.reads*.35,'Offscreen gating must avoid attribute reads as well as PivotTo work')
assert(producer.pivots<15 and not producerRecord.active and (producer.pose.Position-Vector3.new(0,5,120)).Magnitude<1e-5,
    'Throttled producer sway must finish at its original resting position')
local farReads,fullReads=model.reads,reference.reads
-- Reenter before the next far sample. Absolute timestamps must put both
-- controllers at the same current trajectory, without replaying missed frames.
camera.CFrame=CFrame.Angles(0,math.pi,0)
local before=model.pivots
Conveyor.update(gated,2.001);Conveyor.update(baseline,2.001)
assert(model.pivots==before+1 and (model.pose.Position-reference.pose.Position).Magnitude<1e-5,
    'Visible reentry must immediately catch up to the full-rate trajectory')

-- Missing camera data preserves old behavior even for a recognized farm.
gated.cameraProvider=function() return nil end
before=model.pivots
for frame=1,10 do Conveyor.update(gated,2.001+frame/60) end
assert(model.pivots==before+10,'Missing CurrentCamera must disable throttling')
gated.cameraProvider=function() return camera end
Conveyor.update(gated,10)
assert(record.landed and record.settled)
camera.CFrame=CFrame.identity
model.attributes.ConveyorEnd+=Vector3.new(4,0,0)
Conveyor.update(gated,10.01)
assert(record.repackAt==10.01,'A changed destination must start repacking on the next eligible sample')
camera.CFrame=CFrame.Angles(0,math.pi,0)
Conveyor.update(gated,10.02)
assert(record.repackAt==10.01,'Reentry must keep the original absolute repack start')
Conveyor.update(gated,10.5)
assert(record.settled and (model.pose.Position-model.attributes.ConveyorEnd).Magnitude<1e-5,
    'A repacked Mini must settle at the authoritative destination')
model.reads=0;model.pivots=0
Conveyor.update(gated,10.6)
assert(model.reads==1 and model.pivots==0,'Visible settled Minis must retain the cheap idle path')

-- All members of a plot share cadence, so a delayed landing still finds its
-- freshly repacked neighbors. Stale landings must not replay contact feedback.
camera.CFrame=CFrame.identity
local contactsGroup=group(1,Vector3.new(0,0,120))
local contacts=controller({contactsGroup})
local older,olderRecord=add(contacts,contactsGroup,Vector3.new(0,1,120),1,true)
local arriving,arrivalRecord=add(contacts,contactsGroup,Vector3.new(1,1,120),20,false)
Conveyor.update(contacts,19.99)
Conveyor.update(contacts,20)
assert(not arrivalRecord.landed and not olderRecord.jostledAt,'Skipped frames must not partially process a plot')
Conveyor.update(contacts,20.04)
assert(arrivalRecord.landed and olderRecord.jostledAt==20.04,'The next eligible sample must retain nearby landing contact')
local previousContact=olderRecord.jostledAt
add(contacts,contactsGroup,Vector3.new(1,1,120),18,false)
camera.CFrame=CFrame.Angles(0,math.pi,0)
Conveyor.update(contacts,20.041)
assert(olderRecord.jostledAt==previousContact,'Reentry must not replay an old landing')
older.attributes.ConveyorEnd=Vector3.new(8,1,120)
add(contacts,contactsGroup,Vector3.new(8.5,1,120),20.1,false)
Conveyor.update(contacts,20.1)
assert(olderRecord.jostledAt==20.1 and not arrivalRecord.jostledAt,'Contact lookup must use fresh repack positions')

contactsGroup.plot.alive=false
Conveyor.update(contacts,20.2)
assert(next(contacts.groups)==nil and next(contacts.models)==nil,'Detached generated worlds must release plot and model references')
gated.tierEffects={destroy=function() end}
Conveyor.destroy(gated);Conveyor.destroy(gated)
assert(next(gated.groups)==nil and next(gated.models)==nil and gated.cameraProvider==nil,
    'Destroy must release cached plot bounds and the camera provider')
return string.format('PASS 15 Hz offscreen transforms, absolute reentry, camera-free fallback, repack/contact/idle preservation and group cleanup; attribute reads %d/%d',farReads,fullReads)
