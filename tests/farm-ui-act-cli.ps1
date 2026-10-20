$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
# Run the actual dispatch method without Roblox UI or remotes. This preserves
# the clickable-context contract while strict narrowing removes dead branches.
$source = [System.IO.File]::ReadAllText((Join-Path $repo 'src/client/Controllers/FarmUI.luau'))
$method = [regex]::Match($source, '(?s)(function UI\.act\(self: any\).*?\r?\nend)\r?\nfunction UI\.setContext')
if (-not $method.Success) { throw 'Expected the actual FarmUI.act method' }
$checks = @'
local cases={
    {label='nil'}, {label='Buy',context='Buy'}, {label='Deposit',context='Deposit'},
    {label='Claim',context='Claim'}, {label='Upgrade',context='Upgrade'},
    {label='Merge',context='Merge'}, {label='Pass',context='Pass',expected='pass:cash4'},
    {label='Lucky',context='Lucky',expected='open:Lucky'},
    {label='FinishNow',context='FinishNow',expected='notice:Finish now is coming soon.'},
    {label='Unknown',context='Unknown'},
}
local count=0
for _,case in cases do
    for _,pending in {false,true} do for _,modal in {false,true} do
        local trace={}
        local function record(value) table.insert(trace,value) end
        local receiver={
            context=case.context,quantity='cash4',pending=pending,
            isOpen=function() return modal end,
            onPass=function(key) record('pass:'..key) end,
            open=function(_,mode) record('open:'..mode) end,
            notice=function(_,message) record('notice:'..message) end,
        }
        for _,name in {'onBuy','onDeposit','onClaim','onUpgrade','toggleMerge'} do
            receiver[name]=function() error('Walk-pad context dispatched '..name) end
        end
        UI.act(receiver)
        local expected=if pending or modal then '' else case.expected or ''
        assert(table.concat(trace,'|')==expected,
            case.label..' dispatch changed: pending='..tostring(pending)..', modal='..tostring(modal))
        count+=1
    end end
end
print('PASS actual FarmUI.act: '..count..' contexts/guards; exact one allowed action, pass key forwarding, no walk-pad dispatch')
'@
$scriptText = "local UI={}`n" + $method.Groups[1].Value + "`n" + $checks
$target = Join-Path $repo '.tools/farm-ui-act-cli.luau'
[System.IO.File]::WriteAllText($target, $scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
