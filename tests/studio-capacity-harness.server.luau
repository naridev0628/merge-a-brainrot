--!strict
-- TEST ONLY. Install in a temporary Play session with both shipped Main scripts
-- disabled. Install tests/CapacityHarnessScenario.luau as a sibling ModuleScript.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsServer(),'Capacity harness is Studio server only')
local Storage=game:GetService('ServerStorage')
local Replicated=game:GetService('ReplicatedStorage')
local Server=game:GetService('ServerScriptService')
local Players=game:GetService('Players')
local Stats=game:GetService('Stats')
local main=Server:FindFirstChild('Main')
assert(not main or not main:IsA('Script') or main.Disabled,'Disable Main.server before starting the test Play session')
assert(not Replicated:FindFirstChild('FarmNetwork'),'Disable Main.server before starting the test Play session')
assert(not Storage:FindFirstChild('CapacityHarnessControl'),'A capacity harness is already installed')
assert(not workspace:FindFirstChild('MergeABrainrotGenerated'),'Use a fresh test session; never replace an unowned world')
local Shared=Replicated:WaitForChild('Shared')
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Core=require(Server.Domain.FarmCore)
local World=require(Server.Services.WorldBuilder)
local Scenario=require(Server:WaitForChild('CapacityHarnessScenario'))
local models=Replicated:WaitForChild('CharacterModels')
for tier=1,6 do for _,suffix in {'','_Mini'} do
    local model=models:FindFirstChild(string.format('tier_%02d',tier)..suffix)
    assert(model and model:IsA('MeshPart'),'Import all six production character and Mini meshes before profiling')
end end

local status=Instance.new('Folder');status.Name='CapacityHarness';status.Parent=Replicated
local snapshots=Instance.new('RemoteEvent');snapshots.Name='Snapshot';snapshots.Parent=status
local control=Instance.new('BindableFunction');control.Name='CapacityHarnessControl';control.Parent=Storage
local Controller={}
local hub: any=nil
local ownsWorld=false
local run: any=nil
local worker: thread?=nil
local heartbeat: RBXScriptConnection?=nil
local active=false
local destroyRequested=false
local requestedChurn=false
local epoch=0
local metrics: any={}
local workSamples: {number}=table.create(2400)
local heartbeatSamples: {number}=table.create(36000)
local workCursor,heartbeatCursor=0,0
local terrainBackup: TerrainRegion?=nil
local terrainCorner=Vector3int16.new(-126,-4,-126)
local savedLighting: {[string]: any}={}
local savedWater: {[string]: any}={}
local function setStatus(value: string)
    status:SetAttribute('Status',value)
    status:SetAttribute('Active',active)
end
setStatus('Idle')
status:SetAttribute('ClockOffset',0)
status:SetAttribute('SnapshotsEnabled',true)

local function saveEnvironment()
    if terrainBackup then return end
    -- Covers World.build's 1000x4x1000 water fill plus a one-voxel margin.
    terrainBackup=workspace.Terrain:CopyRegion(Region3int16.new(terrainCorner,Vector3int16.new(126,0,126)))
    for _,key in {'ClockTime','Brightness','Ambient'} do savedLighting[key]=(game:GetService('Lighting') :: any)[key] end
    for _,key in {'WaterColor','WaterTransparency','WaterReflectance','WaterWaveSize','WaterWaveSpeed'} do savedWater[key]=(workspace.Terrain :: any)[key] end
end
local function release()
    if heartbeat then heartbeat:Disconnect();heartbeat=nil end
    -- World.build yields while constructing; a failed build may not return hub.
    local root=if hub then hub.root else if ownsWorld then workspace:FindFirstChild('MergeABrainrotGenerated') else nil
    if root then root:Destroy() end
    hub=nil;ownsWorld=false
    if terrainBackup then
        workspace.Terrain:PasteRegion(terrainBackup,terrainCorner,true)
        terrainBackup:Destroy();terrainBackup=nil
    end
    for key,value in savedLighting do (game:GetService('Lighting') :: any)[key]=value end
    for key,value in savedWater do (workspace.Terrain :: any)[key]=value end
    run=nil
    control.OnInvoke=nil
    status:Destroy();control:Destroy()
end
local function distribution(values: {number}): any
    if #values==0 then return {samples=0} end
    local sorted=table.clone(values);table.sort(sorted)
    return {samples=#sorted,p50=sorted[math.ceil(#sorted*.50)],p95=sorted[math.ceil(#sorted*.95)],p99=sorted[math.ceil(#sorted*.99)],max=sorted[#sorted]}
end
local function population(): (number,number)
    local producers,minis=0,0
    if run then for _,session in run.sessions do producers+=#session.state.producers;minis+=#session.state.tokens end end
    return producers,minis
end
local function publish(now: number)
    local producers,minis=population()
    status:SetAttribute('ServerNow',now)
    status:SetAttribute('ProducerCount',producers);status:SetAttribute('MiniCount',minis)
    status:SetAttribute('Churn',run and run.churning or false)
    for key,value in metrics do if type(value)=='number' then status:SetAttribute(key,value) end end
end
local function sendSnapshots(changed: {number},now: number)
    if status:GetAttribute('SnapshotsEnabled')~=true then return end
    local players=Players:GetPlayers()
    table.sort(players,function(a,b) return a.UserId<b.UserId end)
    for index,player in players do
        local plotId=(index-1)%6+1
        if not table.find(changed,plotId) then continue end
        local session=run.sessions[plotId]
        local state=run.core:snapshot(session)
        state.serverNow=now;state.plotId=plotId;state.plotCFrame=hub.plots[plotId].frame
        state.sessionKey=session.key;state.status='Ready';state.harnessEpoch=epoch
        snapshots:FireClient(player,state)
        metrics.SnapshotsSent+=1
        metrics.SnapshotEntities+=#state.producers+#state.tokens
    end
end

function Controller.counters(includeInventory: boolean?): any
    local result=status:GetAttributes()
    result.workMs=distribution(workSamples);result.heartbeatMs=distribution(heartbeatSamples)
    result.serverMemoryMb=Stats:GetTotalMemoryUsageMb()
    if includeInventory and hub then
        local inventory={instances=0,parts=0,meshes=0,shelfParts=0}
        for _,item in hub.root:GetDescendants() do
            inventory.instances+=1
            if item:IsA('BasePart') then
                inventory.parts+=1
                if item:IsA('MeshPart') then inventory.meshes+=1 end
                if item:FindFirstAncestor('StackRows') then inventory.shelfParts+=1 end
            end
        end
        result.inventory=inventory
    end
    return result
end
function Controller.churn(enabled: boolean): any
    assert(type(enabled)=='boolean','churn expects a boolean')
    requestedChurn=enabled
    return {requested=enabled,status=status:GetAttribute('Status')}
end
function Controller.stop(): any
    active=false
    if worker then setStatus('Stopping') else setStatus('Stopped') end
    return {status=status:GetAttribute('Status')}
end
function Controller.destroy(): any
    destroyRequested=true
    Controller.stop()
    if not worker then release() end
    return {status='Destroy requested'}
end
function Controller.start(cap: number): any
    assert(not destroyRequested,'This harness has been destroyed')
    assert(cap==50 or cap==96,'Only the 50/50 and 50/96 comparison is supported')
    assert(not worker,'Stop the current trial and wait for Stopped before starting the next')
    epoch+=1;active=true;requestedChurn=false
    status:SetAttribute('Epoch',epoch);status:SetAttribute('CapacityPerFarm',cap);status:SetAttribute('Error',nil)
    setStatus('Building')
    worker=task.defer(function()
        local ok,err=xpcall(function()
            saveEnvironment()
            if not hub then
                assert(not ownsWorld,'The previous build failed; destroy this harness before retrying')
                assert(not workspace:FindFirstChild('MergeABrainrotGenerated'),'An unowned world appeared; stop the other world builder')
                ownsWorld=true
                hub=World.build()
                hub.root:SetAttribute('CapacityHarnessOwned',true)
            end
            if not active then return end
            for _,plot in hub.plots do World.clear(plot) end
            run=Scenario.new(Core,Config,Catalog,cap,workspace:GetServerTimeNow())
            setStatus('Populating')
            for id,plot in hub.plots do
                if not active then return end
                plot.ownerName.Text='Capacity farm '..id
                World.render(plot,run.sessions[id].state)
            end
            if not active then return end
            metrics={Ticks=0,Renders=0,CreatedMinis=0,RemovedMinis=0,SnapshotsSent=0,SnapshotEntities=0,LastWorkMs=0,MeanWorkMs=0,PeakWorkMs=0}
            table.clear(workSamples);table.clear(heartbeatSamples);workCursor=0;heartbeatCursor=0
            heartbeat=RunService.Heartbeat:Connect(function(delta)
                heartbeatCursor=heartbeatCursor%36000+1
                heartbeatSamples[heartbeatCursor]=delta*1000
            end)
            local started=os.clock()
            status:SetAttribute('ReadyAt',workspace:GetServerTimeNow())
            sendSnapshots({1,2,3,4,5,6},workspace:GetServerTimeNow())
            publish(workspace:GetServerTimeNow())
            setStatus('Ready')
            while active do
                task.wait(Config.Cadence)
                if not active then break end
                local workStarted=os.clock()
                local now=workspace:GetServerTimeNow()
                if requestedChurn~=run.churning then
                    Scenario.churn(run,requestedChurn,now)
                    setStatus(if requestedChurn then 'Churning' else 'Ready')
                end
                local delta=Scenario.step(run,now)
                for _,id in delta.changed do World.render(hub.plots[id],run.sessions[id].state);metrics.Renders+=1 end
                sendSnapshots(delta.changed,now)
                metrics.CreatedMinis+=delta.created;metrics.RemovedMinis+=delta.removed
                metrics.Ticks+=1
                local duration=(os.clock()-workStarted)*1000
                metrics.LastWorkMs=duration;metrics.PeakWorkMs=math.max(metrics.PeakWorkMs,duration)
                metrics.MeanWorkMs+=(duration-metrics.MeanWorkMs)/metrics.Ticks
                workCursor=workCursor%2400+1;workSamples[workCursor]=duration
                metrics.ElapsedSeconds=os.clock()-started
                publish(now)
            end
        end,debug.traceback)
        if heartbeat then heartbeat:Disconnect();heartbeat=nil end
        worker=nil;active=false
        if not ok then status:SetAttribute('Error',tostring(err));setStatus('Failed') else setStatus('Stopped') end
        if destroyRequested then release() end
    end)
    return {status='Building',capacityPerFarm=cap,epoch=epoch}
end
control.OnInvoke=function(action: string,value: any): any
    if action=='start' then return Controller.start(value)
    elseif action=='churn' then return Controller.churn(value)
    elseif action=='stop' then return Controller.stop()
    elseif action=='counters' then return Controller.counters(value)
    elseif action=='snapshots' then assert(type(value)=='boolean');status:SetAttribute('SnapshotsEnabled',value);return value
    elseif action=='destroy' then return Controller.destroy() end
    error('Unknown capacity action: '..tostring(action))
end
return Controller
