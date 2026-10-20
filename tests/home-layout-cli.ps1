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
    MultiplierCuePresentation=require('../src/shared/MultiplierCuePresentation'),
    MiniEvent=require('../src/shared/MiniEvent'),
    CreatureCatalog={tier_01={tier=1}},
    TextStyle={apply=function(label) label.TextOutline={Thickness=3} end},
    LuckyPanel={Height=__LUCKY_HEIGHT__},SettingsPanel={Height=__SETTINGS_HEIGHT__},
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
local input={TouchEnabled=false}
local workspace={CurrentCamera=nil}
local game={GetService=function(_,name)
    if name=='UserInputService' then return input end
    if name=='ReplicatedStorage' then return {WaitForChild=function() return shared end} end
    if name=='TextService' then return {GetTextSize=function(_,value,size) return {X=#value*size*.5} end} end
    return {}
end}
local signal={Connect=function() return {Disconnect=function() end} end}
local function object(parent)
    return {Parent=parent,Visible=true,Active=true,Text='',Font=Enum.Font.FredokaOne,
        Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(0,0),AnchorPoint=Vector2.new(0,0),
        FindFirstChildOfClass=function() return {} end,FindFirstChild=function() return nil end,
        GetPropertyChangedSignal=function() return signal end,GetChildren=function() return {} end,
        GetAttributeChangedSignal=function() return signal end,
        GetAttribute=function(self,key) return rawget(self,'attribute_'..key) end,
        SetAttribute=function(self,key,value) rawset(self,'attribute_'..key,value) end,
        Destroying=signal,AncestryChanged=signal,ChildAdded=signal,
        Destroy=function(self) self.Parent=nil end}
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
$cueSource = [System.IO.File]::ReadAllText((Join-Path $repo 'src/client/Controllers/MultiplierCue.luau'))
$sprintSource = [System.IO.File]::ReadAllText((Join-Path $repo 'src/client/Controllers/Sprint.luau'))
$sprintLayout = [regex]::Match($sprintSource, '(?s)local function resize\(\)(.*?)\r?\n    end\r?\n    safe:GetPropertyChangedSignal').Groups[1].Value
if (-not $sprintLayout) { throw 'Could not read actual Sprint resize body' }
$scriptText = $runtime + "`nlocal UI=(function()`n" + $source + "`nend)()`nlocal Cue=(function()`n" + $cueSource + "`nend)()`n" + @'
local ui=setmetatable({mode='Merge',selected={},shopInfo={},quantity='1'},UI)
ui.gui=object();ui.root=object(ui.gui)
for _,key in {'hud','cashBar','stats','cashPlus','multiplier','cashFog','rebirthCount','bag','total','title','objective','hint',
    'actions','mergeButton','indexButton','rebirthButton','settingsButton','boostButton','permanent','boostPrice','autoButton',
    'homeButton','contextPanel','contextButton','toast','toastText','panel','closeButton','preview','list','layout','detail','bagText',
    'bagValue','rebirthBadge','contextText','overlay'} do ui[key]=object(ui.root) end
ui.cashBar.Parent=ui.hud;ui.cashPlus.Parent=ui.cashBar
ui.overlay.Visible=false
for _,key in {'mergeButton','indexButton','rebirthButton','settingsButton'} do ui[key].Parent=ui.actions end
ui.settingsButton.Icon=object(ui.settingsButton)
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
local function visible(item)
    while item do
        if item.Visible==false then return false end
        item=item.Parent
    end
    return true
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
-- A held Lucky must not force a drop just to reach the audio controls. This
-- checks the actual button's ancestry/geometry, not only UI.open('Settings').
state.tutorialStep=7
state.lucky={id='held-settings',held=true,baseTier=2}
local drops=0
ui.onDropLucky=function() drops+=1 end
for _,size in {{320,480},{320,568},{390,440},{360,568},{390,844},{600,280},{640,280},{640,450},{640,500},{700,500},{780,500},{800,500},{800,573},{900,600},{1440,900}} do
    ui.root.AbsoluteSize=Vector2.new(size[1],size[2]);ui:update(state);ui:open('Lucky')
    assert(visible(ui.settingsButton) and ui.settingsButton.Active,
        'Held Lucky hides the Settings entry at '..size[1]..'x'..size[2])
    inside(ui.settingsButton)
    local r=rect(ui.settingsButton)
    assert(r.w>=40 and r.h>=40,'Held Settings needs a usable touch target')
    local home=rect(ui.homeButton)
    assert(r.x>=home.x+home.w+12,'Held Settings must stay right of Home, away from the open chat pane')
    if size[1]==800 then
        assert(ui.panel.Size.Y.Offset==math.min(modules.LuckyPanel.Height,size[2]-120),
            'A gear-only crossing must retain the full Lucky card height when it fits')
    end
    for _,key in {'homeButton','panel','bag','contextPanel','boostButton','boostPrice','autoButton','cashPlus'} do
        assert(separate(ui.settingsButton,ui[key]),'Held Settings overlaps '..key..' at '..size[1]..'x'..size[2])
    end
    ui:open('Settings')
    assert(ui:isSettingsOpen() and not ui:isOpen() and not ui.overlay.Active)
    ui:close()
    assert(ui:isLuckyOpen() and state.lucky.held and drops==0,'Settings close must retain and restore the held card')
    assert(visible(ui.settingsButton),'Returning to Lucky must restore Settings access')
    state.lucky=nil;ui:close()
    assert(ui.settingsButton.Parent==ui.actions and visible(ui.settingsButton)
        and ui.settingsButton.Text=='Settings','Normal Settings rail placement/caption must return')
    assert(ui.settingsButton.Icon.Position.Y.Scale==.01 and ui.settingsButton.Icon.Size.Y.Scale==.73,
        'Normal Settings icon geometry must return')
    state.lucky={id='held-settings',held=true,baseTier=2}
end
local swept=0
for width=320,1600,20 do
    for height=if width<600 then 440 else 280,960,20 do
        ui.root.AbsoluteSize=Vector2.new(width,height);ui:update(state);ui:open('Lucky');ui:setContext('Buy','1')
        for _,key in {'settingsButton','homeButton','panel'} do
            assert(visible(ui[key]),key..' is hidden at '..width..'x'..height)
            inside(ui[key])
        end
        for _,pair in {{'settingsButton','homeButton'},{'settingsButton','panel'},
            {'panel','homeButton'},{'panel','bag'},{'panel','contextPanel'}} do
            assert(separate(ui[pair[1]],ui[pair[2]]),pair[1]..' overlaps '..pair[2]..' at '..width..'x'..height)
        end
        swept+=1
    end
end
ui:open('Lucky');ui:open('Shop')
assert(ui.settingsButton.Parent==ui.actions,'Changing to another mode must restore the rail')
ui:close();assert(ui:isLuckyOpen() and visible(ui.settingsButton))
ui:unavailable('Waiting for a plot.')
assert(ui.settingsButton.Parent==ui.actions and ui.settingsButton.Text=='Settings',
    'Unavailable must not leave a loose Settings entry')
-- Use the actual Cue constructor's watched obstacles with the actual layout
-- helper. A short landscape event cue previously covered the relocated gear.
local cue=Cue.new(ui)
local function region(item)
    local r=rect(item);return {x=r.x,y=r.y,width=r.w,height=r.h}
end
for _,size in {{320,480},{320,568},{390,440},{360,568},{390,844},{600,280},{640,280},{640,450},{640,500},{700,500},{780,500},{800,500},{800,573},{900,600},{1440,900}} do
    ui.root.AbsoluteSize=Vector2.new(size[1],size[2]);ui:update(state);ui:open('Lucky');ui:setContext('Buy','1')
    local obstacles={}
    for _,item in cue.obstacles do if visible(item) then table.insert(obstacles,region(item)) end end
    for _,pickups in {false,true} do
        local layout=modules.MultiplierCuePresentation.layout(size[1],size[2],region(ui.bag),obstacles,pickups)
        if layout then
            local gear=region(ui.settingsButton)
            assert(layout.x+layout.width<=gear.x or gear.x+gear.width<=layout.x
                or layout.y+layout.height<=gear.y or gear.y+gear.height<=layout.y,
                'Multiplier cue covers held Settings at '..size[1]..'x'..size[2])
        end
    end
end
cue:destroy()
-- Reproduce the actual simulator control rectangles, plus short portrait and
-- the large tablet controls. These are safe-area coordinates, not viewport
-- coordinates: Roblox's touch controls and our HUD share the same origin.
input.TouchEnabled=true
local placeSprint=function(safe,button)
__SPRINT_LAYOUT__
end
local nativeJumpSide=70
ui.gui.Parent={FindFirstChild=function(_,name)
    if name=='TouchGui' then return {FindFirstChild=function()
        return {IsA=function(_,class) return class=='GuiObject' end,AbsoluteSize=Vector2.new(nativeJumpSide,nativeJumpSide)}
    end} end
    return nil
end}
local touchCases={
    {750,323,655,233,70,29,230,74},
    {705,280,610,190,70,29,187,74},
    {401,720,306,630,70,29,627,74},
    {1375,974,1205,764,120,58,788,148},
    {320,440,225,350,70,29,347,74},
    {360,568,265,478,70,29,475,74},
    {600,280,505,190,70,29,187,74},
    {580,760,410,550,120,58,574,148},
    {600,558,430,348,120,58,372,148},
    {600,500,430,290,120,58,314,148},
    {579,759,409,549,120,58,573,148},
    {568,500,398,290,120,58,314,148},
}
local function control(x,y,side)
    local value=object(ui.root);value.Position=UDim2.fromOffset(x,y);value.Size=UDim2.fromOffset(side,side)
    return value
end
for _,size in touchCases do
    ui.root.AbsoluteSize=Vector2.new(size[1],size[2])
    nativeJumpSide=size[5]
    local jump=control(size[3],size[4],size[5])
    local thumb=control(size[6],size[7],size[8])
    local sprint=control(0,0,44);sprint.Size=UDim2.fromOffset(82,44)
    for _,step in {1,7} do
        state.tutorialStep=step;state.lucky=nil;ui:close();ui:update(state);ui:setContext('Buy','1')
        for _,mode in {'Normal','Lucky','Settings'} do
            if mode~='Normal' then
                state.lucky={id='touch-held',held=true,baseTier=2};ui:update(state);ui:open(mode)
            end
            placeSprint(ui.root,sprint);inside(sprint)
            assert(separate(sprint,jump) and separate(sprint,thumb),'Sprint covers native touch controls')
            for _,key in {'hud','bag','total','homeButton','actions','contextPanel','cashPlus','settingsButton','boostButton','autoButton','panel'} do
                local item=ui[key]
                if visible(item) and (key~='panel' or mode~='Normal') then
                    inside(item)
                    for _,touch in {jump,thumb} do
                        assert(separate(item,touch),key..' covers touch movement at '..size[1]..'x'..size[2]..' '..mode)
                    end
                    assert(separate(item,sprint),key..' covers Sprint at '..size[1]..'x'..size[2]..' '..mode)
                end
            end
            assert(visible(ui.total) and visible(ui.bag) and visible(ui.hud),'Touch must retain all farm counts')
            assert(rect(ui.cashPlus).w>=40 and rect(ui.cashPlus).h>=40,'Touch Shop entry is too small')
            assert(separate(ui.hud,ui.bag) and separate(ui.total,ui.bag),'Touch farm counts overlap')
            if mode~='Normal' then
                for _,key in {'homeButton','settingsButton','bag','hud','total','contextPanel'} do
                    if key~='settingsButton' or mode=='Lucky' then
                        assert(separate(ui.panel,ui[key]),'Touch '..mode..' covers '..key..' at '..size[1]..'x'..size[2])
                    end
                end
                assert(ui.panel.Size.Y.Offset>=106,'Touch side panel must retain a usable scroll viewport')
            end
        end
    end
end
input.TouchEnabled=false
print('PASS actual FarmUI/Cue/Sprint: early Home/guidance, held Settings/card restoration, '..swept..' desktop layouts and '..#touchCases..' touch layouts × onboarding/mature × normal/Lucky/Settings with native control separation')
'@
$scriptText=$scriptText.Replace('__SPRINT_LAYOUT__',$sprintLayout)
$target = Join-Path $repo '.tools/home-layout-cli.luau'
[System.IO.File]::WriteAllText($target, $scriptText)
& (Join-Path $repo '.tools/luau/luau.exe') $target
exit $LASTEXITCODE
