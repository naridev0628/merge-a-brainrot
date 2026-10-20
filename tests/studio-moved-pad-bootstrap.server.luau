-- Disposable single-player Studio Play only. Before Play, disable server Main
-- and StarterPlayerScripts.Main. This fixture enables server Main; the matching
-- client fixture starts its untouched client Main after FarmNetwork is ready.
-- In Play, install this exact source as an enabled disposable Script beneath
-- ServerScriptService; do not execute its body directly through execute_luau.
-- The executor's require context did not share Core.newSession with normal Main
-- in native QA. An actual runtime Script shares Main's module context.
-- Then run studio-moved-pad-flow.client.luau on Client and poll both results.
-- Do not restart an already timed-out client Main; use fresh Play instead.
-- No shipped source or Config is changed. Stop Play, remove any retained fixture
-- Script, and re-enable both Main scripts in Edit after inspection.
-- Synthetic setup: 10,000 coin units and an unheld tier-2 Lucky; all purchases
-- and pickup afterward must come from the shipped client walking the real avatar.
-- Results remain in ReplicatedStorage.MovedPadFixture. End Play after inspection;
-- the seeded normal session is deliberately disposable, not restored progression.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsServer(),'Studio Server required')
local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local Server=game:GetService('ServerScriptService')
local Http=game:GetService('HttpService')
local main=assert(Server:FindFirstChild('Main'),'Server Main missing')
assert(main:IsA('Script') and main.Disabled,'Start fresh Play with server Main Disabled')
assert(#Players:GetPlayers()==1,'Use a disposable single-player Play session')
assert(not Replicated:FindFirstChild('FarmNetwork') and not workspace:FindFirstChild('MergeABrainrotGenerated'),
    'Main must never have started in this Play session')
for _,name in {'MovedPadFixture','CapacityHarness','TrayWalkFixture'} do
    assert(not Replicated:FindFirstChild(name),'Remove previous fixture: '..name)
end
local player=Players:GetPlayers()[1]
local Core=require(Server.Domain.FarmCore)
local Config=require(Replicated.Shared.Config)
local Map=require(Replicated.Shared.MapSpec)
assert(Config.BuyZ==67.5 and Config.MergeZ==52,'Use the reviewed buy row and moved Merge geometry')
local status=Instance.new('Folder')
status.Name='MovedPadFixture'
status:SetAttribute('OwnerId',player.UserId)
status:SetAttribute('Status','WaitingForSession')
status:SetAttribute('SyntheticCoinUnits',10000)
status:SetAttribute('LuckyId','moved-pad-'..Http:GenerateGUID(false))
status:SetAttribute('WrapperRestored',false)
status:SetAttribute('BuyZ',Config.BuyZ)
status:SetAttribute('MergeZ',Config.MergeZ)
local result=Instance.new('StringValue');result.Name='ServerResult';result.Value='running';result.Parent=status
local control=Instance.new('RemoteEvent');control.Name='Control';control.Parent=status
status.Parent=Replicated
local originalNewSession=Core.newSession
local wrapper,session,instance,hookTimer,lifetimeTimer
local connections={}
local requests={}
local finished=false
local function restore()
    if Core.newSession==wrapper then Core.newSession=originalNewSession end
    status:SetAttribute('WrapperRestored',Core.newSession==originalNewSession)
end
local function finish(ok,reason)
    if finished then return end
    finished=true
    restore()
    for _,connection in connections do connection:Disconnect() end
    table.clear(connections)
    if hookTimer then task.cancel(hookTimer);hookTimer=nil end
    if lifetimeTimer then task.cancel(lifetimeTimer);lifetimeTimer=nil end
    status:SetAttribute('Active',false)
    status:SetAttribute('FixtureConnections',0)
    status:SetAttribute('Status',if ok then 'PASS' else 'FAIL')
    local state=session and session.state
    result.Value=Http:JSONEncode({
        pass=ok,error=reason,scope='Synthetic funds/Lucky only; normal Main commands and real Humanoid afterward.',
        ownerId=player.UserId,wrapperRestored=Core.newSession==originalNewSession,requests=requests,
        producers=state and #state.producers,purchased=state and state.purchased,coinUnits=state and state.coinUnits,
        luckyHeld=state and state.lucky and state.lucky.held or false,
        cleanup='Fixture observers and bootstrap removed. End disposable Play to discard synthetic progress.',
    })
end
wrapper=function(self,owner,now,key)
    if owner~=player.UserId then return originalNewSession(self,owner,now,key) end
    -- Restore before any seed work, including errors; no later session is altered.
    restore()
    if hookTimer then task.cancel(hookTimer);hookTimer=nil end
    local ok,value=xpcall(function()
        local created=originalNewSession(self,owner,now,key)
        local state=self:snapshot(created)
        assert(not state.starterClaimed and #state.producers==0 and not state.lucky,'Expected a fresh session')
        state.coinUnits=10000
        state.lucky={id=status:GetAttribute('LuckyId'),baseTier=2,held=false}
        assert(self:commit(created,state),'Synthetic setup failed Core validation')
        session=created;instance=self
        local plot=assert(workspace.MergeABrainrotGenerated:FindFirstChild('Plot1'))
        local frame=plot:GetPivot()
        local command=Replicated.FarmNetwork.Command
        table.insert(connections,command.OnServerEvent:Connect(function(who,action,args)
            if finished or who~=player or action=='State' or action=='CollectNearby' then return end
            if #requests>=64 then finish(false,'Unexpected command flood');return end
            local character=player.Character
            local humanoid=character and character:FindFirstChildOfClass('Humanoid')
            local root=character and character:FindFirstChild('HumanoidRootPart')
            local position
            if humanoid and root then
                local offset=humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0)
                position=frame:PointToObjectSpace(root.Position-Vector3.new(0,offset,0))/Map.PlotScale
            end
            table.insert(requests,{
                action=tostring(action),id=type(args)=='table' and args[1] or nil,
                quantity=type(args)=='table' and args[2] or nil,at=os.clock(),
                foot=position and {x=position.X,y=position.Y,z=position.Z},
                luckyDistance=position and (position-Vector3.new(Config.LuckyX,1.6,Config.LuckyZ)).Magnitude*Map.PlotScale,
            })
        end))
        status:SetAttribute('SessionKey',created.key)
        status:SetAttribute('Status','Seeded')
        status:SetAttribute('Active',true)
        return created
    end,debug.traceback)
    if not ok then finish(false,tostring(value));error(value) end
    return value
end
table.insert(connections,control.OnServerEvent:Connect(function(who,action)
    if who~=player or finished then return end
    if action=='Cancel' then finish(false,'Client cancelled; inspect MovedPadFlowResult');return end
    if action~='Complete' then return end
    local ok,err=xpcall(function()
        assert(session and instance and Core.newSession==originalNewSession,'Bootstrap still active or not seeded')
        local state=session.state
        assert(instance:validate(state,player.UserId),'Final normal session is invalid')
        assert(#state.producers==46 and state.purchased==46 and state.starterClaimed,'Expected starter + three Buy5 + three Buy10')
        assert(state.coinUnits==5120,'Expected 20 starter units + 4860 batch units, with free Lucky pickup')
        assert(state.lucky and state.lucky.id==status:GetAttribute('LuckyId') and state.lucky.held,'Expected the same held Lucky')
        assert(not state.autoCollect and not state.autoSell and state.processorLevel==0 and state.rebirths==0,
            'The purchase/Lucky walking route must not change unrelated progression')
        local counts={['1']=0,['5']=0,['10']=0}
        local seen,pickups={},0
        for _,request in requests do
            assert(request.action~='AutoMerge' and request.action~='Merge',
                'Walking fixture crossed Merge instead of following its safe route')
            local cached=session.cache[request.id]
            if cached and cached.result.code=='OK' and not seen[request.id] then
                seen[request.id]=true
                if request.action=='Buy' then
                    assert(counts[request.quantity]~=nil,'Unexpected purchase quantity')
                    counts[request.quantity]+=1
                elseif request.action=='PickupLucky' then
                    pickups+=1
                    assert(request.luckyDistance and request.luckyDistance<=6.05,'Server pickup foot was outside six world studs')
                else error('Unexpected successful gameplay command: '..request.action) end
            end
        end
        assert(counts['1']==1 and counts['5']==3 and counts['10']==3 and pickups==1,'Missing or duplicated normal commands')
    end,debug.traceback)
    finish(ok,if ok then nil else tostring(err))
end))
table.insert(connections,Players.PlayerRemoving:Connect(function(who)
    if who==player then finish(false,'Fixture owner left') end
end))
table.insert(connections,status.Destroying:Connect(function() finish(false,'Fixture removed') end))
hookTimer=task.delay(60,function()
    hookTimer=nil;finish(false,'Main did not create the target session within 60 seconds')
end)
lifetimeTimer=task.delay(180,function()
    lifetimeTimer=nil;finish(false,'Client flow did not complete within 180 seconds')
end)
Core.newSession=wrapper
main.Disabled=false
return {status='Starting',ownerId=player.UserId,result='ReplicatedStorage.MovedPadFixture.ServerResult',
    next='Run studio-moved-pad-flow.client.luau; poll its StringValue. End Play after inspection.'}
