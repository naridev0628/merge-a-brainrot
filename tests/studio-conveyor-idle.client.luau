local Conveyor=require(game.Players.LocalPlayer.PlayerScripts.Controllers.Conveyor)
local target=Vector3.new(3,1,4)
local attributes={
    ConveyorStart=Vector3.new(0,7,0),ConveyorDrop=Vector3.new(0,1,0),
    ConveyorCenter=Vector3.zero,ConveyorEnd=target,
    SpawnedAt=0,ReadyAt=4,PlotScale=.65,FinalRotation=CFrame.identity,RestingLift=Vector3.zero,
}
local reads,pivots=0,0
local pose=CFrame.new(target)
local model={Parent=true}
function model:GetAttribute(name) reads+=1;return attributes[name] end
function model:GetPivot() return pose end
function model:PivotTo(value) pivots+=1;pose=value end
local record={landed=true,settled=true,rotation=CFrame.identity,target=target}
local controller={models={[model]=record},producers={}}
Conveyor.update(controller,10)
assert(reads<=1 and pivots==0,'Settled minis should only check their destination, with no transform or other attribute work')
attributes.ConveyorEnd=Vector3.new(8,1,4)
Conveyor.update(controller,10.1)
assert(record.repackAt==10.1,'A changed destination must still start a repack')
Conveyor.update(controller,10.6)
assert((pose.Position-attributes.ConveyorEnd).Magnitude<.001,'Repack must settle at the authoritative destination')
local before=pivots
record.jostledAt=10.7
Conveyor.update(controller,10.8)
assert(pivots>before,'A new landing contact must wake a settled mini')
Conveyor.update(controller,11.2)
reads=0;pivots=0
Conveyor.update(controller,11.3)
assert(reads<=1 and pivots==0,'Settled minis must return to the cheap idle path after contact animation')
return 'PASS cheap idle path preserves repacking, landing contacts and return to rest'
