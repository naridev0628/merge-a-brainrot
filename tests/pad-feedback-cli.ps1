$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$runtime=@'
local created=0
local function node(name,class,parent)
 local item={Name=name,ClassName=class,Parent=parent,children={}}
 function item:IsA(kind) return kind==self.ClassName or (kind=='BasePart' and self.ClassName=='Part') end
 function item:FindFirstChild(key) return self.children[key] end
 function item:Destroy() self.destroyed=true;self.Parent=nil end
 if parent then parent.children[name]=item end
 return item
end
local workspace=node('Workspace','Workspace')
local world=node('MergeABrainrotGenerated','Model',workspace)
local own=node('Plot2','Model',world)
local other=node('Plot3','Model',world)
local keys={Buy1='Buy1',Buy5='Buy5',Buy10='Buy10',Buy100='Buy100',Deposit='DepositPad',Claim='CoinPad',Upgrade='UpgradePad',AutoMerge='MergePad'}
for _,name in keys do node(name,'Part',own);node(name,'Part',other) end
local Instance={new=function(kind) created+=1;return node('',kind) end}
local Color3={new=function(r,g,b) return {R=r,G=g,B=b} end}
local Enum={HighlightDepthMode={Occluded='Occluded'}}
'@
$source=[System.IO.File]::ReadAllText((Join-Path $repo 'src/client/Controllers/PadFeedback.luau'))
$test=@'
local feedback=Feedback.new()
assert(created==1 and not feedback.highlight.Enabled,'Create exactly one hidden Highlight before input')
assert(not feedback:trigger(2,'Buy1',0),'Unbound controllers cannot target a plot')
feedback:setPlot(2)
for key,name in keys do
 assert(feedback:trigger(2,key,1))
 assert(feedback.highlight.Enabled and feedback.highlight.Adornee==own.children[name],'The trigger call itself must show the exact own-plot pad')
 assert(feedback.highlight.FillTransparency<.6 and feedback.highlight.OutlineTransparency<.4)
 feedback:update(1.09)
 assert(feedback.highlight.Enabled and feedback.highlight.FillTransparency>.6,'Pulse fades between frames')
 feedback:update(1.181)
 assert(not feedback.highlight.Enabled and feedback.highlight.Adornee==nil,'Expired pulse clears its pad reference')
end
assert(not feedback:trigger(3,'Buy1',2),'Do not highlight another plot')
assert(not feedback:trigger(2,'OpenLucky',2),'Unknown actions cannot target arbitrary descendants')
local missing=own.children.Buy1;own.children.Buy1=nil
assert(not feedback:trigger(2,'Buy1',2),'Streaming/missing pads fail without waiting')
own.children.Buy1=missing
feedback:trigger(2,'Buy1',3);feedback:trigger(2,'Buy5',3.1);feedback:update(3.2)
assert(feedback.highlight.Enabled and feedback.highlight.Adornee==own.children.Buy5,'Rapid reentry restarts the single pulse on the new pad')
feedback:setPlot(3)
assert(not feedback.highlight.Enabled and not feedback:trigger(2,'Buy1',4),'Ownership changes clear old feedback')
feedback:setPlot(2);feedback:trigger(2,'Buy1',5);missing.Parent=nil;feedback:update(5.01)
assert(not feedback.highlight.Enabled,'Removed pads must not retain a visible pulse')
missing.Parent=own
local before=created
local start=os.clock()
for index=1,30000 do assert(feedback:trigger(2,'Buy1',index));feedback:update(index+.09) end
local micros=(os.clock()-start)*1e6/30000
assert(created==before,'No instance allocations per trigger/update')
assert(micros<1000,'Average CPU processing must remain under 1ms (not an engine frame-latency guarantee)')
feedback:destroy();feedback:destroy()
assert(feedback.highlight.destroyed and not feedback:trigger(2,'Buy1',40000),'Cleanup is idempotent and prevents reactivation')
feedback:update(40000)
print(string.format('PASS actual PadFeedback: immediate visibility, own-plot scope, all 8 pads, fade/reentry/removal, one allocation, cleanup; %.2f microseconds per trigger+update (CLI)',micros))
'@
$target=Join-Path $repo '.tools/pad-feedback-cli.luau'
[System.IO.File]::WriteAllText($target,$runtime+"`nlocal Feedback=(function()`n"+$source+"`nend)()`n"+$test)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
