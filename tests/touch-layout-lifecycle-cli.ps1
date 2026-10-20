$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
# Execute the actual FarmUI observer with deterministic signals/deferred tasks.
# Native device timing and rendering remain separate Studio checks.
$source=[IO.File]::ReadAllText((Join-Path $repo 'src/client/Controllers/FarmUI.luau'))
$observer=[regex]::Match($source,'(?s)local function observeTouchLayout\(.*?(?=\r?\nfunction UI.new)').Value
if (-not $observer) { throw 'FarmUI touch observer was not found' }
if (-not $source.Contains('observeTouchLayout(gui,function() self:resize() end)')) { throw 'FarmUI.new must install its actual observer' }
$runtime=@'
local active=0
local function signal()
    local listeners={}
    return {Connect=function(_,callback)
        local connection={Connected=true}
        function connection:Disconnect()
            if self.Connected then self.Connected=false;listeners[self]=nil;active-=1 end
        end
        listeners[connection]=callback;active+=1;return connection
    end,Fire=function(...)
        local copy=table.clone(listeners)
        for connection,callback in copy do if connection.Connected then callback(...) end end
    end}
end
local deferred={}
local task={defer=function(callback) table.insert(deferred,callback) end}
local function flush()
    local work=deferred;deferred={}
    for _,callback in work do callback() end
end
local Input={TouchEnabled=true,changed=signal()}
function Input:GetPropertyChangedSignal(property) assert(property=='TouchEnabled');return self.changed end
local searches=0
local function object(name,parent,isGui)
    local value={Name=name,Parent=parent,children={},AbsoluteSize={X=70,Y=70},properties={},
        DescendantAdded=signal(),DescendantRemoving=signal(),Destroying=signal(),AncestryChanged=signal()}
    function value:IsA(class) return class=='GuiObject' and isGui end
    function value:GetPropertyChangedSignal(property)
        self.properties[property]=self.properties[property] or signal();return self.properties[property]
    end
    function value:FindFirstChild(wanted,recursive)
        searches+=1
        for _,child in self.children do if child.Parent==self and child.Name==wanted then return child end end
        if recursive then
            for _,child in self.children do
                if child.Parent==self then local result=child:FindFirstChild(wanted,true);if result then return result end end
            end
        end
        return nil
    end
    if parent then table.insert(parent.children,value);parent.DescendantAdded.Fire(value) end
    return value
end
'@
$checks=@'
local owner=object('PlayerGui')
local gui=object('BrainrotHUD',owner)
local touch=object('TouchGui',owner)
local jump=object('JumpButton',touch,true)
local updates=0
observeTouchLayout(gui,function() updates+=1 end)
local baselineSearches=searches
for i=1,20 do flush() end
assert(searches==baselineSearches and updates==0,'Idle observer must not scan or resize')
jump.AbsoluteSize={X=120,Y=120};jump:GetPropertyChangedSignal('AbsoluteSize').Fire()
assert(#deferred==1,'Native Jump growth must schedule a resize without a state packet')
flush();assert(updates==1,'Native Jump growth must resize immediately on deferred delivery')
for i=1,8 do jump:GetPropertyChangedSignal('AbsoluteSize').Fire() end
assert(#deferred==1,'A burst of native layout changes must coalesce')
flush();assert(updates==2)
local oldJump=jump
touch.DescendantRemoving.Fire(jump);owner.DescendantRemoving.Fire(jump)
jump.Parent=nil
local replacement=object('JumpButton',touch,true);owner.DescendantAdded.Fire(replacement)
flush();local before=updates
oldJump:GetPropertyChangedSignal('AbsoluteSize').Fire();flush()
assert(updates==before,'Removed Jump must release its observer')
replacement:GetPropertyChangedSignal('AbsoluteSize').Fire();flush()
assert(updates==before+1,'Replacement Jump must be watched')
owner.DescendantRemoving.Fire(touch);touch.Parent=nil
flush();before=updates
replacement:GetPropertyChangedSignal('AbsoluteSize').Fire();flush()
assert(updates==before,'Removed TouchGui must release the old Jump')
local nextTouch=object('TouchGui',owner);flush()
local lateJump=object('JumpButton',nextTouch,true);owner.DescendantAdded.Fire(lateJump);flush()
before=updates;lateJump:GetPropertyChangedSignal('AbsoluteSize').Fire();flush()
assert(updates==before+1,'Late Jump after TouchGui recreation must be watched')
before=updates;Input.TouchEnabled=false;Input.changed.Fire();flush()
assert(updates==before+1,'TouchEnabled change must refresh the desktop layout')
local stableConnections=active
for i=1,20 do
    owner.DescendantRemoving.Fire(lateJump);lateJump.Parent=nil
    lateJump=object('JumpButton',nextTouch,true);owner.DescendantAdded.Fire(lateJump);flush()
    assert(active==stableConnections,'Replacing controls must not accumulate connections')
end
-- Destruction invalidates already queued work and removes the service listener.
lateJump:GetPropertyChangedSignal('AbsoluteSize').Fire()
before=updates;gui.Destroying.Fire();gui.Parent=nil;gui.AncestryChanged.Fire(gui,nil)
flush();Input.changed.Fire();lateJump:GetPropertyChangedSignal('AbsoluteSize').Fire();flush()
assert(updates==before and active==0,'Destroyed HUD must not retain listeners or queued callbacks')
-- Detaching the HUD is also a lifetime boundary.
local detached=object('BrainrotHUD',owner)
observeTouchLayout(detached,function() error('Detached HUD resized') end)
detached.Parent=nil;detached.AncestryChanged.Fire(detached,nil);flush()
assert(active==0,'Detached HUD must release all external listeners')
print('PASS actual FarmUI touch observer: immediate size updates, coalescing, late/replaced controls, input changes, idle bounds and destruction/detachment cleanup')
'@
$target=Join-Path $repo '.tools/touch-layout-lifecycle-cli.luau'
[IO.File]::WriteAllText($target,$runtime+"`n"+$observer+"`n"+$checks)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
