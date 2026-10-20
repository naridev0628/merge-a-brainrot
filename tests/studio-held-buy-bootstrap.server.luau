-- Disposable single-player Studio Play only. Disable both Main scripts before
-- fresh Play. Install this source as an actual Script in ServerScriptService;
-- executor require contexts do not share the normal Main module table.
-- Run studio-held-buy-flow.client.luau after Status=Seeded. Stop Play afterward
-- and re-enable Main in Edit. Only setup/credit is synthetic; purchases use Main.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsServer(),'Studio Server required')
local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local Server=game:GetService('ServerScriptService')
local Http=game:GetService('HttpService')
local main=assert(Server:FindFirstChild('Main'))
assert(main:IsA('Script') and main.Disabled,'Fresh Play must start with Main Disabled')
assert(#Players:GetPlayers()==1,'Disposable single-player Play required')
assert(not Replicated:FindFirstChild('FarmNetwork') and not workspace:FindFirstChild('MergeABrainrotGenerated'),
    'Main must never have started in this Play')
assert(not Replicated:FindFirstChild('HeldBuyFixture'),'Remove previous fixture')
local player=Players:GetPlayers()[1]
local Core=require(Server.Domain.FarmCore)
local Config=require(Replicated.Shared.Config)
local Economy=require(Replicated.Shared.Economy)
local PadGeometry=require(Replicated.Shared.PadGeometry)
local Map=require(Replicated.Shared.MapSpec)
local status=Instance.new('Folder');status.Name='HeldBuyFixture'
status:SetAttribute('OwnerId',player.UserId);status:SetAttribute('Status','WaitingForSession')
local result=Instance.new('StringValue');result.Name='ServerResult';result.Value='running';result.Parent=status
local control=Instance.new('RemoteEvent');control.Name='Control';control.Parent=status
status.Parent=Replicated
local original=Core.newSession
local wrapper,session,core,timer
local connections,requests={},{}
local finished=false
local firstAt,creditAt,creditedUnits
local function restore()
    if Core.newSession==wrapper then Core.newSession=original end
    status:SetAttribute('WrapperRestored',Core.newSession==original)
end
local function finish(ok,reason)
    if finished then return end
    finished=true;restore()
    for _,connection in connections do connection:Disconnect() end
    table.clear(connections)
    if timer then task.cancel(timer);timer=nil end
    status:SetAttribute('Active',false);status:SetAttribute('FixtureConnections',0)
    result.Value=Http:JSONEncode({pass=ok,error=reason,requests=requests,firstAt=firstAt,creditAt=creditAt,
        creditedUnits=creditedUnits,shortageSeconds=firstAt and creditAt and creditAt-firstAt,
        producers=session and #session.state.producers,purchased=session and session.state.purchased,
        coinUnits=session and session.state.coinUnits,wrapperRestored=Core.newSession==original,
        cleanup='Observers removed. End disposable Play to discard synthetic progression.'})
    status:SetAttribute('Status',if ok then 'PASS' else 'FAIL')
end
wrapper=function(self,owner,now,key)
    if owner~=player.UserId then return original(self,owner,now,key) end
    restore()
    local ok,value=xpcall(function()
        local created=original(self,owner,now,key)
        local state=self:snapshot(created)
        assert(not state.starterClaimed and #state.producers==0,'Fresh progression required')
        state.coinUnits=Economy.buyCost(0,1,1,Config.MergeCount)
        assert(self:commit(created,state),'Seed failed validation')
        session=created;core=self
        status:SetAttribute('InitialCoinUnits',state.coinUnits)
        status:SetAttribute('SessionKey',created.key)
        table.insert(connections,Replicated.FarmNetwork.Command.OnServerEvent:Connect(function(who,action,args)
            if finished or who~=player or action=='State' or action=='CollectNearby' then return end
            if #requests>=32 then finish(false,'Unexpected command flood');return end
            local id=type(args)=='table' and args[1]
            local quantity=type(args)=='table' and args[2]
            local request={action=tostring(action),id=id,quantity=quantity,at=os.clock()}
            local character=player.Character
            local humanoid=character and character:FindFirstChildOfClass('Humanoid')
            local root=character and character:FindFirstChild('HumanoidRootPart')
            local generated=workspace:FindFirstChild('MergeABrainrotGenerated')
            local plot=generated and generated:FindFirstChild('Plot1')
            if root and humanoid and plot then
                local frame=plot:GetPivot()
                local offset=humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0)
                local pos=frame:PointToObjectSpace(root.Position-Vector3.new(0,offset,0))/Map.PlotScale
                local vel=frame:VectorToObjectSpace(root.AssemblyLinearVelocity)/Map.PlotScale
                local position={x=pos.X,y=pos.Y,z=pos.Z}
                local velocity={x=vel.X,y=vel.Y,z=vel.Z}
                local reconciled=PadGeometry.entryPosition(Config,action,position,velocity,quantity)
                request.foot=position;request.velocity=velocity;request.reconciled=reconciled
                request.insideBefore=PadGeometry.contains(Config,action,position,quantity)
                request.insideAfter=PadGeometry.contains(Config,action,reconciled,quantity)
                request.floorMaterial=humanoid.FloorMaterial.Name
                request.hipHeight=humanoid.HipHeight;request.footOffset=offset
                request.rigType=humanoid.RigType.Name
            end
            local cached=type(id)=='string' and created.cache[id]
            request.code=cached and cached.result.code
            table.insert(requests,request)
        end))
        status:SetAttribute('Active',true);status:SetAttribute('Status','Seeded')
        return created
    end,debug.traceback)
    if not ok then finish(false,tostring(value));error(value) end
    return value
end
table.insert(connections,RunService.Heartbeat:Connect(function()
    if finished or not session or creditAt then return end
    local ok,err=xpcall(function()
        local state=session.state
        if not firstAt then
            if state.purchased==0 then return end
            assert(state.purchased==1 and #state.producers==1 and state.coinUnits==0,
                'Initial funds must allow exactly one Buy1')
            firstAt=os.clock();status:SetAttribute('FirstPurchaseAt',firstAt)
        end
        assert(state.purchased==1 and state.coinUnits==0,'Purchases advanced during the cash shortage')
        if os.clock()-firstAt<1.1 then return end
        local candidate=core:snapshot(session)
        creditedUnits=Economy.buyCost(candidate.purchased,2,1,Config.MergeCount)
        candidate.coinUnits+=creditedUnits
        assert(core:commit(session,candidate),'Server credit failed validation')
        creditAt=os.clock();status:SetAttribute('CreditAt',creditAt);status:SetAttribute('CreditedUnits',creditedUnits)
        -- Normal Main publishes this revision through its existing snapshot loop.
    end,debug.traceback)
    if not ok then finish(false,tostring(err)) end
end))
table.insert(connections,control.OnServerEvent:Connect(function(who,action)
    if who~=player or finished then return end
    if action=='Cancel' then finish(false,'Client failed; inspect HeldBuyFlowResult');return end
    if action~='Complete' then return end
    local ok,err=xpcall(function()
        assert(session and core and Core.newSession==original,'Bootstrap not restored')
        assert(firstAt and creditAt and creditAt-firstAt>=1,'No real cash shortage interval')
        local state=session.state
        assert(core:validate(state,player.UserId),'Invalid final state')
        assert(state.purchased==3 and #state.producers==3 and state.coinUnits==0 and state.starterClaimed,
            'Expected exactly three authoritative Buy1 purchases')
        local successes,seen=0,{}
        for _,request in requests do
            assert(request.action=='Buy' and request.quantity=='1','Unexpected gameplay action')
            local cached=session.cache[request.id]
            assert(cached and cached.result.code~='TooFar','Entry rejected or command did not dispatch')
            if cached.result.code=='OK' and not seen[request.id] then
                seen[request.id]=true;successes+=1
                assert(cached.result.count==1,'Wrong purchase size')
            else assert(cached.result.code=='InsufficientFunds','Unexpected rejection') end
        end
        assert(successes==3,'Missing or duplicated purchases')
    end,debug.traceback)
    finish(ok,if ok then nil else tostring(err))
end))
table.insert(connections,Players.PlayerRemoving:Connect(function(who) if who==player then finish(false,'Player left') end end))
table.insert(connections,status.Destroying:Connect(function() finish(false,'Fixture removed') end))
timer=task.delay(75,function() timer=nil;finish(false,'Fixture startup/flow timeout') end)
Core.newSession=wrapper
main.Disabled=false
return {status='Starting',result='ReplicatedStorage.HeldBuyFixture.ServerResult'}
