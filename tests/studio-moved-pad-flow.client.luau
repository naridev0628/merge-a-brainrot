-- Run after studio-moved-pad-bootstrap.server.luau in its fresh disposable Play.
-- Prefer both Main scripts Disabled before Play. This starts client Main once
-- after the server is ready; it never restarts an already-running LocalScript.
-- Returns immediately; poll PlayerGui.MovedPadFlowResult.Value / Status.
-- Only State is sent by this driver on FarmNetwork. Shipped Main performs every
-- Buy/PickupLucky. Fixture Control only closes the server's read-only observer.
-- This accepts moved geometry/normal input timing, not economy balance, natural
-- Lucky probability, paid-pass ownership, multiplayer, or device performance.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsClient(),'Studio Client required')
local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local player=Players.LocalPlayer
local gui=player:WaitForChild('PlayerGui')
assert(not gui:FindFirstChild('MovedPadFlowResult'),'Remove the previous client result before rerunning')
local output=Instance.new('StringValue')
output.Name='MovedPadFlowResult';output.Value='running';output:SetAttribute('Status','Running');output.Parent=gui
task.spawn(function()
    local connections={}
    local controls,character,humanoid,root,original,speed,autoRotate,enabled,fixture,control
    local state,phase,activeCycle=nil,'startup',nil
    local report={scope='Synthetic funds/Lucky; shipped Main purchases/pickup, one staging move then actual walking.',
        responses={},cycles={},waypoints={},walkedWorldStuds=0}
    local receivedAt=0
    local deadline=os.clock()+130
    local config,plot,offset
    local function foot()
        return root.Position-Vector3.new(0,offset,0)
    end
    local function logicalFoot()
        return state.plotCFrame:PointToObjectSpace(foot())/config.PlotScale
    end
    local function sampleEntry()
        if not activeCycle or activeCycle.enteredAt then return end
        local base=plot['Buy'..activeCycle.quantity..'Base']
        local p=base.CFrame:PointToObjectSpace(foot())
        if math.abs(p.X)<=base.Size.X/2 and math.abs(p.Z)<=base.Size.Z/2 then
            activeCycle.enteredAt=os.clock()
        end
    end
    local function waitUntil(predicate,seconds,message)
        local stop=math.min(deadline,os.clock()+seconds)
        repeat
            if predicate() then return end
            assert(os.clock()<deadline,'Overall fixture deadline exceeded during '..phase)
            if character then assert(character==player.Character and humanoid.Health>0,'Character changed or died during '..phase) end
            if fixture then assert(fixture.Parent and fixture:GetAttribute('Status')~='FAIL',
                'Server fixture failed: '..tostring(fixture.ServerResult.Value)) end
            task.wait(.03)
        until os.clock()>=stop
        error(message..' during '..phase)
    end
    local function setPhase(value)
        phase=value;output:SetAttribute('Phase',value)
    end
    local function walk(x,z)
        local target=state.plotCFrame:PointToWorldSpace(Vector3.new(x,0,z)*config.PlotScale)
        humanoid:MoveTo(target)
        waitUntil(function()
            local p=foot()
            return Vector2.new(p.X-target.X,p.Z-target.Z).Magnitude<1
                and humanoid.FloorMaterial~=Enum.Material.Air
        end,10,'Could not reach '..x..','..z)
        humanoid:Move(Vector3.zero)
        local p=logicalFoot()
        table.insert(report.waypoints,{phase=phase,targetX=x,targetZ=z,x=p.X,y=p.Y,z=p.Z,at=os.clock()})
    end
    local ok,err=xpcall(function()
        fixture=assert(Replicated:WaitForChild('MovedPadFixture',10),'Run server bootstrap first')
        control=assert(fixture:WaitForChild('Control',5),'Fixture control missing')
        waitUntil(function() return fixture:GetAttribute('Status')=='Seeded' end,60,'Bootstrap not ready')
        assert(fixture:GetAttribute('OwnerId')==player.UserId and fixture:GetAttribute('WrapperRestored'),
            'Fixture metadata does not belong to this player or bootstrap was not restored')
        local net=assert(Replicated:WaitForChild('FarmNetwork',5))
        local clientMain=assert(player.PlayerScripts:FindFirstChild('Main'),'Client Main missing')
        assert(clientMain:IsA('LocalScript'),'Expected the shipped client Main')
        if clientMain.Disabled then
            assert(not gui:FindFirstChild('BrainrotHUD'),'Do not restart a previously-run client Main')
            clientMain.Disabled=false
            report.startedClientMain=true
        end
        waitUntil(function() return gui:FindFirstChild('BrainrotHUD')~=nil end,10,'Client Main did not create its HUD')
        config=require(Replicated.Shared.Config)
        assert(config.BuyPads['5']==22 and config.BuyPads['10']==-22 and config.AutoCollectZ==52 and config.LuckyZ==65,
            'Use the accepted wider-tray sources')
        assert(math.abs(config.LuckyPickupRadius*config.PlotScale-6)<1e-6)
        table.insert(connections,net.StateSnapshot.OnClientEvent:Connect(function(value)
            if value.status=='Ready' then state=value;receivedAt=os.clock() end
        end))
        table.insert(connections,net.CommandResult.OnClientEvent:Connect(function(value)
            if value.action=='CollectNearby' then return end
            if root and activeCycle then sampleEntry() end
            local now=os.clock()
            local entry={phase=phase,action=value.action,code=value.code,count=value.count,
                requestId=value.requestId,replayed=value.replayed==true,at=now}
            if #report.responses<64 then table.insert(report.responses,entry) end
            if activeCycle and value.action=='Buy' then
                if value.code=='TooFar' then activeCycle.tooFar+=1 end
                if value.code=='OK' and not value.replayed then
                    table.insert(activeCycle.successes,entry)
                end
            end
            if value.action=='PickupLucky' and value.code=='OK' and root then
                local p=logicalFoot()
                report.luckyResponse={at=now,foot={x=p.X,y=p.Y,z=p.Z},
                    distance=(p-Vector3.new(config.LuckyX,1.6,config.LuckyZ)).Magnitude*config.PlotScale}
            end
        end))
        net.Command:FireServer('State',{})
        waitUntil(function() return state~=nil end,5,'No normal snapshot; restart client Main if its network wait expired')
        assert(state.sessionKey==fixture:GetAttribute('SessionKey') and state.coinUnits==10000
            and not state.starterClaimed and #state.producers==0 and not state.autoCollect and not state.autoSell,
            'Use the untouched synthetic bootstrap session')
        assert(state.lucky and state.lucky.id==fixture:GetAttribute('LuckyId') and not state.lucky.held)
        waitUntil(function()
            local current=player.Character
            local alive=current and current:FindFirstChildOfClass('Humanoid')
            return alive and alive.Health>0 and current:FindFirstChild('HumanoidRootPart')
        end,10,'A live character did not spawn')
        character=assert(player.Character);humanoid=assert(character:FindFirstChildOfClass('Humanoid'))
        root=assert(character:FindFirstChild('HumanoidRootPart'))
        controls=require(player.PlayerScripts.PlayerModule):GetControls()
        original=character:GetPivot();speed=humanoid.WalkSpeed;autoRotate=humanoid.AutoRotate;enabled=controls.controlsEnabled
        offset=humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0)
        plot=assert(workspace.MergeABrainrotGenerated:FindFirstChild('Plot'..state.plotId))
        controls:Disable();humanoid.WalkSpeed=16;humanoid.AutoRotate=true
        -- Allow shipped moveHome to finish before the sole staging teleport.
        task.wait(.5)
        character:PivotTo(state.plotCFrame*CFrame.new(Vector3.new(44,0,48)*config.PlotScale+Vector3.new(0,offset+.2,0)))
        root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        task.wait(.3)
        local lastPosition,lastAt=root.Position,os.clock()
        table.insert(connections,RunService.Heartbeat:Connect(function()
            if character~=player.Character or not root.Parent then return end
            sampleEntry()
            local p,now=root.Position,os.clock()
            local delta=p-lastPosition
            if delta.Magnitude>math.max(5,(now-lastAt)*28+2) then report.unexpectedTeleport=true end
            report.walkedWorldStuds+=Vector2.new(delta.X,delta.Z).Magnitude
            lastPosition=p;lastAt=now
        end))
        setPhase('starter')
        walk(44,56)
        waitUntil(function() return #state.producers==1 end,2,'Starter walk-up failed')
        walk(44,48)
        local function buyCycle(quantity)
            local x=config.BuyPads[quantity]
            setPhase('buy-'..quantity..'-approach')
            walk(x,48)
            local before=#state.producers
            local cycle={quantity=quantity,successes={},tooFar=0}
            table.insert(report.cycles,cycle);activeCycle=cycle
            setPhase('buy-'..quantity..'-hold')
            walk(x,56)
            waitUntil(function() return #cycle.successes>=3 end,6,'Expected entry and two standing purchases')
            -- Leave before the fourth .5-second repeat; the pad front is only
            -- 2.51 world studs from its center, traversed at normal WalkSpeed.
            walk(x,48);activeCycle=nil
            waitUntil(function() return #state.producers==before+3*tonumber(quantity) end,2,'Wrong batch count')
            assert(#cycle.successes==3,'Unexpected extra standing purchase')
            assert(cycle.enteredAt,'Never entered the rendered pad base')
            local first,second,third=cycle.successes[1],cycle.successes[2],cycle.successes[3]
            for _,response in cycle.successes do assert(response.count==tonumber(quantity),'Wrong pad quantity') end
            cycle.entryLatency=first.at-cycle.enteredAt
            cycle.firstRepeatAfterEntry=second.at-cycle.enteredAt
            cycle.repeatInterval=third.at-second.at
            -- Broad scheduling tolerance; still rejects delayed first-entry,
            -- old .1s spam, missing two-second hold and three-second pending retry.
            assert(cycle.entryLatency>=-.1 and cycle.entryLatency<1,'Entry was not immediate: '..cycle.entryLatency)
            assert(cycle.firstRepeatAfterEntry>=1.75 and cycle.firstRepeatAfterEntry<3.25,
                'First repeat did not honor the two-second hold: '..cycle.firstRepeatAfterEntry)
            assert(cycle.repeatInterval>=.35 and cycle.repeatInterval<1.25,
                'Standing repeat did not follow the half-second cadence: '..cycle.repeatInterval)
        end
        buyCycle('5')
        walk(0,48)
        buyCycle('10')
        walk(0,48)
        assert(#state.producers==46 and state.coinUnits==5120,'Unexpected completed purchase accounting')
        setPhase('auto-collect-walkup')
        walk(0,52)
        local hud=assert(gui:FindFirstChild('BrainrotHUD'))
        local action=hud.SafeArea.PadAction
        waitUntil(function()
            return action.Visible and action.Summary.Text=='Auto Collect + Deposit' and action.Act.Text=='Coming soon'
        end,2,'Moved Auto Collect context did not appear')
        assert(action.Act.Active and not state.autoCollect and not state.autoSell,'Offer granted automation or became inactive')
        report.autoCollect={summary=action.Summary.Text,button=action.Act.Text,x=logicalFoot().X,z=logicalFoot().Z}
        setPhase('lucky-outside')
        walk(0,55);task.wait(.25)
        local outside=logicalFoot()
        report.luckyOutside=(outside-Vector3.new(config.LuckyX,1.6,config.LuckyZ)).Magnitude*config.PlotScale
        assert(report.luckyOutside>6 and state.lucky and not state.lucky.held,'Lucky picked up outside six world studs')
        local coins=state.coinUnits
        setPhase('lucky-inside')
        -- MoveTo can stop nearly one world stud short. At goal Z57.5 even
        -- that early arrival is inside six studs; the goal stays ahead of
        -- the collidable rim at Z58.65 and requires neither jumping nor climbing.
        walk(0,57.5)
        waitUntil(function() return state.lucky and state.lucky.held and report.luckyResponse~=nil end,3,'Lucky walk-up pickup failed')
        local inside=logicalFoot()
        report.luckyInside=(inside-Vector3.new(config.LuckyX,1.6,config.LuckyZ)).Magnitude*config.PlotScale
        assert(report.luckyInside<=6 and report.luckyResponse.distance<=6.05,'Lucky response outside expected radius')
        assert(state.lucky.id==fixture:GetAttribute('LuckyId') and state.coinUnits==coins,'Pickup charged coins or changed the Lucky')
        waitUntil(function()
            local held=character:FindFirstChild('HeldLuckyBlock')
            return held and held:GetAttribute('LuckyId')==state.lucky.id
        end,3,'Held block did not replicate')
        local overlay=hud.SafeArea.PanelOverlay
        assert(overlay.Visible and not overlay.Active and overlay.BackgroundTransparency==1,'Lucky card became modal')
        setPhase('held-lucky-walk')
        walk(0,52)
        assert(state.lucky and state.lucky.held and overlay.Visible,'Walking closed or dropped the held Lucky')
        assert(not report.unexpectedTeleport and report.walkedWorldStuds>50,'Route must be real walking after the initial stage')
        report.producers=#state.producers;report.coinUnits=state.coinUnits;report.snapshotAge=os.clock()-receivedAt
        control:FireServer('Complete')
        waitUntil(function() return fixture:GetAttribute('Status')=='PASS' end,5,'Server acceptance failed')
        report.server=Http:JSONDecode(fixture.ServerResult.Value)
    end,debug.traceback)
    -- Stop observing before restoration; that final pivot is cleanup, not walking.
    for _,connection in connections do connection:Disconnect() end
    if not ok and control and control.Parent then control:FireServer('Cancel') end
    if humanoid and humanoid.Parent then
        humanoid:Move(Vector3.zero)
        if speed then humanoid.WalkSpeed=speed;humanoid.AutoRotate=autoRotate end
    end
    if controls and enabled~=false then controls:Enable() end
    if original and character==player.Character and character.Parent then
        character:PivotTo(original);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
    end
    report.pass=ok;report.error=if ok then nil else tostring(err);report.cleanup=true
    output.Value=Http:JSONEncode(report)
    output:SetAttribute('Phase',phase);output:SetAttribute('Status',if ok then 'PASS' else 'FAIL')
    print('[MovedPadFlow]',output.Value)
end)
return {status='Running',result='Players.LocalPlayer.PlayerGui.MovedPadFlowResult'}
