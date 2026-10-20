$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
# Actual controller + actual layout, with native measured rectangles and
# observable GUI stand-ins. Native rendering/input remain separate checks.
$runtime = @'
local RealPresentation=require('../src/shared/MultiplierCuePresentation')
local layoutCalls=0
local Presentation=table.clone(RealPresentation)
Presentation.layout=function(...)
    layoutCalls+=1
    return RealPresentation.layout(...)
end
local modules={MultiplierCuePresentation=Presentation,MiniEvent={Minimum=50,Maximum=150},
    TextStyle={Price={},apply=function(label) label.TextOutline={Thickness=3} end}}
local shared={WaitForChild=function(_,name) return name end}
local game={GetService=function() return {WaitForChild=function() return shared end} end}
local function require(name) return modules[name] end
local Color3={fromRGB=function(...) return {...} end,new=function(...) return {...} end}
local ColorSequence={new=function(...) return {...} end}
local enumMT={__index=function(self,key) local value=setmetatable({},getmetatable(self));rawset(self,key,value);return value end}
local Enum=setmetatable({},enumMT)
local UDim2={fromOffset=function(x,y)return {X={Offset=x},Y={Offset=y}}end}
local vectorMT={__sub=function(a,b)return setmetatable({X=a.X-b.X,Y=a.Y-b.Y},getmetatable(a))end}
local function vector(x,y)return setmetatable({X=x,Y=y},vectorMT)end
local liveConnections=0
local function signal()
    local listeners={}
    return {Connect=function(_,callback)
        local connection={Connected=true}
        function connection:Disconnect()
            if not self.Connected then return end
            self.Connected=false;listeners[self]=nil;liveConnections-=1
        end
        listeners[connection]=callback;liveConnections+=1;return connection
    end,Fire=function(...)
        local copy=table.clone(listeners)
        for connection,callback in copy do if connection.Connected then callback(...) end end
    end}
end
local function object(class,name,parent,x,y,w,h)
    local o={Name=name,Parent=parent,Visible=true,Enabled=true,AbsolutePosition=vector(x or 0,y or 0),
        AbsoluteSize=vector(w or 0,h or 0),attributes={},properties={},attributeSignals={},children={},
        Destroying=signal(),AncestryChanged=signal(),ChildAdded=signal()}
    function o:IsA(wanted)return wanted==class or (wanted=='GuiObject' and class~='ScreenGui' and class~='UITextSizeConstraint')end
    function o:GetPropertyChangedSignal(key)
        self.properties[key]=self.properties[key] or signal();return self.properties[key]
    end
    function o:GetAttributeChangedSignal(key)
        self.attributeSignals[key]=self.attributeSignals[key] or signal();return self.attributeSignals[key]
    end
    function o:GetAttribute(key)return self.attributes[key]end
    function o:SetAttribute(key,value)
        if self.attributes[key]==value then return end
        self.attributes[key]=value;self:GetAttributeChangedSignal(key).Fire()
    end
    function o:GetChildren()return self.children end
    function o:FindFirstChild(key)
        for _,child in self.children do if child.Parent==self and child.Name==key then return child end end
        return nil
    end
    function o:Destroy()
        if self.destroyed then return end
        self.destroyed=true;self.Destroying.Fire();self.Parent=nil;self.AncestryChanged.Fire(self,nil)
    end
    if parent then table.insert(parent.children,o);parent.ChildAdded.Fire(o) end
    return o
end
local Instance={new=function(class)return object(class,class)end}
'@
$source = [IO.File]::ReadAllText((Join-Path $repo 'src/client/Controllers/MultiplierCue.luau'))
$checks = @'
local function overlaps(a,b)
    return a.x<b.x+b.w and a.x+a.w>b.x and a.y<b.y+b.h and a.y+a.h>b.y
end
local function labelRect(label)
    return {x=label.Position.X.Offset,y=label.Position.Y.Offset,w=label.Size.X.Offset,h=label.Size.Y.Offset}
end
local function verify(cue,regions)
    if not cue.label.Visible then return end
    local rect=labelRect(cue.label)
    for _,region in regions do assert(not overlaps(rect,region),'Cue covers '..region.name) end
end
local function makeView(w,h,reserve,stacked)
    local gui=object('ScreenGui','HUD')
    local root=object('Frame','SafeArea',gui,0,0,w,h)
    root:SetAttribute('TouchControlReserve',reserve);root:SetAttribute('TouchHudStacked',stacked)
    local view={gui=gui,root=root,bag=object('Frame','MiniBag',root,w-118,h-reserve-89,106,89)}
    return view
end
local function activate(cue)
    cue:receive({status='Ready',sessionKey='touch',revision=1,serverNow=1,eventHundredths=100},100)
    assert(not cue.label.Visible,'Quiet initial snapshot')
    cue:receive({status='Ready',sessionKey='touch',revision=2,serverNow=2,eventHundredths=110},101)
end
-- Actual portrait geometry. Upper UI/pickup rows can force the old controller
-- below the raised basket, directly over the native movement controls.
for _,case in {{401,720,110,306,630,70},{579,759,230,409,549,120},{320,440,110,225,350,70}} do
    local w,h,reserve=case[1],case[2],case[3]
    local view=makeView(w,h,reserve,true)
    view.panel=object('Frame','Panel',view.root,0,0,w,h-reserve-89)
    object('Frame','PickupGain',view.bag)
    local cue=Cue.new(view);activate(cue)
    verify(cue,{{name='native Jump',x=case[4],y=case[5],w=case[6],h=case[6]},
        {name='reserved touch band',x=0,y=h-reserve,w=w,h=reserve}})
    local before=layoutCalls
    for i=1,10 do cue:update(101+i*.01) end
    assert(layoutCalls==before,'Stable cue must not relayout or scan each tick')
    cue:update(104);assert(not cue.label.Visible,'Expiry still works without another snapshot')
    view.gui:Destroy();assert(cue.destroyed and liveConnections==0,'Destroy releases all control and attribute subscriptions')
end
-- A roomier landscape keeps the central gap available; only its two corners
-- are excluded. Changing attributes must invalidate the cached placement.
local view=makeView(800,600,0,false)
view.bag.AbsolutePosition=vector(360,400)
local cue=Cue.new(view);activate(cue)
assert(cue.label.Visible,'Unobstructed desktop cue remains visible')
local before=layoutCalls
view.root:SetAttribute('TouchControlReserve',230)
cue:update(101.1)
assert(layoutCalls==before+1,'Touch reserve invalidates the existing cue once')
verify(cue,{{name='left controls',x=0,y=370,w=220,h=230},
    {name='right controls',x=580,y=370,w=220,h=230}})
view.root:SetAttribute('TouchHudStacked',true);cue:update(101.2)
verify(cue,{{name='stacked band',x=0,y=370,w=800,h=230}})
view.root:SetAttribute('TouchControlReserve',0);cue:update(101.3)
assert(cue.label.Visible,'Desktop transition releases touch exclusions')
-- Sprint is created after Cue by Main. It is a single named child, not a
-- descendant scan; removal/replacement must release the old subscriptions.
local oldRect=labelRect(cue.label)
local sprint=object('TextButton','Sprint',view.root,oldRect.x,oldRect.y,82,44)
cue:update(101.4)
verify(cue,{{name='late Sprint',x=oldRect.x,y=oldRect.y,w=82,h=44}})
local connectionsWithSprint=liveConnections
sprint:Destroy();cue:update(101.5)
assert(liveConnections<connectionsWithSprint,'Removing Sprint releases its subscriptions')
local replacement=object('TextButton','Sprint',view.root,360,300,82,44)
cue:update(101.6)
verify(cue,{{name='replacement Sprint',x=360,y=300,w=82,h=44}})
replacement.AbsolutePosition=vector(360,350)
replacement:GetPropertyChangedSignal('AbsolutePosition').Fire()
cue:update(101.7)
verify(cue,{{name='moved Sprint',x=360,y=350,w=82,h=44}})
local previous=cue;cue=Cue.new(view)
assert(previous.destroyed,'Controller replacement destroys its old lifetime')
view.gui:Destroy();cue:destroy()
assert(liveConnections==0,'Repeated teardown leaves no control listeners')
print('PASS actual Cue touch-band/corner exclusion, late Sprint/move/replacement, coalescing, expiry and cleanup')
'@
$target = Join-Path $repo '.tools/touch-cue-cli.luau'
[IO.File]::WriteAllText($target, $runtime + "`nlocal Cue=(function()`n" + $source + "`nend)()`n" + $checks)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
