$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$runtime=@'
local function node(name,class,parent)
 local item={Name=name,ClassName=class,Parent=parent,children={}}
 function item:FindFirstChild(key) return self.children[key] end
 function item:IsA(key) return key==self.ClassName end
 if parent then parent.children[name]=item end
 return item
end
local workspace=node('Workspace','Workspace')
local world=node('MergeABrainrotGenerated','Model',workspace)
local plot=node('Plot2','Model',world)
local pad=node('CoinPad','Part',plot)
local gui=node('Label','BillboardGui',pad)
local price=node('Price','TextLabel',gui);price.Text='$700000'
local other=node('Plot3','Model',world)
local otherPad=node('CoinPad','Part',other);local otherGui=node('Label','BillboardGui',otherPad)
local otherPrice=node('Price','TextLabel',otherGui);otherPrice.Text='$12'
'@
$source=[System.IO.File]::ReadAllText((Join-Path $repo 'src/client/Controllers/CashPadCounter.luau'))
$test=@'
local counter=Counter.new()
counter:setState({plotId=2,soldUnits=2800000,revision=4})
assert(price.Text=='$700000','A snapshot alone never starts an optimistic claim animation')
assert(not counter:claim(3,48,0,0,5) and otherPrice.Text=='$12','Never animate a foreign plot')
assert(counter:claim(2,2800000,0,10,5) and price.Text=='$700,000','Server-confirmed claim must start visibly on this call')
counter:update(10.375);assert(price.Text=='$590,625','Gentle ease-in keeps the initial amount readable')
counter:update(10.75);assert(price.Text=='$350,000')
-- A pre-claim snapshot must not reintroduce already claimed cash.
counter:setState({plotId=2,soldUnits=2800000,revision=4});counter:update(10.75)
assert(price.Text=='$350,000')
counter:setState({plotId=2,soldUnits=40,revision=6})
price.Text='$10' -- Simulate a replicated WorldBuilder label write between frames.
counter:update(10.75);assert(price.Text=='$350,010','New processor cash adds to the remaining balance without restarting the deadline')
assert(not counter:claim(2,2800000,0,10.8,5),'A replayed confirmed revision cannot restart the countdown or erase new earnings')
counter:update(11.125);assert(price.Text=='$109,385','Ease-out slows the final portion')
counter:update(11.49);assert(counter.active,'Keep the countdown visible for approximately 1.5 seconds')
counter:update(11.501);assert(price.Text=='$10' and not counter.active,'Finish at 1.5 seconds without zeroing new cash')
price.Text='$999';counter:update(11.6)
assert(price.Text=='$999','After completion server owns the label again')
counter:setState({plotId=2,soldUnits=100,revision=7})
counter:claim(2,100,0,12,8);counter:update(12.75)
assert(price.Text=='$12','Display whole dollars while preserving exact internal quarter-dollar accounting')
counter:setState({plotId=2,soldUnits=16,revision=9})
counter:claim(2,16,0,12.75,10)
assert(price.Text=='$16','A second confirmed claim retains the eased unfinished amount')
counter:setState({plotId=2,soldUnits=8,revision=11});counter:update(14.251)
assert(price.Text=='$2' and not counter.active)
counter:claim(2,8,0,15,12);counter:setState({plotId=3,soldUnits=48,revision=1})
assert(not counter.active and price.Text=='$0' and otherPrice.Text=='$12','Changing plot restores old label without touching new plot')
counter:setState({plotId=2,soldUnits=0,revision=13})
gui.children.Price=nil
assert(not counter:claim(2,400,0,16,14),'Missing/streamed labels return without waiting or errors')
gui.children.Price=price;counter:update(16.75);assert(price.Text=='$50')
counter:setState({plotId=2,soldUnits=23,revision=15});counter:destroy();counter:destroy()
assert(price.Text=='$5' and counter.actual==23 and not counter:claim(2,400,0,17),'Restoration hides cents without dropping fractional authoritative earnings')
local fractional=Counter.new();fractional:setState({plotId=2,soldUnits=3,revision=1})
fractional:claim(2,13,3,0,2);assert(price.Text=='$4')
for step=1,90 do fractional:update(step/60);assert(not price.Text:find('%.'),'Never show cents during animation or restoration') end
assert(price.Text=='$0' and fractional.actual==3 and not fractional.active)
local bench=Counter.new();bench:setState({plotId=2,soldUnits=0,revision=1})
local started=os.clock()
for index=1,30000 do bench:claim(2,2800000,0,index*2);bench:update(index*2+.75);bench:update(index*2+1.51) end
local micros=(os.clock()-started)*1e6/30000
assert(micros<1000)
print(string.format('PASS actual CashPadCounter: eased 1.5s whole-dollar countdown, exact fractional earnings, stale/replay rejection, retargeting, own plot, streaming, cleanup; %.2fus mean claim+2updates CPU',micros))
'@
$target=Join-Path $repo '.tools/cash-pad-counter-cli.luau'
[System.IO.File]::WriteAllText($target,$runtime+"`nlocal Counter=(function()`n"+$source+"`nend)()`n"+$test)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
