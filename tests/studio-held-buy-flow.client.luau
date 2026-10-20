-- Run Client after the matching bootstrap Script reports Seeded in fresh Play.
-- This driver sends only State and fixture completion. Untouched client Main
-- performs all Buy1 commands. One staging pivot, then MoveTo and continuous hold.
-- Poll PlayerGui.HeldBuyFlowResult. End Play after inspecting both JSON results.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsClient(),'Studio Client required')
local Replicated=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local player=game:GetService('Players').LocalPlayer
local gui=player:WaitForChild('PlayerGui')
assert(not gui:FindFirstChild('HeldBuyFlowResult'),'Remove previous result')
local output=Instance.new('StringValue');output.Name='HeldBuyFlowResult';output.Value='running'
output:SetAttribute('Status','Running');output.Parent=gui
task.spawn(function()
    local connections={}
    local fixture,control,state,character,humanoid,root,controls,original,speed,autoRotate,enabled,base,offset,hud
    local enteredAt,entryDeadline,lastPosition
    local plotScale=1
    local report={responses={},timings={},motionSamples={},leftPad=false,unexpectedTeleport=false,walkedWorldStuds=0}
    local lastMotionSample=-math.huge
    local successes={}
    local deadline=os.clock()+60
    local function waitFor(predicate,seconds,message)
        local stop=math.min(deadline,entryDeadline or math.huge,os.clock()+seconds)
        repeat
            if predicate() then return end
            assert(not fixture or fixture:GetAttribute('Status')~='FAIL','Server failed: '..tostring(fixture.ServerResult.Value))
            assert(not character or (player.Character==character and humanoid.Health>0),'Character changed or died')
            task.wait(.02)
        until os.clock()>=stop
        error(message)
    end
    local function sample()
        local foot=root.Position-Vector3.new(0,offset,0)
        local p=base.CFrame:PointToObjectSpace(foot)
        local inside=math.abs(p.X)<=base.Size.X/2 and math.abs(p.Z)<=base.Size.Z/2
        local now=os.clock()
        if now-lastMotionSample>=.05 and (not enteredAt or now-enteredAt<1.2) then
            lastMotionSample=now
            local position=state.plotCFrame:PointToObjectSpace(foot)/plotScale
            local velocity=state.plotCFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)/plotScale
            if #report.motionSamples>=40 then table.remove(report.motionSamples,1) end
            table.insert(report.motionSamples,{at=now,inside=inside,
                foot={x=position.X,y=position.Y,z=position.Z},
                velocity={x=velocity.X,y=velocity.Y,z=velocity.Z},floorMaterial=humanoid.FloorMaterial.Name})
        end
        if inside and not enteredAt then
            enteredAt=os.clock();entryDeadline=enteredAt+8;report.enteredAt=enteredAt
        elseif enteredAt and not inside then report.leftPad=true end
        if lastPosition then
            local delta=root.Position-lastPosition
            if delta.Magnitude>3 then report.unexpectedTeleport=true end
            report.walkedWorldStuds+=Vector2.new(delta.X,delta.Z).Magnitude
        end
        lastPosition=root.Position
    end
    local ok,err=xpcall(function()
        fixture=assert(Replicated:WaitForChild('HeldBuyFixture',10),'Run server bootstrap first')
        control=assert(fixture:FindFirstChild('Control'))
        waitFor(function() return fixture:GetAttribute('Status')=='Seeded' end,30,'Server not seeded')
        assert(fixture:GetAttribute('OwnerId')==player.UserId and fixture:GetAttribute('WrapperRestored'))
        local net=assert(Replicated:FindFirstChild('FarmNetwork'))
        table.insert(connections,net.StateSnapshot.OnClientEvent:Connect(function(value)
            if value.status=='Ready' then state=value end
        end))
        table.insert(connections,net.CommandResult.OnClientEvent:Connect(function(value)
            if value.action~='Buy' then return end
            if root then sample() end
            local record={at=os.clock(),code=value.code,count=value.count,replayed=value.replayed==true,requestId=value.requestId}
            table.insert(report.responses,record)
            if value.code=='OK' and not value.replayed then table.insert(successes,record) end
            task.defer(function()
                if not hud then return end
                table.insert(report.timings,{code=value.code,key=hud:GetAttribute('LastPadKey'),
                    feedbackMs=hud:GetAttribute('LastPadFeedbackMs'),dispatchMs=hud:GetAttribute('LastPadDispatchMs'),
                    confirmationMs=hud:GetAttribute('LastPadServerConfirmationMs')})
            end)
        end))
        local main=assert(player.PlayerScripts:FindFirstChild('Main'))
        assert(main:IsA('LocalScript') and main.Disabled and not gui:FindFirstChild('BrainrotHUD'),
            'Use a fresh disabled client Main; do not restart it')
        main.Disabled=false
        net.Command:FireServer('State',{})
        waitFor(function() return state and gui:FindFirstChild('BrainrotHUD') end,10,'No snapshot/HUD')
        hud=gui.BrainrotHUD
        plotScale=require(Replicated.Shared.Config).PlotScale
        assert(state.sessionKey==fixture:GetAttribute('SessionKey') and #state.producers==0
            and state.coinUnits==fixture:GetAttribute('InitialCoinUnits'),'Seed changed before walking')
        waitFor(function()
            local c=player.Character
            return c and c:FindFirstChild('HumanoidRootPart') and c:FindFirstChildOfClass('Humanoid')
        end,10,'No character')
        character=player.Character;root=character.HumanoidRootPart;humanoid=character:FindFirstChildOfClass('Humanoid')
        controls=require(player.PlayerScripts.PlayerModule):GetControls()
        original=character:GetPivot();speed=humanoid.WalkSpeed;autoRotate=humanoid.AutoRotate;enabled=controls.controlsEnabled
        controls:Disable();humanoid.WalkSpeed=16;humanoid.AutoRotate=true
        offset=humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0)
        local plot=workspace.MergeABrainrotGenerated:FindFirstChild('Plot'..state.plotId)
        base=assert(plot:FindFirstChild('Buy1Base'))
        report.padBaseSize={x=base.Size.X,y=base.Size.Y,z=base.Size.Z}
        report.footOffset=offset;report.hipHeight=humanoid.HipHeight;report.rigType=humanoid.RigType.Name
        task.wait(.5) -- Allow the normal initial moveHome to complete.
        local stage=base.CFrame:PointToWorldSpace(Vector3.new(0,0,-base.Size.Z/2-3))
        character:PivotTo(CFrame.new(stage.X,state.plotCFrame.Position.Y+offset+.2,stage.Z))
        root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        task.wait(.25)
        assert(#successes==0,'Staging must stay outside the pad')
        table.insert(connections,RunService.RenderStepped:Connect(sample))
        humanoid:MoveTo(Vector3.new(base.Position.X,state.plotCFrame.Position.Y,base.Position.Z))
        waitFor(function()
            return enteredAt and Vector2.new(root.Position.X-base.Position.X,root.Position.Z-base.Position.Z).Magnitude<.9
        end,3,'Failed to walk onto Buy1')
        humanoid:Move(Vector3.zero)
        waitFor(function() return #successes>=3 and state.purchased==3 end,8,'Standing Buy1 failed to resume after server funds arrived')
        task.wait(.05)
        assert(os.clock()<=entryDeadline,'Exceeded eight seconds after entry')
        assert(#successes==3 and #state.producers==3 and state.coinUnits==0,'Wrong purchase accounting')
        assert(not report.leftPad and not report.unexpectedTeleport and report.walkedWorldStuds>2,
            'Must enter once, walk normally, then remain on the pad')
        for _,response in report.responses do assert(response.code=='OK' or response.code=='InsufficientFunds','Unexpected '..response.code) end
        report.entryLatency=successes[1].at-enteredAt
        report.resumedInterval=successes[3].at-successes[2].at
        assert(report.entryLatency>=-.1 and report.entryLatency<.35,'First purchase confirmation was delayed')
        assert(report.resumedInterval>=.35 and report.resumedInterval<1.25,'Resumed purchases must repeat every half second')
        assert(successes[2].at-successes[1].at>=1,'No observable waiting interval before resumption')
        assert(#report.timings>=3,'Missing local pad timing telemetry')
        for _,timing in report.timings do
            assert(type(timing.feedbackMs)=='number' and type(timing.dispatchMs)=='number'
                and type(timing.confirmationMs)=='number','Missing feedback/dispatch/confirmation timing')
            assert(timing.feedbackMs<10,'Local visual acknowledgement exceeded 10 ms')
        end
        report.completedAfterEntry=os.clock()-enteredAt
        control:FireServer('Complete')
        waitFor(function() return fixture:GetAttribute('Status')=='PASS' end,1,'Server did not accept held-buy run')
        report.server=Http:JSONDecode(fixture.ServerResult.Value)
    end,debug.traceback)
    for _,connection in connections do connection:Disconnect() end
    if not ok and control and control.Parent then control:FireServer('Cancel') end
    if humanoid and humanoid.Parent then humanoid:Move(Vector3.zero);humanoid.WalkSpeed=speed or 16;humanoid.AutoRotate=autoRotate~=false end
    if controls and enabled~=false then controls:Enable() end
    if original and character==player.Character and character.Parent then
        character:PivotTo(original);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
    end
    report.pass=ok;report.error=if ok then nil else tostring(err);report.cleanup=true
    output.Value=Http:JSONEncode(report);output:SetAttribute('Status',if ok then 'PASS' else 'FAIL')
    print('[HeldBuyFlow]',output.Value)
end)
return {status='Running',result='Players.LocalPlayer.PlayerGui.HeldBuyFlowResult'}
