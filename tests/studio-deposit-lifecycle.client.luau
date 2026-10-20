-- Run with Source access in Studio Client after syncing DepositEffects/VisualRuntime.
-- Disposable module clones inject asset outcomes; real UI/model/tween/task APIs run.
-- Does not modify normal UI, preferences, player state or network traffic.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsClient(),'Studio Client required')
local player=game.Players.LocalPlayer
local controllers=player.PlayerScripts.Controllers
local fixture=Instance.new('Folder')
fixture.Name='DepositLifecycleFixture_'..game:GetService('HttpService'):GenerateGUID(false)
fixture.Parent=player.PlayerScripts
local screen=Instance.new('ScreenGui')
screen.Name='DepositLifecycleQA';screen.Enabled=false;screen.IgnoreGuiInset=true;screen.Parent=player.PlayerGui
local loader=nil
local metrics={cases=0}
local function waitUntil(test,seconds,message)
    local deadline=os.clock()+seconds
    while not test() and os.clock()<deadline do task.wait(.02) end
    assert(test(),message)
end
local function childrenNamed(parent,name)
    local result={}
    for _,item in parent:GetDescendants() do if item.Name==name then table.insert(result,item) end end
    return result
end
local function liveWorkers()
    local count=0
    for _,worker in loader.workers do if coroutine.status(worker)~='dead' then count+=1 end end
    return count
end
local ok,err=xpcall(function()
    local provider=Instance.new('ModuleScript');provider.Name='FixtureLoader'
    provider.Source=[[
local Loader={mode='stall',workers={}}
function Loader:PreloadAsync(assets,callback)
    table.insert(self.workers,coroutine.running())
    if self.mode=='stall' then task.wait(30) end
    if self.mode=='throw' then error('Injected unavailable deposit asset') end
    callback('fixture',if self.mode=='fail' then Enum.AssetFetchStatus.Failure else Enum.AssetFetchStatus.Success)
end
return Loader
]]
    provider.Parent=fixture
    loader=require(provider)
    for _,name in {'VisualLifecycle','VisualRuntime','DepositEffects'} do
        local module=controllers[name]:Clone()
        if name=='VisualRuntime' or name=='DepositEffects' then
            local source,replacements=module.Source:gsub(
                "local ContentProvider=game:GetService%('ContentProvider'%)",
                "local ContentProvider=require(script.Parent.FixtureLoader)")
            if name=='VisualRuntime' then
                assert(replacements==1,'Expected one ContentProvider binding in the disposable runtime')
            else
                -- The baseline effect owns its loader directly; inject that
                -- binding too so native RED exercises the same stalled fetch.
                assert(replacements<=1,'Unexpected direct effect loader bindings')
            end
            module.Source=source
        end
        module.Parent=fixture
    end
    local Deposit=require(fixture.DepositEffects)
    local Runtime=require(fixture.VisualRuntime)
    assert(Runtime.LoadTimeout==3,'Lucky/Discovery default load budget must remain3s')
    local bag={'tier_01','tier_02','tier_03','tier_04','tier_05','tier_06'}
    local function host(width,height)
        local frame=Instance.new('Frame');frame.Name='DepositHost';frame.Size=UDim2.fromOffset(width,height)
        frame.BackgroundTransparency=1;frame.Parent=screen
        RunService.Heartbeat:Wait()
        return frame
    end
    local function cleanup(frame)
        frame:Destroy()
        waitUntil(function() return liveWorkers()==0 end,.5,'Destroyed host retained a preload worker')
        metrics.cases+=1
    end
    -- Inject a never-completing fetch; asset-independent feedback must still run.
    local frame=host(1440,900)
    local started=os.clock()
    Deposit.play(frame,nil,bag)
    waitUntil(function() return #loader.workers>0 end,.3,'Fixture loader did not start')
    waitUntil(function() return #childrenNamed(frame,'DepositPulse')==1 end,.85,'Stalled loading suppressed the deposit pulse')
    assert(os.clock()-started<1.2,'Pulse missed its short feedback window')
    assert(liveWorkers()==0,'Portrait timeout must cancel the suspended visual worker')
    local portraits=childrenNamed(frame,'FlyingMini')
    assert(#portraits==6,'Desktop retains six actual-species portraits')
    for _,portrait in portraits do assert(not portrait.Visible,'Unavailable portraits must stay hidden') end
    local layer=assert(frame:FindFirstChild('DepositCelebration'))
    waitUntil(function() return not layer.Parent end,1.6,'Deposit lifetime exceeded1.9s plus scheduler tolerance')
    assert(#frame:GetChildren()==0,'Expired visual left UI behind')
    cleanup(frame)

    -- Actual native visibility/tweens, desktop/phone caps and successful-load expiry.
    loader.mode='loaded'
    for _,size in {{1440,900,6},{390,690,4},{640,280,6}} do
        frame=host(size[1],size[2])
        Deposit.play(frame,nil,bag)
        waitUntil(function()
            local items=childrenNamed(frame,'FlyingMini')
            if #items~=size[3] then return false end
            for _,item in items do if not item.Visible then return false end end
            return true
        end,.6,'Warm portraits did not appear within their stagger budget')
        assert(#childrenNamed(frame,'DepositCelebration')==1)
        waitUntil(function() return #childrenNamed(frame,'DepositPulse')==1 end,.5,'Warm path lost its pulse')
        waitUntil(function() return not frame:FindFirstChild('DepositCelebration') end,1.7,'Warm path failed cleanup')
        cleanup(frame)
    end
    for _,mode in {'fail','throw'} do
        loader.mode=mode;frame=host(390,690);Deposit.play(frame,nil,bag)
        waitUntil(function() return #childrenNamed(frame,'DepositPulse')==1 end,.85,'Failed asset suppressed native feedback')
        for _,portrait in childrenNamed(frame,'FlyingMini') do assert(not portrait.Visible) end
        cleanup(frame)
    end
    loader.mode='stall';frame=host(390,690)
    Deposit.play(frame,nil,bag)
    waitUntil(function() return liveWorkers()==1 end,.3,'Missing first stalled worker')
    local previous=frame:FindFirstChild('DepositCelebration')
    local previousWorker=loader.workers[#loader.workers]
    Deposit.play(frame,nil,bag)
    assert(not previous.Parent,'Replacement must remove the old layer')
    -- Destroying/AncestryChanged may be deferred until the next resumption point.
    waitUntil(function() return coroutine.status(previousWorker)=='dead' end,.3,'Replacement must cancel loading promptly')
    assert(#childrenNamed(frame,'DepositCelebration')==1 and #childrenNamed(frame,'FlyingMini')==4)
    waitUntil(function() return #childrenNamed(frame,'DepositPulse')==1 end,.85,'Replacement lost its only pulse')
    assert(coroutine.status(previousWorker)=='dead','Old load may not resume after its replacement')
    cleanup(frame)

    frame=host(1440,900);Deposit.play(frame,nil,bag)
    waitUntil(function() return liveWorkers()==1 end,.3,'Missing destroy-case worker')
    local worker=loader.workers[#loader.workers]
    screen:Destroy()
    waitUntil(function() return coroutine.status(worker)=='dead' and liveWorkers()==0 end,.3,'GUI destruction must promptly cancel loading')
    task.wait(.6)
    assert(#screen:GetChildren()==0,'Cancelled callbacks restarted the destroyed UI')
    metrics.cases+=1
end,debug.traceback)
screen:Destroy()
if loader then
    for _,worker in loader.workers do
        if coroutine.status(worker)~='dead' then pcall(task.cancel,worker) end
    end
end
fixture:Destroy()
assert(ok,err)
return {result='PASS deposit pulse under stalled/failed loading, warm desktop/phone/short layouts, replacement, GUI destruction and worker cleanup',cases=metrics.cases}
