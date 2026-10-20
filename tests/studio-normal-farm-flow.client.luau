-- Disposable fresh Studio Play only. Uses shipped Main/controller/server for every
-- gameplay command; this driver only requests State and walks the actual Humanoid.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local HttpService=game:GetService('HttpService')
assert(RunService:IsStudio(),'Studio-only fixture')
local player=Players.LocalPlayer
local character=assert(player.Character)
local humanoid=assert(character:FindFirstChildOfClass('Humanoid'))
local root=assert(character:FindFirstChild('HumanoidRootPart'))
local controls=require(player.PlayerScripts.PlayerModule):GetControls()
local original=character:GetPivot()
local enabled=controls.controlsEnabled
local net=game.ReplicatedStorage.FarmNetwork
local config=require(game.ReplicatedStorage.Shared.Config)
local economy=require(game.ReplicatedStorage.Shared.Economy)
local offset=humanoid.HipHeight+root.Size.Y/2+(if humanoid.RigType==Enum.HumanoidRigType.R6 then 2 else 0)
local state,receivedAt
local responses={}
local phase='initial'
local report={scope='Normal shipped Main/controller/server; one staging move, then actual Humanoid walks. No direct gameplay commands.',phases={},airborneCollections=0,heldAirborneCollections=0,responses=responses}
local status=Instance.new('StringValue')
status.Name='NormalFarmFlowResult'
status.Value='running'
status.Parent=player.PlayerGui
local snapshotConnection=net.StateSnapshot.OnClientEvent:Connect(function(incoming)
    if incoming.status=='Ready' then state=incoming;receivedAt=os.clock() end
end)
local resultConnection=net.CommandResult.OnClientEvent:Connect(function(response)
    local now=os.clock()
    if response.action=='CollectNearby' and response.code=='OK' then
        local estimated=state and state.serverNow+now-receivedAt or 0
        local flight=0
        for _,token in state and state.tokens or {} do if token.readyAt>estimated then flight+=1 end end
        -- At the source/tray approach the ordinary collection may include a
        -- mixture; only count unambiguously airborne, all-flight snapshots.
        if state and #state.tokens>0 and flight==#state.tokens then
            report.airborneCollections+=1
            if state.lucky and state.lucky.held then report.heldAirborneCollections+=1 end
        end
    end
    if response.action~='CollectNearby' or response.code~='OK' then
        table.insert(responses,{phase=phase,action=response.action,code=response.code,at=now,
            level=state and state.processorLevel,held=state and state.lucky and state.lucky.held or false})
    end
end)
local function waitUntil(predicate,seconds,message)
    local deadline=os.clock()+seconds
    repeat
        if predicate() then return end
        assert(humanoid.Health>0,'Character died during '..phase)
        task.wait(.05)
    until os.clock()>=deadline
    error(message)
end
local function setPhase(value)
    phase=value
    table.insert(report.phases,{name=value,at=os.clock()})
    status:SetAttribute('Phase',value)
end
local function walk(x,z)
    local target=state.plotCFrame:PointToWorldSpace(Vector3.new(x,0,z)*config.PlotScale)
    local deadline=os.clock()+20
    repeat
        humanoid:MoveTo(target)
        task.wait(.1)
        local foot=root.Position-Vector3.new(0,offset,0)
        if (Vector2.new(foot.X,foot.Z)-Vector2.new(target.X,target.Z)).Magnitude<=1 then return end
    until os.clock()>=deadline
    error('Walk failed at '..phase..' to '..x..','..z)
end
local function successCount(action)
    local count=0
    for _,r in responses do if r.action==action and r.code=='OK' then count+=1 end end
    return count
end
local ok,err=xpcall(function()
    net.Command:FireServer('State',{})
    waitUntil(function()return state~=nil end,5,'No snapshot')
    assert(#state.producers<=1 and state.processorLevel==0 and #state.saleQueue==0,'Fresh or starter-only Play required')
    controls:Disable()
    if not state.starterClaimed then
        setPhase('buy-entry')
        character:PivotTo(state.plotCFrame*CFrame.new(Vector3.new(config.BuyPads['1'],0,config.BuyZ-10)*config.PlotScale+Vector3.new(0,offset+.2,0)))
        task.wait(.5)
        walk(config.BuyPads['1'],config.BuyZ)
        waitUntil(function()return #state.producers==1 end,10,'Shipped entry did not buy')
    else report.startedWithStarter=true end
    setPhase('airborne-and-held-lucky')
    walk(0,config.BuyZ-8)
    walk(0,config.TrayZ)
    waitUntil(function()
        status:SetAttribute('Bag',economy.count(state.bag))
        status:SetAttribute('HeldLucky',state.lucky~=nil and state.lucky.held==true)
        return state.lucky and state.lucky.held and economy.count(state.bag)>=100 and report.heldAirborneCollections>=3
    end,420,'Natural Lucky/airborne collection condition not reached')
    local overlay=player.PlayerGui.BrainrotHUD.SafeArea.PanelOverlay
    assert(overlay.Visible and not overlay.Active and overlay.BackgroundTransparency==1,'Lucky card became modal')
    report.bagBeforeDeposit=economy.count(state.bag)
    report.heldLuckyId=state.lucky.id
    setPhase('deposit')
    walk(-15,config.BuyZ-10)
    walk(-15,config.SellZ+10)
    walk(config.SellX,config.SellZ)
    waitUntil(function()return successCount('Deposit')>=1 and #state.bag==0 end,4,'Normal deposit failed')
    assert(state.lucky and state.lucky.held and overlay.Visible,'Deposit closed held Lucky card')
    setPhase('standing-claim')
    walk(config.ClaimX,config.ClaimZ)
    waitUntil(function()return successCount('Claim')>=3 end,12,'Standing claim did not repeat')
    waitUntil(function()return #state.saleQueue==0 and state.soldUnits==0 end,80,'Standing claim did not drain timed sales')
    report.claims=successCount('Claim')
    report.coinsBeforeUpgrade=state.coinUnits
    setPhase('standing-upgrade')
    walk(config.UpgradeX,config.UpgradeZ)
    waitUntil(function()return state.processorLevel>=2 end,8,'Standing upgrade did not repeat')
    report.processorLevel=state.processorLevel
    report.upgrades=successCount('Upgrade')
    assert(state.lucky and state.lucky.held and overlay.Visible and not overlay.Active,'Lucky card blocked gameplay')
    report.pass=true
end,debug.traceback)
report.error=if ok then nil else tostring(err)
report.pass=ok
snapshotConnection:Disconnect()
resultConnection:Disconnect()
humanoid:Move(Vector3.zero)
character:PivotTo(original)
if enabled then controls:Enable() end
status.Value=HttpService:JSONEncode(report)
status:SetAttribute('Phase',if ok then 'PASS' else 'FAIL')
print('[NormalFarmFlow]',status.Value)
