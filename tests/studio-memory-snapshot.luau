--!strict
-- One-shot, read-only diagnostic for normal Play or the capacity harness,
-- executable on either Client or Server. No connections, retained Instances,
-- new Instances, garbage-collection forcing or production-source changes.
-- Compare matched population/camera phases after warm-up; one delta is not a
-- leak verdict. Take these outside frame-time sample windows because inventory
-- enumeration itself allocates temporary arrays and takes measurable time.
local started=os.clock()
local Stats=game:GetService('Stats')
local RunService=game:GetService('RunService')
local Collection=game:GetService('CollectionService')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
assert(RunService:IsStudio(),'Memory diagnostic is for Studio validation')
local errors: {[string]: string}={}
local function read(name: string,callback: () -> any): any
    local ok,value=pcall(callback)
    if ok then return value end
    errors[name]=tostring(value)
    return nil
end
-- Read heap/categories before building the temporary inventory tables below.
local memory: any={luaHeapKb=gcinfo()}
memory.trackingEnabled=read('trackingEnabled',function() return Stats.MemoryTrackingEnabled end)
memory.instanceCount=read('instanceCount',function() return Stats.InstanceCount end)
if memory.trackingEnabled==true then
    memory.totalMb=read('totalMb',function() return Stats:GetTotalMemoryUsageMb() end)
    memory.tagsMb={}
    for _,tag in Enum.DeveloperMemoryTag:GetEnumItems() do
        memory.tagsMb[tag.Name]=read(tag.Name,function() return Stats:GetMemoryUsageMbForTag(tag) end)
    end
end
local function countKeys(values: {[string]: boolean}): number
    local count=0
    for _ in values do count+=1 end
    return count
end
local meshIds: {[string]: boolean}={}
local textureIds: {[string]: boolean}={}
local function noteAssets(item: Instance)
    if item:IsA('MeshPart') then
        if item.MeshId~='' then meshIds[item.MeshId]=true end
        if item.TextureID~='' then textureIds[item.TextureID]=true end
    elseif item:IsA('SpecialMesh') then
        if item.MeshId~='' then meshIds[item.MeshId]=true end
        if item.TextureId~='' then textureIds[item.TextureId]=true end
    end
end
local inventory: any={worldDescendants=0,parts=0,meshParts=0,producerModels=0,miniModels=0,
    producerParts=0,miniParts=0,accentFolders=0,accentParts=0,plots={}}
local world=workspace:FindFirstChild('MergeABrainrotGenerated')
if world then
    for _,item in world:GetDescendants() do
        inventory.worldDescendants+=1
        if item:IsA('BasePart') then inventory.parts+=1 end
        if item:IsA('MeshPart') then inventory.meshParts+=1 end
        noteAssets(item)
    end
    for _,plot in world:GetChildren() do
        if plot:IsA('Model') and plot.Name:match('^Plot%d+$') then
            local counts={producers=0,minis=0,producerParts=0,miniParts=0}
            for _,entry in {{folder='Producers',models='producers',parts='producerParts'},
                {folder='Minis',models='minis',parts='miniParts'}} do
                local folder=plot:FindFirstChild(entry.folder)
                if folder then for _,model in folder:GetChildren() do
                    if model:IsA('Model') then
                        counts[entry.models]+=1
                        for _,item in model:GetDescendants() do
                            if item:IsA('BasePart') then counts[entry.parts]+=1 end
                        end
                    end
                end end
            end
            inventory.plots[plot.Name]=counts
            inventory.producerModels+=counts.producers;inventory.miniModels+=counts.minis
            inventory.producerParts+=counts.producerParts;inventory.miniParts+=counts.miniParts
        end
    end
end
for _,item in workspace:GetChildren() do
    if item.Name=='ProducerTierAccent' then
        inventory.accentFolders+=1
        for _,part in item:GetChildren() do if part:IsA('BasePart') then inventory.accentParts+=1 end end
    end
end
local tags: any={}
for _,name in {'ConveyorMini','BrainrotProducer'} do
    local counts={total=0,inGeneratedWorld=0,outsideWorkspace=0}
    for _,model in Collection:GetTagged(name) do
        counts.total+=1
        if world and model:IsDescendantOf(world) then counts.inGeneratedWorld+=1 end
        if not model:IsDescendantOf(workspace) then counts.outsideWorkspace+=1 end
    end
    tags[name]=counts
end
local assets: any={worldUniqueMeshes=countKeys(meshIds),worldUniqueTextures=countKeys(textureIds),templateMeshParts=0}
for _,name in {'CharacterModels','ExpansionModels','MapModels'} do
    local folder=ReplicatedStorage:FindFirstChild(name)
    if folder then for _,item in folder:GetDescendants() do
        if item:IsA('MeshPart') then assets.templateMeshParts+=1 end
        noteAssets(item)
    end end
end
assets.worldAndTemplateUniqueMeshes=countKeys(meshIds)
assets.worldAndTemplateUniqueTextures=countKeys(textureIds)
local harness=ReplicatedStorage:FindFirstChild('CapacityHarness')
local harnessState: any=nil
if harness then
    harnessState={status=harness:GetAttribute('Status'),epoch=harness:GetAttribute('Epoch'),
        capacityPerFarm=harness:GetAttribute('CapacityPerFarm'),churn=harness:GetAttribute('Churn'),
        snapshotsEnabled=harness:GetAttribute('SnapshotsEnabled')}
end
local camera: any=nil
if RunService:IsClient() and workspace.CurrentCamera then
    local position=workspace.CurrentCamera.CFrame.Position
    local localPlayer=Players.LocalPlayer
    local playerGui=localPlayer and localPlayer:FindFirstChildOfClass('PlayerGui')
    local status=playerGui and playerGui:FindFirstChild('CapacityHarnessClient')
    camera={position={position.X,position.Y,position.Z},mode=status and status:GetAttribute('Camera')}
end
return {
    context=if RunService:IsClient() then 'Client' else 'Server',sampledAt=os.clock(),
    memory=memory,inventory=inventory,tags=tags,assets=assets,harness=harnessState,camera=camera,errors=errors,
    elapsedMs=(os.clock()-started)*1000,
    note='No GC forced. Memory sampled before inventory. Tags/instances are snapshots, not retained Lua-reference inspection. Category values are not summed; they may overlap. Disabled tracking leaves category/total fields absent.',
}
