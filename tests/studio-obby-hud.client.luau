-- Run in Studio Client after syncing ObbyPresentation and ObbyHUD.
-- Uses a private local world stub; never modifies the actual multiplier sign,
-- plays audio, fires network requests, or moves the player/camera.
local HUD=require(game.Players.LocalPlayer.PlayerScripts.Controllers.ObbyHUD)
local fixture=Instance.new('Folder');fixture.Name='ObbyHUDRegression';fixture.Parent=workspace
local function makeWorld()
    local world=Instance.new('Folder');world.Name='MergeABrainrotGenerated';world.Parent=fixture
    local anchor=Instance.new('Part');anchor.Name='MiniMultiplierBillboardAnchor'
    anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
    anchor.CFrame=CFrame.new(0,-200,0);anchor.Parent=world
    local gui=Instance.new('BillboardGui');gui.Name='MiniMultiplierBillboard'
    gui.Size=UDim2.fromOffset(460,125);gui.MaxDistance=500;gui.AlwaysOnTop=true;gui.Adornee=anchor;gui.Parent=anchor
    local title=Instance.new('TextLabel');title.Name='MultiplierTitle';title.Text='Mini Multiplier: 1.27x';title.Parent=gui
    local countdown=Instance.new('TextLabel');countdown.Name='NextUpdateCountdown';countdown.Text='Updating in 37s';countdown.Parent=gui
    return world,gui
end
local function packet(now,phase,checkpoint,expires,cooldown,bonus)
    return {status='Ready',sessionKey='obby-hud-fixture',revision=1,serverNow=now,
        obby={phase=phase,checkpoint=checkpoint or 0,totalCheckpoints=10,
            boostExpiresAt=expires or 0,cooldownEndsAt=cooldown or 0,bonusHundredths=bonus or 0}}
end
local world,gui=makeWorld()
local hud=HUD.new(fixture)
local replacement=nil
local watch=nil
local ok,err=pcall(function()
    assert(not hud:receive(packet(100,'idle'),9000))
    local label=assert(gui:FindFirstChild('ObbyStatus'))
    assert(label:IsA('TextLabel') and label.Text=='Obby available now!')
    assert(label.Position==UDim2.fromOffset(0,125) and label.Size==UDim2.new(1,0,0,30))
    assert(label.Font==Enum.Font.FredokaOne and label:FindFirstChild('TextOutline'))
    assert(label.BackgroundTransparency==1 and not label.Active,'Status must be nonmodal')
    assert(gui.Size==UDim2.fromOffset(460,160) and gui.MaxDistance==500)
    assert(gui.MultiplierTitle.Text=='Mini Multiplier: 1.27x' and gui.NextUpdateCountdown.Text=='Updating in 37s',
        'The personal bonus must not rewrite the global multiplier')
    for checkpoint=1,10 do
        assert(not hud:receive(packet(100+checkpoint,'running',checkpoint),9000+checkpoint))
        assert(label.Text=='Obby: step '..checkpoint..' / 10','Progress changes must refresh immediately')
    end
    local notices=0
    local completion=packet(111,'cooldown',0,411,711,25)
    if hud:receive(completion,9011) then notices+=1 end
    assert(label.Text=='+0.25x Minis • 5:00')
    local textChanges=0
    watch=label:GetPropertyChangedSignal('Text'):Connect(function() textChanges+=1 end)
    for tick=1,19 do hud:update(9011+tick*.05) end
    task.wait()
    assert(textChanges==0,'The existing .05 loop must not rewrite text every tick')
    hud:update(9012)
    task.wait()
    assert(textChanges==1 and label.Text=='+0.25x Minis • 4:59')
    if hud:receive(completion,9012.1) then notices+=1 end
    if hud:receive(packet(110,'running',9),9012.2) then notices+=1 end
    if hud:receive(packet(112,'cooldown',0,411,711,25),9012) then notices+=1 end
    assert(notices==1,'Replay/stale/ongoing-award packets must not repeat the cue')
    hud:update(9311)
    assert(label.Text=='Obby ready in 5:00','Boost expiry must keep the cooldown visible')
    hud:update(9611)
    assert(label.Text=='Obby available now!','Cooldown expiry must become ready without a new snapshot')
    assert(notices==1,'Expiry must not be a completion cue')
    watch:Disconnect();watch=nil

    hud:clear()
    assert(not gui:FindFirstChild('ObbyStatus') and gui.Size==UDim2.fromOffset(460,125))
    assert(not hud:receive(packet(712,'idle'),9612))
    world:Destroy()
    world,gui=makeWorld()
    hud:update(9613)
    assert(gui:FindFirstChild('ObbyStatus') and gui.Size==UDim2.fromOffset(460,160),'Rebuilt worlds must acquire a new local label')
    replacement=HUD.new(fixture)
    assert(not replacement:receive(packet(713,'cooldown',0,1013,1313,25),9613),
        'A new controller seeing an existing award must establish a quiet baseline')
    local count=0
    for _,child in gui:GetChildren() do if child.Name=='ObbyStatus' then count+=1 end end
    assert(count==1 and hud.destroyed,'A replacement controller must retire the previous owner')
    hud:update(9700)
    assert(gui.ObbyStatus.Text=='+0.25x Minis • 5:00','The retired controller must not rewrite its replacement')
    replacement:destroy();replacement:destroy()
    assert(not gui:FindFirstChild('ObbyStatus') and gui.Size==UDim2.fromOffset(460,125),'Destroy must restore the original billboard height')
    assert(gui.MultiplierTitle.Text=='Mini Multiplier: 1.27x' and gui.MaxDistance==500)
    replacement:update(9701)
    assert(not gui:FindFirstChild('ObbyStatus'),'Destroyed controllers must stay detached')
end)
if watch then watch:Disconnect() end
hud:destroy()
if replacement then replacement:destroy() end
fixture:Destroy()
assert(ok,err)
print('PASS local obby label, styling, independent global sign, full run, countdown throttle, one completion, rebuild, duplicate ownership and cleanup')
