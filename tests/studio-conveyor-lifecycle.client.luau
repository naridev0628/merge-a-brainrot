-- Isolated controller ownership test; original player's controller stays active.
local Collection=game:GetService('CollectionService')
local Conveyor=require(game.Players.LocalPlayer.PlayerScripts.Controllers.Conveyor)
local controller=Conveyor.new()
local connections=table.clone(controller.connections)
local fixture=Instance.new('Model')
fixture.Name='ConveyorLifecycleQA'
fixture.Parent=workspace
local piece=Instance.new('Part')
piece.Anchored=true;piece.Position=Vector3.new(0,500,0);piece.Parent=fixture
local ok,err=pcall(function()
    Collection:AddTag(fixture,'ConveyorMini')
    task.wait()
    assert(controller.models[fixture],'Controller must subscribe to new mini tags')
    assert(#connections==4,'Controller must own its four tag subscriptions')
    controller:destroy()
    controller:destroy()
    for _,connection in connections do assert(not connection.Connected,'Destroy must disconnect every tag subscription') end
    assert(next(controller.models)==nil and next(controller.producers)==nil,'Destroy must release model references')
    assert(next(controller.tierEffects.effects)==nil,'Destroy must release native accent geometry')
    Collection:RemoveTag(fixture,'ConveyorMini')
    Collection:AddTag(fixture,'ConveyorMini')
    Collection:AddTag(fixture,'BrainrotProducer')
    task.wait()
    assert(next(controller.models)==nil and next(controller.producers)==nil,'Destroyed controller must not receive future tags')
    controller:update(os.clock())
end)
controller:destroy()
fixture:Destroy()
assert(ok,err)
return 'PASS Conveyor disconnects all tag subscriptions, releases references, ignores later tags and safely repeats destroy'
