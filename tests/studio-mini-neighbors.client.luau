-- Isolated native-model fixture. No actual player progress or producers are changed.
local Conveyor=require(game.Players.LocalPlayer.PlayerScripts.Controllers.Conveyor)
local fixture=Instance.new('Folder');fixture.Name='MiniNeighborsQA';fixture.Parent=workspace
local controller={models={},producers={}}
local function add(name,target,ready,landed)
    local model=Instance.new('Model');model.Name=name;model.Parent=fixture
    model:SetAttribute('ConveyorEnd',target);model:SetAttribute('ReadyAt',ready);model:SetAttribute('PlotScale',.65)
    local record={landed=landed,settled=true,rotation=CFrame.identity}
    controller.models[model]=record
    return model,record
end
local old,oldRecord=add('Existing',Vector3.zero,1,true)
local arriving,arrivingRecord=add('Arriving',Vector3.new(1,0,0),10,false)
local remote,remoteRecord=add('OtherFarm',Vector3.new(200,0,0),1,true)
local ok,err=pcall(function()
    Conveyor.update(controller,10)
    assert(oldRecord.jostledAt==10,'Fresh landing must jostle its close landed neighbor')
    assert(not remoteRecord.jostledAt,'Fresh landing must leave other farms alone')
    assert(arrivingRecord.landed,'Fresh arrival must become landed')
    -- Repacking changes attributes; the next landing must use the new positions.
    old:SetAttribute('ConveyorEnd',Vector3.new(201,0,0))
    local nextArrival=add('AfterRepack',Vector3.new(201.5,0,0),10.1,false)
    Conveyor.update(controller,10.1)
    assert(oldRecord.jostledAt==10.1 and remoteRecord.jostledAt==10.1,'Repacked positions must replace previous neighborhood membership')
    assert(not arrivingRecord.jostledAt,'The old farm must not inherit contacts from a stale index')
    local before=oldRecord.jostledAt
    add('StaleArrival',Vector3.new(201.2,0,0),8,false)
    Conveyor.update(controller,11)
    assert(oldRecord.jostledAt==before,'Old arrivals must not replay landing feedback')
    -- An edge exactly 3*scale away retains the original strict comparison.
    local edge,edgeRecord=add('RadiusEdge',Vector3.new(400+1.95,0,0),1,true)
    add('BoundaryArrival',Vector3.new(400,0,0),12,false)
    Conveyor.update(controller,12)
    assert(not edgeRecord.jostledAt,'Jostle boundary must remain strict')
end)
fixture:Destroy()
assert(ok,err)
return 'PASS spatial landing contacts, separate farms, fresh repacks, stale arrivals and strict radius'
