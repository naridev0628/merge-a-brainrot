-- Run after studio-tray-walk.server.luau in a fresh disposable normal Play.
-- The server stages once; this client walks a fixed tray route with the actual
-- Humanoid. No token positions or pickup coordinates are sent to the server.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsClient(),'Studio Client required')
local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local player=Players.LocalPlayer
-- Server execution returning does not mean its new instances or attributes
-- have arrived on this client. Bound each wait so a missing/stopped fixture
-- still fails without taking movement control or changing the character.
local status=assert(Replicated:WaitForChild('TrayWalkFixture',10),'Server fixture did not replicate within 10 seconds')
local remote=assert(status:WaitForChild('Control',10),'Fixture control did not replicate within 10 seconds')
assert(remote:IsA('RemoteFunction'),'Fixture control must be a RemoteFunction')
local metadataDeadline=os.clock()+5
repeat
    assert(status.Parent,'Server fixture stopped during replication')
    if status:GetAttribute('OwnerId')~=nil and status:GetAttribute('Status')~=nil then break end
    task.wait(.03)
until os.clock()>=metadataDeadline
assert(status:GetAttribute('OwnerId')==player.UserId,'Fixture owner metadata is missing or belongs to another player')
assert(status:GetAttribute('Status')=='Ready','Server fixture is not ready: '..tostring(status:GetAttribute('Status')))
local character=assert(player.Character)
local humanoid=assert(character:FindFirstChildOfClass('Humanoid'))
local root=assert(character:FindFirstChild('HumanoidRootPart'))
local controls=require(player.PlayerScripts.PlayerModule):GetControls()
local original=character:GetPivot()
local speed,autoRotate,enabled=humanoid.WalkSpeed,humanoid.AutoRotate,controls.controlsEnabled
local snapshot=nil
local net=Replicated:FindFirstChild('FarmNetwork')
assert(net,'Use a normal Play session after removing the capacity harness')
local connection=net.StateSnapshot.OnClientEvent:Connect(function(state) snapshot=state end)
local function waitUntil(predicate,seconds,message,details)
    local deadline=os.clock()+seconds
    repeat
        if predicate() then return end
        assert(character==player.Character and humanoid.Health>0,'Character changed or died')
        assert(status.Parent and status:GetAttribute('Status')~='Failed',
            tostring(status:GetAttribute('Error') or 'Server fixture stopped'))
        task.wait(.03)
    until os.clock()>deadline
    error(message..' at '..tostring(root.Position)..(if details then '; '..details() else ''))
end
local result=nil
local ok,err=xpcall(function()
    net.Command:FireServer('State',{})
    waitUntil(function() return snapshot~=nil end,5,'No normal session snapshot')
    assert(snapshot.status=='Ready' and not snapshot.starterClaimed and #snapshot.producers==0
        and #snapshot.tokens==0 and #snapshot.bag==0 and not snapshot.lucky
        and snapshot.obby and snapshot.obby.checkpoint==0 and snapshot.obby.bonusHundredths==0
        and snapshot.obby.cooldownRemaining==0,
        'Use a fresh disposable Play session; the fixture refuses existing progress')
    controls:Disable();humanoid.WalkSpeed=12;humanoid.AutoRotate=true
    local setup=remote:InvokeServer('Begin')
    assert(not setup.error,setup.error)
    task.wait(.75)
    for index,point in setup.points do
        humanoid:MoveTo(point+Vector3.new(0,setup.offset,0))
        waitUntil(function()
            local delta=root.Position-point
            -- MoveTo naturally stops within about one stud. Match the server's
            -- existing footprint, then require its independent landing hold.
            return Vector2.new(delta.X,delta.Z).Magnitude<1 and status:GetAttribute('Visited')>=index
        end,7,'Could not walk to waypoint '..index,function()
            local delta=root.Position-point
            return game:GetService('HttpService'):JSONEncode({
                waypoint=index,target={point.X,point.Y,point.Z},
                horizontalDistance=Vector2.new(delta.X,delta.Z).Magnitude,
                serverVisited=status:GetAttribute('Visited'),serverRemaining=status:GetAttribute('Remaining'),
                serverStatus=status:GetAttribute('Status'),
            })
        end)
        humanoid:Move(Vector3.zero)
    end
    result=remote:InvokeServer('Finish')
    assert(result.pass,game:GetService('HttpService'):JSONEncode(result))
end,debug.traceback)
connection:Disconnect()
if not ok and remote.Parent then pcall(function() remote:InvokeServer('Cancel') end) end
if humanoid.Parent then
    humanoid:Move(Vector3.zero);humanoid.WalkSpeed=speed;humanoid.AutoRotate=autoRotate
end
if enabled~=false then controls:Enable() end
if player.Character==character and character.Parent then
    character:PivotTo(original);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
end
assert(ok,err)
return {result='PASS real Humanoid tray route, 96 accounted Minis, six species and partial-pile repack',server=result}
