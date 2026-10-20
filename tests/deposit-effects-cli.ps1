$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$runtime = @'
-- Execute the actual effect/runtime/lifecycle with deterministic engine stand-ins.
-- This proves scheduling/ownership, not native rendering or downloaded asset quality.
local now,timers,workers,tweens,connections=0,{},{},{},{}
local function signal()
    local callbacks={}
    return {
        Connect=function(_,callback)
            local c={Connected=true,callback=callback};table.insert(callbacks,c);table.insert(connections,c)
            function c:Disconnect() self.Connected=false end
            return c
        end,
        emit=function(_,...) for _,c in table.clone(callbacks) do if c.Connected then c.callback(...) end end end,
    }
end
local task={}
local function schedule(seconds,callback)
    local thread=coroutine.create(callback)
    local item={at=now+seconds,thread=thread};table.insert(timers,item)
    return thread
end
task.delay=schedule
task.defer=function(callback) return schedule(0,callback) end
task.spawn=task.defer
task.cancel=function(thread) coroutine.close(thread) end
local function advance(seconds)
    local target=now+seconds
    while true do
        local index,item=nil,nil
        for i,t in timers do
            if t.at<=target and (not item or t.at<item.at) then index,item=i,t end
        end
        if not item then break end
        table.remove(timers,index);now=item.at
        if coroutine.status(item.thread)~='dead' then
            local ok,err=coroutine.resume(item.thread);assert(ok,err)
        end
    end
    now=target
end
local vectorMT={}
local function vector(x,y,z) return setmetatable({X=x,Y=y,Z=z or 0},vectorMT) end
vectorMT.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMT.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMT.__mul=function(a,n) return vector(a.X*n,a.Y*n,a.Z*n) end
local Vector2={new=vector}
local Vector3={new=vector,zero=vector(0,0,0)}
local UDim2={fromOffset=function(x,y) return {X={Offset=x},Y={Offset=y}} end}
UDim2.fromScale=function(x,y) return {X={Scale=x},Y={Scale=y}} end
local Instance={}
local methods={}
local instanceMT={
    __index=function(self,key) return methods[key] or self.props[key] end,
    __newindex=function(self,key,value)
        local old=self.props[key]
        self.props[key]=value
        if key=='Parent' and old~=value then
            if old then local i=table.find(old.children,self);if i then table.remove(old.children,i) end end
            if value then
                table.insert(value.children,self)
                self.props.AbsoluteSize=value.AbsoluteSize
                self.props.AbsolutePosition=value.AbsolutePosition
            end
            self.AncestryChanged:emit(self,value)
        end
    end,
}
function Instance.new(class)
    return setmetatable({props={ClassName=class,Name=class,Visible=true,
        AbsoluteSize=vector(1440,900),AbsolutePosition=vector(0,0),
        Destroying=signal(),AncestryChanged=signal()},children={}},instanceMT)
end
function methods:IsA(class) return self.ClassName==class or class=='GuiObject' and self.ClassName=='Frame' end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants()
    local items={}
    for _,child in self.children do table.insert(items,child);for _,item in child:GetDescendants() do table.insert(items,item) end end
    return items
end
function methods:FindFirstChild(name,recursive)
    for _,child in self.children do
        if child.Name==name then return child end
        if recursive then local found=child:FindFirstChild(name,true);if found then return found end end
    end
    return nil
end
function methods:Destroy()
    if self.dead then return end
    self.dead=true;self.Destroying:emit()
    for _,child in self:GetChildren() do child:Destroy() end
    self.Parent=nil
end
local loadMode,loadDelay='stall',0
local provider={}
function provider:PreloadAsync(_,callback)
    local worker=coroutine.running()
    table.insert(workers,worker)
    if loadDelay>0 then
        task.delay(loadDelay,function()
            if coroutine.status(worker)~='dead' then local ok,err=coroutine.resume(worker);assert(ok,err) end
        end)
        coroutine.yield()
    end
    if loadMode=='stall' then coroutine.yield() end
    if loadMode=='throw' then error('Unavailable asset') end
    if callback then callback('asset',if loadMode=='fail' then 'Failure' else 'Success') end
end
local TweenService={}
function TweenService:Create(item,info,properties)
    local tween={item=item,info=info,properties=properties}
    function tween:Play() self.at=now;table.insert(tweens,self) end
    function tween:Cancel() self.cancelled=true end
    return tween
end
local modules={VisualLifecycle=require('../src/client/Controllers/VisualLifecycle')}
local shared={WaitForChild=function(_,name) return name end}
local services={
    ContentProvider=provider,TweenService=TweenService,
    Debris={AddItem=function(_,item,seconds) task.delay(seconds,function() item:Destroy() end) end},
    ReplicatedStorage={WaitForChild=function(_,name) assert(name=='Shared');return shared end},
}
modules.CreatureCatalog={}
for i=1,8 do modules.CreatureCatalog['tier_'..i]={id='tier_'..i} end
modules.ModelFactory={producer=function(parent,name,species)
    local model=Instance.new('Model');model.Name=name;model.species=species.id;model.Parent=parent
    model.GetBoundingBox=function() return {Position=Vector3.zero},vector(2,3,2) end
    return model
end}
modules.TextStyle={Gold='gold'}
local environment=setmetatable({
    task=task,Instance=Instance,Vector2=Vector2,Vector3=Vector3,UDim2=UDim2,
    UDim={new=function(a,b) return {Scale=a,Offset=b} end},
    Color3={new=function(...) return {...} end,fromRGB=function(...) return {...} end},
    CFrame={lookAt=function(...) return {...} end},
    Enum={EasingStyle={Quad='Quad'},EasingDirection={Out='Out',In='In'},AssetFetchStatus={Success='Success'}},
    TweenInfo={new=function(seconds,...) return {Time=seconds} end},
    game={GetService=function(_,name) return assert(services[name],name) end},
    workspace={},script={Parent={WaitForChild=function(_,name) return name end}},
    require=function(name) return assert(modules[name],name) end,
    warn=function(message) error(message) end,
},{__index=getfenv()})
local function compile(source)
    local chunk=assert(loadstring(source));setfenv(chunk,environment);return chunk()
end
'@
$runtimeSource = Get-Content -LiteralPath (Join-Path $repo 'src/client/Controllers/VisualRuntime.luau') -Raw
$effectsSource = Get-Content -LiteralPath (Join-Path $repo 'src/client/Controllers/DepositEffects.luau') -Raw
$scriptText = $runtime + "`nmodules.VisualRuntime=compile([====[`n" + $runtimeSource + "`n]====])`nlocal Deposit=compile([====[`n" + $effectsSource + "`n]====])`n"
$scriptText += @'
local function gui(width)
    local screen=Instance.new('ScreenGui');screen.Parent=Instance.new('Folder')
    screen.AbsoluteSize=vector(width or 1440,900)
    return screen
end
local bag={'tier_1','tier_2','tier_3','tier_4','tier_5','tier_6','tier_7','tier_8'}
local function named(parent,name)
    local found={}
    for _,item in parent:GetDescendants() do if item.Name==name then table.insert(found,item) end end
    return found
end
local function liveWorkers()
    local count=0;for _,thread in workers do if coroutine.status(thread)~='dead' then count+=1 end end;return count
end
local function clean(screen)
    screen:Destroy();advance(4)
    assert(liveWorkers()==0,'Finished effects must release every visual preload worker')
    for _,c in connections do assert(not c.Connected,'Finished effects must disconnect ownership watches') end
end
-- RED on the original module: no pulse ever appears when preload stalls.
local screen=gui()
Deposit.play(screen,nil,bag);advance(.51)
assert(#named(screen,'DepositPulse')==1,'A stalled portrait load must not suppress the .5s gold deposit pulse')
assert(liveWorkers()==0,'The short portrait budget must cancel a stalled worker before the pulse')
for _,portrait in named(screen,'FlyingMini') do assert(not portrait.Visible,'Timed-out portraits must stay hidden') end
local count=#tweens
advance(.7);assert(#named(screen,'DepositPulse')==1 and #tweens==count,'Timeout must not repeat the pulse')
advance(.7);assert(not screen:FindFirstChild('DepositCelebration'),'Lifetime must stay bounded at1.9s')
clean(screen)

-- Warm assets preserve species sampling, stagger, both flight durations and pulse.
loadMode='loaded';screen=gui();local start=now;local firstTween=#tweens
Deposit.play(screen,nil,bag);advance(0)
local portraits=named(screen,'FlyingMini')
assert(#portraits==6 and portraits[1].Visible and not portraits[2].Visible)
for index,portrait in portraits do
    assert(portrait:FindFirstChild('DepositedMini',true).species==bag[math.ceil(index*#bag/6)],'Use the actual deposited species sample')
end
advance(.301)
for _,portrait in portraits do assert(portrait.Visible) end
advance(.02)
assert(tweens[firstTween+1].info.Time==.32 and tweens[firstTween+7].info.Time==.38,'Flight phases must preserve .32/.38 durations')
for index=1,6 do assert(math.abs(tweens[firstTween+index].at-start-(index-1)*.06)<1e-6,'Stagger changed') end
advance(.18)
assert(#named(screen,'DepositPulse')==1,'Warm path keeps the .5s pulse')
local pulse=named(screen,'DepositPulse')[1]
local pulseTween=nil
for _,t in tweens do if t.item==pulse then pulseTween=t end end
assert(pulseTween and math.abs(pulseTween.at-start-.5)<1e-6 and pulseTween.info.Time==.65)
advance(1.4);assert(not screen:FindFirstChild('DepositCelebration'))
clean(screen)

screen=gui(390);Deposit.play(screen,nil,bag);advance(0)
assert(#named(screen,'FlyingMini')==4,'Phone must retain the four-portrait cap')
clean(screen)
loadDelay=.2;screen=gui();Deposit.play(screen,nil,bag);advance(.19)
for _,portrait in named(screen,'FlyingMini') do assert(not portrait.Visible) end
advance(.02);assert(named(screen,'FlyingMini')[1].Visible,'A successful load inside the budget must still animate')
advance(.3);assert(#named(screen,'DepositPulse')==1,'A delayed but successful load must not delay the pulse')
clean(screen)
loadDelay=.8;screen=gui();Deposit.play(screen,nil,bag);advance(.51)
assert(liveWorkers()==0 and #named(screen,'DepositPulse')==1)
advance(.4)
for _,portrait in named(screen,'FlyingMini') do assert(not portrait.Visible,'Late asset completion must not reveal timed-out portraits') end
clean(screen);loadDelay=0
for _,mode in {'fail','throw'} do
    loadMode=mode;screen=gui();Deposit.play(screen,nil,bag);advance(.51)
    assert(#named(screen,'DepositPulse')==1,'Unavailable assets must keep the native pulse')
    for _,portrait in named(screen,'FlyingMini') do assert(not portrait.Visible) end
    clean(screen)
end
-- Replacing a layer cancels its preload/timers immediately; only the newest pulses.
loadMode='stall';screen=gui();Deposit.play(screen,nil,bag);advance(.1)
local old=screen:FindFirstChild('DepositCelebration');local oldWorker=workers[#workers]
Deposit.play(screen,nil,bag)
assert(old.Parent==nil and coroutine.status(oldWorker)=='dead','Replacement must immediately cancel the previous worker')
advance(.41);assert(#named(screen,'DepositPulse')==0,'Old pulse timer must be cancelled')
advance(.1);assert(#named(screen,'DepositPulse')==1)
local resumed=coroutine.resume(oldWorker)
assert(not resumed and #named(screen,'DepositPulse')==1,'A cancelled late completion cannot restart a visual')
clean(screen)
screen=gui();Deposit.play(screen,nil,bag);advance(.1)
local worker=workers[#workers];screen:Destroy()
assert(coroutine.status(worker)=='dead' and liveWorkers()==0,'GUI destruction must cancel loading promptly')
advance(3);assert(#screen:GetDescendants()==0)
clean(screen)
screen=gui();Deposit.play(screen,nil,bag);advance(.1);screen.Parent=nil
assert(liveWorkers()==0 and not screen:FindFirstChild('DepositCelebration'),'Removing the GUI must cancel the visual without requiring Destroy')
clean(screen)

-- The shared runtime still gives other reveal callers their original3s budget.
screen=gui();local finished,loaded=0,0
local scope=modules.VisualRuntime.new(screen,function() finished+=1 end)
modules.VisualRuntime.load(scope,{},function(ok) assert(not ok);loaded+=1 end)
advance(2.99);assert(loaded==0 and liveWorkers()==1)
advance(.02);assert(loaded==1 and liveWorkers()==0 and finished==0)
scope:finish('complete');assert(finished==1);clean(screen)
print('PASS actual deposit/runtime: stalled and failed assets, pulse, warm timing/species, phone cap, replace/destroy cancellation, late completion, cleanup and unchanged default timeout')
'@
$target = Join-Path $repo '.tools/deposit-effects-cli.luau'
[System.IO.File]::WriteAllText($target, $scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
