--!strict
-- TEST ONLY. Install as a LocalScript in a temporary Play session with Main.client
-- disabled. Uses production Conveyor.new/update/destroy without a FarmNetwork.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsClient(),'Capacity harness is Studio client only')
local player=game:GetService('Players').LocalPlayer
local scripts=player:WaitForChild('PlayerScripts')
local main=scripts:FindFirstChild('Main')
assert(not main or not main:IsA('LocalScript') or main.Disabled,'Disable Main.client before the test Play session')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Config=require(Shared.Config)
local Conveyor=require(scripts:WaitForChild('Controllers'):WaitForChild('Conveyor'))
assert(type(Conveyor.destroy)=='function','Sync Conveyor.destroy before running this harness')
local Collection=game:GetService('CollectionService')
local Stats=game:GetService('Stats')
local server=assert(game:GetService('ReplicatedStorage'):WaitForChild('CapacityHarness',20),'Install the server harness first')
local snapshot=server:WaitForChild('Snapshot') :: RemoteEvent
local parent=player:WaitForChild('PlayerGui')
assert(not parent:FindFirstChild('CapacityHarnessClientControl'),'A client capacity harness is already installed')
local control=Instance.new('BindableFunction');control.Name='CapacityHarnessClientControl';control.Parent=parent
local status=Instance.new('Folder');status.Name='CapacityHarnessClient';status.Parent=parent
local Controller={}
local conveyor: any=nil
local connections: {RBXScriptConnection}={}
local cameraBackup: any=nil
local cameraMode='farm1'
local cameraStarted=0
local sampling: any=nil
local lastSample: any=nil
local latestSnapshot: any=nil
local receivedSnapshots=0
local receivedEntities=0
local function inventory(): any
    local counts={instances=0,parts=0,meshes=0,shelfParts=0,producerParts=0,miniParts=0}
    local world=workspace:FindFirstChild('MergeABrainrotGenerated')
    if world then for _,item in world:GetDescendants() do
        counts.instances+=1
        if item:IsA('BasePart') then
            counts.parts+=1
            if item:IsA('MeshPart') then counts.meshes+=1 end
            if item:FindFirstAncestor('StackRows') then counts.shelfParts+=1
            elseif item:FindFirstAncestor('Producers') then counts.producerParts+=1
            elseif item:FindFirstAncestor('Minis') then counts.miniParts+=1 end
        end
    end end
    counts.producerModels=#Collection:GetTagged('BrainrotProducer')
    counts.miniModels=#Collection:GetTagged('ConveyorMini')
    counts.accentParts=0
    for _,item in workspace:GetChildren() do
        if item.Name=='ProducerTierAccent' then counts.accentParts+=#item:GetChildren() end
    end
    return counts
end
local function farmCamera(id: number): CFrame?
    local world=workspace:FindFirstChild('MergeABrainrotGenerated')
    local plot=world and world:FindFirstChild('Plot'..id)
    if not plot or not plot:IsA('Model') then return nil end
    local frame=plot:GetPivot()
    return CFrame.lookAt(frame:PointToWorldSpace(Vector3.new(70,48,32)*Config.PlotScale),
        frame:PointToWorldSpace(Vector3.new(0,20,Config.DisplayZ)*Config.PlotScale))
end
local function updateCamera(now: number)
    local camera=workspace.CurrentCamera
    if not camera then return end
    if cameraMode=='overview' then
        camera.CFrame=CFrame.lookAt(Vector3.new(240,190,240),Vector3.new(0,15,0))
    elseif cameraMode=='route' then
        -- One repeatable 60-second circuit through the same six farm views.
        local phase=((now-cameraStarted)%60)/10
        local index=math.floor(phase)+1
        local a,b=farmCamera(index),farmCamera(index%6+1)
        if a and b then
            local t=phase%1
            camera.CFrame=a:Lerp(b,t*t*(3-2*t))
        end
    else
        local pose=farmCamera(tonumber(cameraMode:sub(5)) or 1)
        if pose then camera.CFrame=pose end
    end
    camera.Focus=CFrame.new(camera.CFrame.Position+camera.CFrame.LookVector*80)
end
local function percentile(sample: any,fraction: number): number
    local target=math.ceil(sample.frames*fraction)
    local count=0
    for index,value in sample.histogram do
        count+=value
        if count>=target then return if index==513 then sample.maxMs else index*.25 end
    end
    return sample.maxMs
end
local function finishSample(sample: any)
    lastSample={
        capacity=sample.capacity,epoch=sample.epoch,churn=sample.churn,camera=sample.camera,
        snapshotsEnabled=sample.snapshotsEnabled,
        sampleSeconds=os.clock()-sample.started,frames=sample.frames,
        meanFrameMs=sample.totalMs/sample.frames,maxFrameMs=sample.maxMs,
        p50FrameMs=percentile(sample,.50),p95FrameMs=percentile(sample,.95),p99FrameMs=percentile(sample,.99),
        meanConveyorWorkMs=sample.workMs/sample.frames,maxConveyorWorkMs=sample.maxWorkMs,
        memoryBeforeMb=sample.memoryBefore,memoryAfterMb=Stats:GetTotalMemoryUsageMb(),
        before=sample.before,after=inventory(),
        snapshotsReceived=receivedSnapshots-sample.snapshotsBefore,
        snapshotEntitiesReceived=receivedEntities-sample.entitiesBefore,
        note='Frame percentiles use fixed 0.25 ms bins; overflow above 128 ms uses observed max. Main HUD/audio, real player commands and UI snapshot work are excluded.',
    }
    status:SetAttribute('SampleStatus','Complete')
    for key,value in lastSample do if type(value)=='number' then status:SetAttribute(key,value) end end
end
function Controller.camera(mode: string)
    assert(mode=='overview' or mode=='route' or mode:match('^farm[1-6]$'),'Camera must be overview, route or farm1..farm6')
    if sampling then sampling=nil;status:SetAttribute('SampleStatus','Cancelled: camera changed') end
    cameraMode=mode;cameraStarted=os.clock()
    status:SetAttribute('Camera',mode)
end
function Controller.start(mode: string?): any
    if conveyor then return {status='Running'} end
    Controller.camera(mode or 'farm1')
    local camera=assert(workspace.CurrentCamera)
    cameraBackup={camera=camera,type=camera.CameraType,frame=camera.CFrame,focus=camera.Focus,subject=camera.CameraSubject,fov=camera.FieldOfView}
    camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=60
    conveyor=Conveyor.new()
    table.insert(connections,snapshot.OnClientEvent:Connect(function(state)
        latestSnapshot=state;receivedSnapshots+=1;receivedEntities+=#state.producers+#state.tokens
    end))
    table.insert(connections,server.AncestryChanged:Connect(function()
        if not server.Parent then Controller.stop() end
    end))
    table.insert(connections,RunService.RenderStepped:Connect(function(delta)
        local now=os.clock()
        updateCamera(now)
        local workStarted=os.clock()
        -- The server seeds and steps Core with GetServerTimeNow, whose clock is
        -- synchronized on clients. Never compare these timestamps to os.clock().
        conveyor:update(workspace:GetServerTimeNow()+(server:GetAttribute('ClockOffset') or 0))
        local workMs=(os.clock()-workStarted)*1000
        local sample=sampling
        if not sample then return end
        local phase=server:GetAttribute('Status')
        if server:GetAttribute('Epoch')~=sample.epoch or server:GetAttribute('Churn')~=sample.churn
            or server:GetAttribute('SnapshotsEnabled')~=sample.snapshotsEnabled
            or (phase~='Ready' and phase~='Churning') then
            sampling=nil;status:SetAttribute('SampleStatus','Cancelled: scenario changed');return
        end
        if not sample.started then sample.started=now;return end
        local ms=delta*1000
        sample.frames+=1;sample.totalMs+=ms;sample.maxMs=math.max(sample.maxMs,ms)
        sample.workMs+=workMs;sample.maxWorkMs=math.max(sample.maxWorkMs,workMs)
        local bin=math.clamp(math.ceil(ms*4),1,513);sample.histogram[bin]+=1
        if now-sample.started>=sample.seconds then
            sampling=nil
            finishSample(sample)
        end
    end))
    status:SetAttribute('Running',true)
    return {status='Running',camera=cameraMode}
end
function Controller.sample(options: any): any
    assert(conveyor,'Start the client harness first')
    assert(not sampling,'A sample is already running')
    local seconds=if type(options)=='number' then options else (options and options.seconds or 10)
    assert(type(seconds)=='number' and seconds>=10 and seconds<=600,'Sample duration must be 10..600 seconds')
    if type(options)=='table' and options.camera then Controller.camera(options.camera) else Controller.camera(cameraMode) end
    local phase=server:GetAttribute('Status')
    assert(phase=='Ready' or phase=='Churning','Wait for the server population to be Ready')
    lastSample=nil
    local before=inventory()
    sampling={seconds=seconds,histogram=table.create(513,0),frames=0,totalMs=0,maxMs=0,workMs=0,maxWorkMs=0,
        capacity=server:GetAttribute('CapacityPerFarm'),epoch=server:GetAttribute('Epoch'),churn=server:GetAttribute('Churn'),
        camera=cameraMode,before=before,memoryBefore=Stats:GetTotalMemoryUsageMb(),
        snapshotsEnabled=server:GetAttribute('SnapshotsEnabled'),
        snapshotsBefore=receivedSnapshots,entitiesBefore=receivedEntities}
    status:SetAttribute('SampleStatus','Sampling')
    return {status='Sampling',seconds=seconds,camera=cameraMode}
end
function Controller.counters(includeInventory: boolean?): any
    return {status=status:GetAttributes(),lastSample=lastSample,
        snapshotsReceived=receivedSnapshots,snapshotEntitiesReceived=receivedEntities,
        lastSnapshot=if latestSnapshot then {plotId=latestSnapshot.plotId,revision=latestSnapshot.revision,producers=#latestSnapshot.producers,minis=#latestSnapshot.tokens} else nil,
        inventory=if includeInventory then inventory() else nil}
end
function Controller.stop(): any
    for _,connection in connections do connection:Disconnect() end
    table.clear(connections)
    if conveyor then conveyor:destroy();conveyor=nil end
    sampling=nil;latestSnapshot=nil
    if cameraBackup and workspace.CurrentCamera==cameraBackup.camera then
        local camera=cameraBackup.camera
        camera.CameraType=cameraBackup.type;camera.CFrame=cameraBackup.frame;camera.Focus=cameraBackup.focus;camera.FieldOfView=cameraBackup.fov
        if cameraBackup.subject and cameraBackup.subject.Parent then camera.CameraSubject=cameraBackup.subject end
    end
    cameraBackup=nil
    status:SetAttribute('Running',false)
    if status:GetAttribute('SampleStatus')=='Sampling' then status:SetAttribute('SampleStatus','Cancelled: stopped') end
    return {status='Stopped'}
end
function Controller.destroy(): any
    Controller.stop()
    control.OnInvoke=nil;control:Destroy();status:Destroy()
    return {status='Destroyed'}
end
control.OnInvoke=function(action: string,value: any): any
    if action=='start' then return Controller.start(value)
    elseif action=='camera' then Controller.camera(value);return {camera=cameraMode}
    elseif action=='sample' then return Controller.sample(value)
    elseif action=='counters' then return Controller.counters(value)
    elseif action=='stop' then return Controller.stop()
    elseif action=='destroy' then return Controller.destroy() end
    error('Unknown client capacity action: '..tostring(action))
end
return Controller
