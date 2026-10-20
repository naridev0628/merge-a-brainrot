-- Studio-only disposable QA. Execute this on Server, then execute the matching
-- client fixture. No shipped Main scripts, normal farm sessions, or Config are
-- changed. The clone and isolated Core session expire after 120 seconds.
-- For the all-Crocodilo variant, replace only the following literal's value with
-- 'tier_06' in the executor source. Keep the committed default mixed.
local SPECIES_MODE='mixed'
assert(SPECIES_MODE=='mixed' or SPECIES_MODE=='tier_06','Species mode must be mixed or tier_06')
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsServer(),'Studio Server required')
local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local Server=game:GetService('ServerScriptService')
local Http=game:GetService('HttpService')
assert(not Replicated:FindFirstChild('CapacityHarness'),'Stop and remove the capacity harness first')
assert(not Replicated:FindFirstChild('TrayWalkFixture'),'A tray walk is already active')
assert(#Players:GetPlayers()==1,'Use a disposable single-player Play session')
local player=Players:GetPlayers()[1]
local Shared=Replicated.Shared
local Config=require(Shared.Config)
local Catalog=require(Shared.CreatureCatalog)
local Economy=require(Shared.Economy)
local Core=require(Server.Domain.FarmCore)
local World=require(Server.Services.WorldBuilder)
local generated=assert(workspace:FindFirstChild('MergeABrainrotGenerated'),'Normal world must be ready')
local source=assert(generated:FindFirstChild('Plot1'),'Plot1 geometry required')
local models=assert(Replicated:FindFirstChild('CharacterModels'),'Imported characters required')
for tier=1,6 do
    local template=models:FindFirstChild(string.format('tier_%02d_Mini',tier))
    assert(template and template:IsA('MeshPart') and template.MeshId~='','Import all six actual Mini meshes')
end
local config=table.clone(Config)
config.GroundCap=96;config.LuckyChance=0
assert(config.Slots==50 and config.GroundPerProducer==8)
local core=Core.new(config,Catalog,function() return 1 end)
local session=core:newSession(player.UserId,0,'tray-walk-'..Http:GenerateGUID(false))
local seeded=core:snapshot(session)
seeded.starterClaimed=true
for slot=1,50 do
    local species=if SPECIES_MODE=='mixed' then string.format('tier_%02d',(slot-1)%6+1) else SPECIES_MODE
    seeded.producers[slot]={id=core:id(session),speciesId=species,slot=slot,due=1}
    seeded.discoveries[species]=true
end
assert(core:commit(session,seeded))
core:step(session,1);core:step(session,2)
assert(#session.state.tokens==96)
local expected={}
local settled=core:snapshot(session)
local expectedQuantity=Economy.count(settled.tokens)
for _,token in settled.tokens do
    expected[token.speciesId]=(expected[token.speciesId] or 0)+(token.count or 1)
    token.spawnedAt=os.clock()-10;token.readyAt=os.clock()-6
end
for _,producer in settled.producers do producer.due=os.clock()+10000 end
assert(core:commit(session,settled))
if SPECIES_MODE=='tier_06' then
    assert(expected.tier_06==96*Catalog.tier_06.production and Catalog.tier_06.value==1,
        'Crocodilo variant requires 96 counted bundles at $1 per individual Mini')
end
local verifiedMeshIds={}
local function verifyMiniMeshes(tokens)
    local checked=0
    for _,token in session.state.tokens do
        local model=assert(tokens:FindFirstChild(token.id),'Missing rendered Mini')
        local mesh=model:FindFirstChild('Character')
        local template=models:FindFirstChild(token.speciesId..'_Mini')
        assert(mesh and mesh:IsA('MeshPart') and template and mesh.MeshId==template.MeshId,
            'Every rendered Mini must use its actual imported species MeshId')
        if SPECIES_MODE=='tier_06' then
            assert(token.speciesId=='tier_06' and mesh.MeshId==models.tier_06_Mini.MeshId,
                'All 96 Crocodilo variant models must use tier_06_Mini')
        end
        verifiedMeshIds[token.speciesId]=mesh.MeshId
        checked+=1
    end
    return checked
end

local fixture=source:Clone()
fixture.Name='TrayWalkPlot'
local status=Instance.new('Folder')
status.Name='TrayWalkFixture'
local remote=Instance.new('RemoteFunction')
remote.Name='Control';remote.Parent=status
local world=nil
local character,humanoid,root,original=nil,nil,nil,nil
local active=false
local destroyed=false
local deadline=os.clock()+120
local route={
    {name='left front',x=-15,z=config.TrayZ-11},
    {name='left perimeter',x=-15,z=config.TrayZ},
    {name='front center',x=0,z=config.TrayZ-11},
    {name='right perimeter',x=15,z=config.TrayZ},
    {name='tray center',x=0,z=config.TrayZ},
}
local visited,serial,total,partial,repacked=0,0,0,false,false
local initialMeshChecks=0
local samples,events={},{}
local lastPosition,lastSampleAt=nil,nil
local walked=0
local heldSince=nil
local function boundedPush(list,value,cap)
    table.insert(list,value)
    if #list>cap then table.remove(list,1) end
end
local function restore()
    if original and player.Character==character and character.Parent and root.Parent then
        humanoid:Move(Vector3.zero)
        character:PivotTo(original)
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end
end
local function cleanup()
    if destroyed then return end
    destroyed=true;active=false
    restore()
    fixture:Destroy()
    remote.OnServerInvoke=nil
    status:Destroy()
    world=nil;session=nil
end
local function fail(reason)
    if destroyed then return end
    active=false
    status:SetAttribute('Status','Failed')
    status:SetAttribute('Error',tostring(reason))
    restore()
    -- Give the waiting client time to read the failure and restore its controls.
    deadline=math.min(deadline,os.clock()+10)
end
local ok,err=xpcall(function()
    for _,name in {'Producers','Minis','StackRows'} do fixture[name]:ClearAllChildren() end
    local lucky=fixture:FindFirstChild('LuckyBlock')
    if lucky then lucky:Destroy() end
    for _,item in fixture:GetDescendants() do
        if item:IsA('SpawnLocation') or item:IsA('LuaSourceContainer') then item:Destroy() end
    end
    fixture:PivotTo(CFrame.new(0,2000,0))
    world={root=fixture,frame=fixture:GetPivot(),producers=fixture.Producers,tokens=fixture.Minis,
        rows=fixture.StackRows,badgePart=fixture.OwnerBadgeAnchor,ownerLabel=fixture.OwnerSign.Label.Text,pads={},
        saleLabel={},processorLabel={},processorRate={},
        upgradeLabel=fixture.UpgradePad.Label.Text,upgradePrice=fixture.UpgradePad.Label.Price}
    -- Render the real imported meshes and shelf geometry before publishing.
    World.render(world,session.state)
    assert(#world.tokens:GetChildren()==96)
    initialMeshChecks=verifyMiniMeshes(world.tokens)
    assert(initialMeshChecks==96)
    fixture.Parent=workspace
    status:SetAttribute('Status','Ready')
    status:SetAttribute('OwnerId',player.UserId)
    status:SetAttribute('Scenario',SPECIES_MODE)
    status:SetAttribute('Remaining',96);status:SetAttribute('Visited',0)
    status.Parent=Replicated
end,debug.traceback)
if not ok then cleanup();error(err) end

remote.OnServerInvoke=function(who,action)
    if who~=player or destroyed then return {error='Wrong fixture owner'} end
    if action=='Cancel' then task.defer(cleanup);return {cancelled=true} end
    if action=='Begin' then
        if status:GetAttribute('Status')~='Ready' then return {error='Already started'} end
        character=player.Character
        humanoid=character and character:FindFirstChildOfClass('Humanoid')
        root=character and character:FindFirstChild('HumanoidRootPart')
        if not humanoid or humanoid.Health<=0 or not root then return {error='Alive character required'} end
        original=character:GetPivot()
        local offset=humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0)
        local start=world.frame:PointToWorldSpace(Vector3.new(-15,0,config.TrayZ-18)*config.PlotScale)
        -- Exactly one staging move. Every subsequent pickup uses real walking.
        character:PivotTo(CFrame.new(start+Vector3.new(0,offset+.15,0)))
        root.AssemblyLinearVelocity=Vector3.zero
        active=true;status:SetAttribute('Status','Running')
        local points={}
        for _,node in route do
            table.insert(points,world.frame:PointToWorldSpace(Vector3.new(node.x,0,node.z)*config.PlotScale))
        end
        return {points=points,offset=offset}
    end
    if action=='Finish' then
        local result={scenario=SPECIES_MODE,initialMeshChecks=initialMeshChecks,verifiedMeshIds=verifiedMeshIds,
            remaining=#session.state.tokens,collected=total,bag=Economy.count(session.state.bag),
            visited=visited,walkedStuds=walked,partial=partial,repacked=repacked,expectedSpecies=expected,
            events=events,recentSamples=samples,cloneMiniModels=#world.tokens:GetChildren()}
        local checked,problem=pcall(function()
            assert(status:GetAttribute('Status')=='Running','Fixture did not remain running')
            assert(visited==#route and walked>=20,'Every actual walking waypoint must be visited')
            assert(total==expectedQuantity and result.bag==expectedQuantity and result.remaining==0 and result.cloneMiniModels==0,
                'All 96 real Mini bundles and their complete quantities must be collected')
            assert(partial and repacked,'A partial pickup must visibly repack surviving upper-layer Minis')
            if SPECIES_MODE=='mixed' then
                for tier=1,6 do assert((expected[string.format('tier_%02d',tier)] or 0)>0) end
            else assert(expected.tier_06==96*Catalog.tier_06.production) end
            local counts={}
            for _,good in session.state.bag do
                assert(good.baseCoinValue==Catalog[good.speciesId].value,'Collection changed cash value')
                counts[good.speciesId]=(counts[good.speciesId] or 0)+(good.count or 1)
            end
            for species,count in expected do assert(counts[species]==count,'Species count mismatch') end
            assert(core:validate(session.state,session.owner),'Final domain state invalid')
            -- Producers were frozen only for this isolated collection experiment.
            core:step(session,os.clock())
            assert(#session.state.tokens==0,'Unexpected refill during the frozen collection pass')
        end)
        result.pass=checked;result.error=if checked then nil else tostring(problem)
        active=false;status:SetAttribute('Status',if checked then 'Passed' else 'Failed')
        restore()
        task.delay(.5,cleanup)
        return result
    end
    return {error='Unknown fixture command'}
end

task.spawn(function()
    while not destroyed and os.clock()<deadline do
        task.wait(.1)
        if not active then continue end
        local sampled,sampleError=xpcall(function()
            assert(player.Parent==Players and player.Character==character and humanoid.Health>0 and root.Parent,
                'Character changed or died; aborting isolated fixture')
            local now=os.clock()
            local position=root.Position
            if lastPosition then
                local delta=position-lastPosition
                assert(delta.Magnitude<=math.max(7,(now-lastSampleAt)*24+2),'Unexpected teleport during walking')
                walked+=Vector2.new(delta.X,delta.Z).Magnitude
            end
            lastPosition=position;lastSampleAt=now
            local offset=humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0)
            local foot=position-Vector3.new(0,offset,0)
            local pos=world.frame:PointToObjectSpace(foot)/config.PlotScale
            local pickup=world.frame:PointToObjectSpace(position)/config.PlotScale
            assert(math.abs(pos.X)<55 and pos.Z>44 and pos.Z<96 and math.abs(pos.Y)<8,
                'Character left the cloned farm')
            local target=route[visited+1]
            if target and Vector2.new(pos.X-target.x,pos.Z-target.z).Magnitude*config.PlotScale<1
                and humanoid.FloorMaterial~=Enum.Material.Air then
                heldSince=heldSince or now
                if now-heldSince>=.2 then visited+=1;heldSince=nil;status:SetAttribute('Visited',visited) end
            else heldSince=nil end
            boundedPush(samples,{x=pos.X,y=pos.Y,z=pos.Z,remaining=#session.state.tokens,visited=visited},64)
            local old={}
            for _,token in session.state.tokens do old[token.id]=token.y end
            local before=#session.state.tokens
            local beforeQuantity=Economy.count(session.state.tokens)
            serial+=1
            local result=core:dispatch(session,'CollectNearby',{'tray-walk-'..serial},{
                now=now,alive=true,position={x=pos.X,y=pos.Y,z=pos.Z},
                pickupPosition={x=pickup.X,y=pickup.Y,z=pickup.Z},
            })
            if result.code=='OK' then
                local after=#session.state.tokens
                assert(result.count==beforeQuantity-Economy.count(session.state.tokens) and result.count>0 and before>after)
                total+=result.count
                partial=partial or after>0
                for _,token in session.state.tokens do
                    assert(token.y<=old[token.id],'Repack unexpectedly raised a survivor')
                    repacked=repacked or token.y<old[token.id]
                end
                assert(Economy.count(session.state.bag)+Economy.count(session.state.tokens)==expectedQuantity,'A pickup lost or duplicated Minis')
                boundedPush(events,{count=result.count,remaining=after,x=pos.X,z=pos.Z},96)
                World.render(world,session.state)
                assert(verifyMiniMeshes(world.tokens)==after,'Repacked survivors must retain their imported meshes')
                status:SetAttribute('Remaining',after)
            else assert(result.code=='NothingNearby','Unexpected pickup rejection: '..result.code) end
        end,debug.traceback)
        if not sampled then fail(sampleError) end
    end
    cleanup()
end)
return {status='Ready',scenario=SPECIES_MODE,initialMeshChecks=initialMeshChecks,verifiedMeshIds=verifiedMeshIds,
    instructions='Run studio-tray-walk.client.luau now in this disposable single-player Play session',timeoutSeconds=120}
