$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
# Execute the actual FarmUI update/resize/open/close code with numeric GUI
# properties. Native font bounds and input delivery remain Studio checks.
$runtime = @'
local modules={
    Config=require('../src/shared/Config'),
    Economy=require('../src/shared/Economy'),
    Tutorial=require('../src/shared/Tutorial'),
    FarmCapacity=require('../src/shared/FarmCapacity'),
    PassConfig=require('../src/shared/PassConfig'),
    CreatureCatalog={tier_01={tier=1}},
    TextStyle={},LuckyPanel={Height=__LUCKY_HEIGHT__},SettingsPanel={Height=__SETTINGS_HEIGHT__},
}
local function require(name) return modules[name] or {} end
local enumMT={__index=function(self,key) local value=setmetatable({},getmetatable(self));rawset(self,key,value);return value end}
local Enum=setmetatable({},enumMT)
local Color3={fromRGB=function(...) return {...} end,new=function(...) return {...} end}
local Vector2={new=function(x,y) return {X=x,Y=y} end}
local udimMT={}
local UDim2={}
function UDim2.new(xs,xo,ys,yo) return setmetatable({X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}},udimMT) end
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
udimMT.__add=function(a,b) return UDim2.new(a.X.Scale+b.X.Scale,a.X.Offset+b.X.Offset,a.Y.Scale+b.Y.Scale,a.Y.Offset+b.Y.Offset) end
local shared={WaitForChild=function(_,name) return name end}
local script={Parent=shared}
local game={GetService=function(_,name)
    if name=='ReplicatedStorage' then return {WaitForChild=function() return shared end} end
    if name=='TextService' then return {GetTextSize=function(_,value,size) return {X=#value*size*.5} end} end
    return {}
end}
local function object(parent)
    return {Parent=parent,Visible=true,Active=true,Text='',Font=Enum.Font.FredokaOne,
        Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(0,0),AnchorPoint=Vector2.new(0,0),
        FindFirstChildOfClass=function() return {} end}
end
local Instance={new=function() return object() end}
'@
foreach ($panel in @(@('LuckyPanel','__LUCKY_HEIGHT__'),@('SettingsPanel','__SETTINGS_HEIGHT__'))) {
    $panelSource = [System.IO.File]::ReadAllText((Join-Path $repo ("src/client/Controllers/" + $panel[0] + ".luau")))
    $height = [regex]::Match($panelSource, 'local Panel=\{[^}]*?\bHeight=(\d+)').Groups[1].Value
    if (-not $height) { throw "Could not read real panel height: $($panel[0])" }
    $runtime = $runtime.Replace($panel[1], $height)
}
$source = [System.IO.File]::ReadAllText((Join-Path $repo 'src/client/Controllers/FarmUI.luau'))
$scriptText = $runtime + "`nlocal UI=(function()`n" + $source + "`nend)()`n" + @'
local ui=setmetatable({mode='Merge',selected={},shopInfo={},quantity='1'},UI)
ui.root=object()
for _,key in {'hud','cashBar','stats','cashPlus','multiplier','cashFog','rebirthCount','bag','total','title','objective','hint',
    'actions','mergeButton','indexButton','rebirthButton','settingsButton','boostButton','permanent','boostPrice','autoButton',
    'homeButton','contextPanel','contextButton','toast','toastText','panel','closeButton','preview','list','layout','detail','bagText',
    'bagValue','rebirthBadge','contextText','overlay'} do ui[key]=object(ui.root) end
ui.cashBar.Parent=ui.hud;ui.cashPlus.Parent=ui.cashBar
ui.overlay.Visible=false
for _,key in {'mergeButton','indexButton','rebirthButton','settingsButton'} do ui[key].Parent=ui.actions end
ui.contextPanel.AnchorPoint=Vector2.new(.5,1)
ui.indexView={resize=function() end};ui.luckyView={resize=function() end};ui.settingsView={resize=function() end}
ui.drawMerge=function() end
local function rect(item)
    if item==ui.root then return {x=0,y=0,w=item.AbsoluteSize.X,h=item.AbsoluteSize.Y} end
    local p=rect(item.Parent)
    local w=p.w*item.Size.X.Scale+item.Size.X.Offset
    local h=p.h*item.Size.Y.Scale+item.Size.Y.Offset
    return {x=p.x+p.w*item.Position.X.Scale+item.Position.X.Offset-w*item.AnchorPoint.X,
        y=p.y+p.h*item.Position.Y.Scale+item.Position.Y.Offset-h*item.AnchorPoint.Y,w=w,h=h}
end
local function separate(a,b)
    a=rect(a);b=rect(b)
    return a.x+a.w<=b.x or b.x+b.w<=a.x or a.y+a.h<=b.y or b.y+b.h<=a.y
end
local function inside(item)
    local r=rect(item);local size=ui.root.AbsoluteSize
    assert(r.w>0 and r.h>0 and r.x>=0 and r.y>=0 and r.x+r.w<=size.X and r.y+r.h<=size.Y,'Control leaves safe area')
end
local state={status='Ready',coinUnits=20,rebirths=0,purchased=0,bag={},tokens={},saleQueue={},soldUnits=0,
    processorLevel=0,starterClaimed=false,cashMultiplier=1,miniMultiplier=1,autoCollect=false,autoSell=false,
    discoveries={},serverNow=0,tutorialStep=1,eventHundredths=100,producers={}}
for _,size in {{320,480},{390,440},{360,568},{390,844},{600,280},{640,280},{640,450},{640,500},{700,500},{780,500},{900,600},{1440,900}} do
    ui.root.AbsoluteSize=Vector2.new(size[1],size[2]);ui.state=nil;ui:resize()
    assert(not ui.homeButton.Visible,'Home must wait for a Ready state')
    for _,step in {1,2,4,6,7} do
        state.tutorialStep=step;ui:update(state);ui:setContext('Buy','1')
        assert(ui.homeButton.Visible,'A Ready farm must have Home before finishing the tutorial')
        inside(ui.homeButton);inside(ui.cashPlus)
        assert(ui.cashPlus.Visible and ui.cashPlus.Active,'Compact onboarding must retain the Shop entry')
        local goal=modules.Tutorial.goal(state)
        assert(ui.objective.Text==goal.title and ui.hint.Text==goal.detail,'Home must not replace onboarding guidance')
        if step<7 then
            assert(ui.objective.Visible and ui.hint.Visible,'Onboarding goal and detail remain visible')
            for _,key in {'objective','hint','actions','contextPanel'} do
                assert(separate(ui.homeButton,ui[key]),'Home overlaps '..key)
            end
            assert(separate(ui.objective,ui.hint),'Onboarding text overlaps')
            for _,key in {'objective','hint'} do
                inside(ui[key])
                assert(separate(ui[key],ui.actions),'Onboarding text overlaps action controls')
                assert(separate(ui[key],ui.contextPanel),'Onboarding text overlaps pad context')
            end
            if size[1]<600 and size[2]<500 then
                assert(not ui.boostButton.Visible and not ui.boostPrice.Visible and not ui.autoButton.Visible,
                    'Short phone onboarding must reserve its header and action row')
                for _,key in {'mergeButton','indexButton','rebirthButton','settingsButton'} do inside(ui[key]) end
            end
        else
            assert(ui.homeButton.Position.X.Scale==.5 and ui.homeButton.Position.Y.Offset==6,'Mature Home layout changed')
            assert(ui.boostButton.Visible and ui.boostPrice.Visible and ui.autoButton.Visible,'Promos must return after onboarding')
        end
        ui:open('Shop');assert(ui.mode=='Shop' and ui:isOpen(),'The retained Shop route must still open');ui:close()
    end
    state.tutorialStep=1;ui:update(state)
    for _,mode in {'Lucky','Settings'} do
        ui:open(mode)
        assert(ui.homeButton.Visible and ui.homeButton.Position.X.Scale==.5,'Side panels retain centered Home')
        for _,key in {'homeButton','bag','contextPanel'} do
            assert(separate(ui.panel,ui[key]),mode..' overlaps '..key..' at '..size[1]..'x'..size[2])
        end
        inside(ui.panel)
        assert(not ui.objective.Visible and not ui.hint.Visible,'Side panels keep their existing guidance suppression')
        assert(ui.boostButton.Visible and ui.autoButton.Visible,'Side-panel promotional layout must be restored')
        ui:close()
    end
    ui:unavailable('Waiting for a plot.')
    assert(not ui.homeButton.Visible,'Unavailable farms must hide Home again')
end
print('PASS actual FarmUI: early Home, guidance, twelve viewport bounds/separation, short-phone Shop access, mature/side-panel restoration and unavailable state')
'@
$target = Join-Path $repo '.tools/home-layout-cli.luau'
[System.IO.File]::WriteAllText($target, $scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
