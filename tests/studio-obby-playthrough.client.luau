-- Run only in a disposable normal Studio Play session, after syncing the obby.
-- Teleports to the ground beside START once, then uses Humanoid walking/jumping
-- through every platform. Restores controls and the original character position.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
assert(RunService:IsStudio(),'Studio-only gameplay fixture')
local player=Players.LocalPlayer
local character=assert(player.Character,'Character required')
local humanoid=assert(character:FindFirstChildOfClass('Humanoid'))
local root=assert(character:FindFirstChild('HumanoidRootPart'))
local config=require(game.ReplicatedStorage.Shared.ObbyConfig)
local controls=require(player.PlayerScripts.PlayerModule):GetControls()
local original=character:GetPivot()
local speed=humanoid.WalkSpeed
local enabled=controls.controlsEnabled
local offset=humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0)
local packets={}
local last=nil
local trajectory={}
local jumpIndex=0
local lastTrace=0
local movementTrace=RunService.Heartbeat:Connect(function()
    if os.clock()-lastTrace<.06 then return end
    lastTrace=os.clock()
    table.insert(trajectory,{step=jumpIndex,x=root.Position.X,y=root.Position.Y-offset,z=root.Position.Z,
        vertical=root.AssemblyLinearVelocity.Y,state=humanoid:GetState().Name,jump=humanoid.Jump})
    if #trajectory>64 then table.remove(trajectory,1) end
end)
local connection=game.ReplicatedStorage.FarmNetwork.StateSnapshot.OnClientEvent:Connect(function(state)
    if state.obby then
        last=state.obby
        table.insert(packets,{checkpoint=last.checkpoint,bonus=last.bonusHundredths,phase=last.phase})
    end
end)
local function at(pad)
    local foot=root.Position-Vector3.new(0,offset,0)
    return math.abs(foot.X-pad.x)<pad.halfX+.05 and math.abs(foot.Z-pad.z)<pad.halfZ+.05
        and math.abs(foot.Y-pad.y)<.4
end
local function waitUntil(predicate,seconds,message)
    local deadline=os.clock()+seconds
    repeat if predicate() then return end;task.wait(.03) until os.clock()>deadline
    error(message..' at '..tostring(root.Position)..'; state='..game.HttpService:JSONEncode(last or {}))
end
local function walkTo(point)
    humanoid:MoveTo(point)
    waitUntil(function()
        local delta=root.Position-point
        return Vector2.new(delta.X,delta.Z).Magnitude<.55
    end,3,'Could not reach takeoff edge')
end
local ok,err=xpcall(function()
    game.ReplicatedStorage.FarmNetwork.Command:FireServer('State',{})
    waitUntil(function() return last~=nil end,4,'Initial server snapshot not received')
    assert(last.bonusHundredths==0 and last.cooldownRemaining==0,'Run in a fresh Play session without an active obby cooldown')
    controls:Disable()
    humanoid.WalkSpeed=16
    local first=config.Checkpoints[1]
    -- Start on the hub floor, with enough horizontal clearance to jump onto 1.
    character:PivotTo(CFrame.new(first.x-5,offset+.55,first.z))
    root.AssemblyLinearVelocity=Vector3.zero
    task.wait(.6)
    for index=1,11 do
        jumpIndex=index
        local target=if index==11 then config.Finish else config.Checkpoints[index]
        if index>1 then
            local previous=config.Checkpoints[index-1]
            local direction=Vector3.new(target.x-previous.x,0,target.z-previous.z).Unit
            local edge=math.min(1.9/math.max(math.abs(direction.X),.001),1.9/math.max(math.abs(direction.Z),.001))
            walkTo(Vector3.new(previous.x,previous.y+offset,previous.z)+direction*edge)
        end
        -- PlayerModule still clears the Jump flag while its input is disabled;
        -- enter the normal Humanoid jumping state without injecting velocity.
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        humanoid:MoveTo(Vector3.new(target.x,target.y+offset,target.z))
        waitUntil(function() return at(target) and humanoid.FloorMaterial~=Enum.Material.Air end,3,'Jump failed at platform '..index)
        humanoid:Move(Vector3.zero)
        -- Hold a real landing long enough for the server's authoritative sample.
        if index<=10 then
            waitUntil(function() return last and last.checkpoint==index end,3,'Server did not accept checkpoint '..index)
        else
            waitUntil(function() return last and last.bonusHundredths==config.BonusHundredths end,3,'Server did not award the finish')
        end
    end
    assert(last.boostExpiresAt>0 and last.cooldownEndsAt>last.boostExpiresAt)
end,debug.traceback)
humanoid:Move(Vector3.zero)
humanoid.WalkSpeed=speed
if enabled~=false then controls:Enable() end
if character.Parent then character:PivotTo(original);root.AssemblyLinearVelocity=Vector3.zero end
connection:Disconnect()
movementTrace:Disconnect()
assert(ok,tostring(err)..'\nRecent trajectory: '..game.HttpService:JSONEncode(trajectory))
return {result='PASS real Humanoid route through ten checkpoints and server-awarded finish',packets=packets}
